import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/utils/log.dart';

int _defaultNowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Thrown inside a download whose deck is being removed.
class _DownloadHalted implements Exception {}

/// Thrown when a download stopped because the app left the foreground.
class _DownloadInterrupted implements Exception {
  const _DownloadInterrupted();
}

/// The deck and the fact pages a download fetched so far. Saved in the store
/// after each page, so a run resumed after a pause or an app restart
/// continues from there.
class _Checkpoint {
  _Checkpoint(this.remote, this.before, this.fetchedAt);

  final Deck remote;
  final OfflineDeck? before;
  final int fetchedAt;
  final List<OfflineFact> facts = [];
  final Map<String, Tag> tags = {};

  /// Fact count the pages were fetched against; null when unknown.
  int? factTotal;
  bool factsDone = false;

  /// The facts themselves are in the store; only their ids are saved here.
  Map<String, dynamic> toJson() => {
    'sourceVersion': remote.sourceVersion,
    'factTotal': factTotal,
    'factIds': [for (final f in facts) f.id],
    'tags': [for (final t in tags.values) t.toJson()],
    'factsDone': factsDone,
  };
}

/// Assembles a deck's offline study package (deck, facts, cards, media) into
/// [OfflineLearningStore]. Server card schedules replace local ones unless the
/// card has unsynced local changes.
class OfflinePackageDownloader {
  OfflinePackageDownloader({
    required OfflineLearningStore store,
    required String mediaRootDir,
    FetchDeckFn? fetchDeck,
    FetchFactsPageFn? fetchFactsPage,
    FetchFactIdsFn? fetchFactIds,
    FetchCardsFn? fetchCards,
    DownloadMediaFn? downloadMedia,
    FetchMediaVersionsFn? fetchMediaVersions,
    int Function()? nowSec,
    Future<bool> Function()? isOnline,
    ValueListenable<bool>? foreground,
    Stream<void> Function()? connectivityChanged,
  }) : _store = store,
       _mediaRootDir = mediaRootDir,
       _fetchDeck = fetchDeck ?? DeckService.of.getDeckDetail,
       _fetchFactsPage = fetchFactsPage ?? fetchOfflineFactsPage,
       _fetchFactIds = fetchFactIds ?? fetchOfflineFactIds,
       _fetchCards = fetchCards ?? fetchOfflineCards,
       _downloadMedia = downloadMedia ?? ApiService.downloadFile,
       _fetchMediaVersions = fetchMediaVersions ?? fetchOfflineMediaVersions,
       _nowSec = nowSec ?? _defaultNowSec,
       _isOnline = isOnline ?? hasNetworkConnection,
       _foreground = foreground,
       _connectivityChanged = connectivityChanged {
    _foreground?.addListener(_onForeground);
  }

  static const int factsPageSize = 200;
  static const int versionLookupConcurrency = 4;
  static const int mediaDownloadConcurrency = 64;
  static const int refreshIntervalSec = 3600;
  static const int resumeConcurrency = 2;

  // Share of the progress each stage fills; media takes the rest.
  static const double _deckShare = 0.05;
  static const double _factsShare = 0.30;
  static const double _cardsShare = 0.05;

  final OfflineLearningStore _store;
  final String _mediaRootDir;
  final FetchDeckFn _fetchDeck;
  final FetchFactsPageFn _fetchFactsPage;
  final FetchFactIdsFn _fetchFactIds;
  final FetchCardsFn _fetchCards;
  final DownloadMediaFn _downloadMedia;
  final FetchMediaVersionsFn _fetchMediaVersions;
  final int Function() _nowSec;
  final Future<bool> Function() _isOnline;
  final ValueListenable<bool>? _foreground;
  final Stream<void> Function()? _connectivityChanged;
  StreamSubscription<void>? _offlineWait;
  var _disposed = false;
  final Map<String, Future<bool>> _inFlight = {};
  final Map<String, int> _halts = {};
  final Map<String, ValueNotifier<double?>> _progress = {};
  final Map<String, ValueNotifier<bool>> _failed = {};
  final Set<String> _resumed = {};
  final Set<String> _leftForeground = {};
  final Set<String> _resumeWhenForeground = {};
  var _haltsAll = 0;

  /// Stops listening to the app and the network. Used once the account logs
  /// out; the downloader is not used afterwards. The foreground listenable is
  /// not disposed here: OfflineLearningSession owns and disposes it.
  void dispose() {
    _disposed = true;
    _foreground?.removeListener(_onForeground);
    unawaited(_offlineWait?.cancel());
    _offlineWait = null;
  }

  /// Download progress of [deckId] from 0 to 1, or null when none is running.
  /// Never decreases during a run; concurrent callers share one run.
  ValueListenable<double?> progressOf(String deckId) => _notifier(deckId);

  ValueNotifier<double?> _notifier(String deckId) =>
      _progress[deckId] ??= ValueNotifier(null);

  /// True once the last download of [deckId] failed (not when it was stopped
  /// for removal); reset when the next one starts.
  ValueListenable<bool> failedOf(String deckId) => _failedNotifier(deckId);

  ValueNotifier<bool> _failedNotifier(String deckId) =>
      _failed[deckId] ??= ValueNotifier(false);

  void _report(String deckId, double fraction) {
    final progress = _notifier(deckId);
    if (fraction > (progress.value ?? 0)) progress.value = fraction.clamp(0, 1);
  }

  bool _isHalted(String deckId) => _haltsAll > 0 || _halts.containsKey(deckId);

  void _checkHalted(String deckId) {
    if (_isHalted(deckId)) throw _DownloadHalted();
  }

  /// Stops the download of [deckId] (every deck when null) at its next step,
  /// waits for it, then runs [action] before any new download can start.
  /// Used before deleting offline data, which a running download would
  /// otherwise write back.
  Future<T> whileHalted<T>(String? deckId, Future<T> Function() action) async {
    if (deckId == null) {
      _haltsAll++;
    } else {
      _halts.update(deckId, (n) => n + 1, ifAbsent: () => 1);
    }
    await _dropPaused(deckId);
    try {
      while (true) {
        final running = [
          if (deckId == null) ..._inFlight.values,
          if (deckId != null) ?_inFlight[deckId],
        ];
        if (running.isEmpty) break;
        await Future.wait(running);
      }
      return await action();
    } finally {
      if (deckId == null) {
        _haltsAll--;
      } else if (_halts.update(deckId, (n) => n - 1) == 0) {
        _halts.remove(deckId);
      }
    }
  }

  /// Study-page refresh: downloads only when online, and a study-ready deck
  /// at most once per [refreshIntervalSec].
  Future<void> refreshIfStale(String deckId) async {
    if (!await _isOnline()) return;
    final deck = await _store.getDeck(deckId);
    if (deck != null &&
        deck.isReady &&
        _nowSec() - deck.refreshedAt < refreshIntervalSec) {
      return;
    }
    await download(deckId);
  }

  /// Downloads the decks of [deckIds] that are not study-ready yet, picking up
  /// downloads cut short by closing the app, [resumeConcurrency] at a time.
  /// Only when online, and each deck at most once per app run, so a deck that
  /// keeps failing is not retried on every list refresh (its retry button
  /// still works). A deck being downloaded already is joined, not repeated.
  Future<void> resumeMissing(Iterable<String> deckIds) async {
    try {
      if (!await _isOnline()) return;
      final ready = {
        for (final d in await _store.getDecks())
          if (d.isReady) d.id,
      };
      final pending = [
        for (final id in deckIds)
          if (!ready.contains(id) && _resumed.add(id)) id,
      ];
      var next = 0;
      Future<void> worker() async {
        while (next < pending.length) {
          await download(pending[next++]);
        }
      }

      await Future.wait([for (var w = 0; w < resumeConcurrency; w++) worker()]);
    } catch (e) {
      logger.w('Offline download resume failed: $e');
    }
  }

  /// Returns true when the deck is study-ready offline. Concurrent calls for
  /// one deck share a single download (they would write the same files).
  /// [fresh] skips a download already running, which may have listed the
  /// deck before a just-made edit, and runs a new one after it.
  Future<bool> download(String deckId, {bool fresh = false}) {
    if (_disposed || _isHalted(deckId)) return Future.value(false);
    final running = _inFlight[deckId];
    if (running != null && !fresh) return running;
    final started = running == null
        ? _download(deckId, resume: !fresh)
        : running.then(
            (_) => _disposed
                ? Future.value(false)
                : _download(deckId, resume: !fresh),
          );
    return _trackInFlight(deckId, started);
  }

  /// A later [download] with `fresh: true` replaces the map entry; only that
  /// one may clear it when it finishes.
  Future<bool> _trackInFlight(String deckId, Future<bool> started) {
    late final Future<bool> tracked;
    tracked = started.whenComplete(() {
      if (identical(_inFlight[deckId], tracked)) _inFlight.remove(deckId);
      unawaited(_kickPaused());
    });
    return _inFlight[deckId] = tracked;
  }

  void _onForeground() {
    if (_foreground?.value == true) unawaited(_kickPaused());
  }

  /// A download cut off by leaving the app waits here instead of failing.
  void _pauseForForeground(String deckId) {
    if (_isHalted(deckId)) return;
    _resumeWhenForeground.add(deckId);
    unawaited(_kickPaused());
  }

  Future<void> _dropPaused(String? deckId) async {
    final ids = deckId == null ? _resumeWhenForeground.toList() : [deckId];
    for (final id in ids) {
      if (!_resumeWhenForeground.remove(id)) continue;
      _notifier(id).value = null;
      await _forgetCheckpoint(id);
    }
  }

  /// Offline, the paused downloads stay paused with their checkpoints instead
  /// of failing at once; the network coming back or the next return to the
  /// app resumes them.
  Future<void> _kickPaused() async {
    if (_foreground?.value == false || _resumeWhenForeground.isEmpty) return;
    final online = await _probeOnline();
    if (_disposed) return;
    if (!online) {
      _waitForNetwork();
      return;
    }
    if (_foreground?.value == false) return;
    for (final id in _resumeWhenForeground.toList()) {
      if (_inFlight.containsKey(id)) continue;
      _resumeWhenForeground.remove(id);
      unawaited(download(id));
    }
  }

  /// A failing connectivity check counts as offline.
  Future<bool> _probeOnline() async {
    try {
      return await _isOnline();
    } catch (e) {
      logger.w('Offline download connectivity check failed: $e');
      return false;
    }
  }

  /// Kicks the paused downloads again on the next connectivity change, which
  /// waits once more if the device is still offline.
  void _waitForNetwork() {
    _offlineWait ??= _connectivityChanged?.call().listen((_) {
      unawaited(_offlineWait?.cancel());
      _offlineWait = null;
      unawaited(_kickPaused());
    });
  }

  /// [resume]: continue from the checkpoint a paused run saved.
  Future<bool> _download(String deckId, {required bool resume}) async {
    final progress = _notifier(deckId)..value ??= 0;
    _failedNotifier(deckId).value = false;
    // This run replaces a paused one, which must not start again after it.
    _resumeWhenForeground.remove(deckId);
    void noteLeft() {
      if (_foreground?.value == false) _leftForeground.add(deckId);
    }

    noteLeft();
    _foreground?.addListener(noteLeft);
    try {
      return await _writePackage(deckId, resume: resume);
    } on _DownloadHalted {
      logger.i('Offline download of deck=$deckId stopped for removal');
      return false;
    } on _DownloadInterrupted catch (e) {
      return _pauseDownload(deckId, e);
    } catch (e, s) {
      if (_leftForeground.contains(deckId)) return _pauseDownload(deckId, e);
      logger.e('Offline download failed for deck=$deckId: $e', stackTrace: s);
      _failedNotifier(deckId).value = true;
      return false;
    } finally {
      _foreground?.removeListener(noteLeft);
      _leftForeground.remove(deckId);
      if (!_resumeWhenForeground.contains(deckId)) {
        progress.value = null;
        await _forgetCheckpoint(deckId);
      }
    }
  }

  bool _pauseDownload(String deckId, Object error) {
    logger.w('Offline download of deck=$deckId paused with the app: $error');
    _pauseForForeground(deckId);
    return false;
  }

  Future<bool> _writePackage(String deckId, {required bool resume}) async {
    _checkHalted(deckId);
    final checkpoint = await _startCheckpoint(deckId, resume: resume);
    // Facts finished before a pause are kept only while the deck lists the
    // very same facts.
    if (checkpoint.factsDone && !await _listsSameFacts(deckId, checkpoint)) {
      _restartFacts(checkpoint, null);
    }
    await _pinRestoredFacts(deckId, checkpoint);
    if (!checkpoint.factsDone) await _syncFacts(deckId, checkpoint);
    _report(deckId, _deckShare + _factsShare);
    final _Checkpoint(:remote, :before, :fetchedAt, :facts) = checkpoint;
    final tags = checkpoint.tags.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final mediaComplete = await _downloadFactMedia(deckId, facts);
    // Last, so reviews made online while the deck was downloading (the
    // study screen serves it remotely until it is ready) are not lost.
    await _seedCards(deckId);
    // Re-read: sync flushes and tag loads may have written the row meanwhile.
    final local = await _store.getDeck(deckId);
    _checkHalted(deckId);
    await _store.putDeck(
      _buildDeck(
        deckId,
        remote,
        local,
        tags,
        // A flush that refreshed the counters during the download has
        // newer ones than the deck fetched before it.
        countsAt: local?.lastSyncedAt == before?.lastSyncedAt
            ? fetchedAt
            : null,
        mediaComplete: mediaComplete,
      ),
    );
    try {
      await pruneUnusedMedia(_store);
    } catch (e) {
      logger.w('Offline media cleanup of deck=$deckId failed: $e');
    }
    _report(deckId, 1);
    return true;
  }

  /// Fetches the deck, then takes over the fact pages a paused run of the same
  /// snapshot saved. Only such a run keeps the paused bar; any other starts it
  /// over and replaces the saved checkpoint.
  Future<_Checkpoint> _startCheckpoint(
    String deckId, {
    required bool resume,
  }) async {
    final fetchedAt = _nowSec();
    final remote = await _fetchDeck(deckId);
    _checkHalted(deckId);
    final cp = _Checkpoint(remote, await _store.getDeck(deckId), fetchedAt);
    final saved = resume ? await _store.getDownloadCheckpoint(deckId) : null;
    if (saved == null || !await _restore(deckId, cp, saved)) {
      _notifier(deckId).value = 0;
      await _store.putDownloadCheckpoint(deckId, cp.toJson());
    }
    _report(deckId, _deckShare);
    return cp;
  }

  /// Fills [cp] from [saved] when it read the same snapshot and its facts are
  /// all still stored.
  Future<bool> _restore(
    String deckId,
    _Checkpoint cp,
    Map<String, dynamic> saved,
  ) async {
    if (saved case {
      'sourceVersion': final int version,
      'factTotal': final int? total,
      'factIds': final List<dynamic> ids,
      'tags': final List<dynamic> tags,
      'factsDone': final bool done,
    } when version == cp.remote.sourceVersion) {
      final stored = {for (final f in await _store.getFacts(deckId)) f.id: f};
      final facts = [for (final id in ids) stored[id]];
      if (facts.contains(null)) return false;
      cp.facts.addAll(facts.nonNulls);
      for (final t in tags) {
        final tag = Tag.fromJson(Map<String, dynamic>.from(t as Map));
        cp.tags[tag.id] = tag;
      }
      cp
        ..factTotal = total
        ..factsDone = done;
      return true;
    }
    return false;
  }

  Future<void> _forgetCheckpoint(String deckId) async {
    try {
      await _store.deleteDownloadCheckpoint(deckId);
    } catch (e) {
      logger.w('Offline download checkpoint of deck=$deckId kept: $e');
    }
  }

  /// [countsAt]: when the server review counters of [remote] were fetched, to
  /// replace the local ones; null keeps the local counters. Queued reviews
  /// are added on top of either when stats are computed.
  OfflineDeck _buildDeck(
    String deckId,
    Deck remote,
    OfflineDeck? local,
    List<Tag> tags, {
    int? countsAt,
    bool mediaComplete = true,
  }) {
    final kept = countsAt == null ? local : null;
    final ready = local != null && local.isReady ? local : null;
    return OfflineDeck(
      id: deckId,
      name: remote.name,
      fields: remote.fields,
      rate: remote.rate,
      sourceDeckId: remote.sourceDeckId,
      sourceVersion: remote.sourceVersion,
      totalReviews: kept?.totalReviews ?? remote.stats.totalReviews,
      totalReviewsToday:
          kept?.totalReviewsToday ?? remote.stats.totalReviewsToday,
      downloadedAt: ready?.downloadedAt ?? _nowSec(),
      lastSyncedAt: countsAt ?? local?.lastSyncedAt ?? 0,
      tags: tags,
      // A first download's card snapshot predates the online session it runs
      // beside, so it leaves the deck due a refresh on the next open, as does
      // a refresh that missed media.
      refreshedAt: ready == null
          ? 0
          : mediaComplete
          ? _nowSec()
          : ready.refreshedAt,
    );
  }

  /// Fetches the fact pages into [cp], continuing after the pages it already
  /// holds. Tags are later ordered by id, the order of `GET /api/tags` used by
  /// the online tag filter.
  Future<void> _syncFacts(String deckId, _Checkpoint cp) async {
    final deck = _buildDeck(deckId, cp.remote, cp.before, const []);
    final imported = deck.sourceDeckId.isNotEmpty;
    final stored = imported
        ? await _factsAtSnapshot(deck)
        : <String, OfflineFact>{};
    final total = await _factCount(deckId);
    // Facts added or deleted meanwhile shift the offsets, so start over.
    if (total == null || total != cp.factTotal) _restartFacts(cp, total);
    await _fetchFactPages(deckId, cp, stored, imported: imported);
    var ids = await _liveFactIds(deckId);
    if (ids != null && _missesAny(cp, ids)) {
      // A fact added or deleted while paging shifted the offsets past some.
      logger.w('Offline facts of deck=$deckId incomplete, fetching again');
      _restartFacts(cp, ids.length);
      await _fetchFactPages(deckId, cp, stored, imported: imported);
      // Re-read, or a fact added meanwhile would be dropped as deleted.
      ids = await _liveFactIds(deckId);
    }
    _report(deckId, _deckShare + _factsShare);
    if (ids != null) await _dropDeletedFacts(deckId, ids);
    cp.factsDone = true;
    await _store.putDownloadCheckpoint(deckId, cp.toJson());
  }

  /// Restored facts of an imported deck whose version lookup failed are looked
  /// up again, or their media would be fetched unpinned and refused.
  Future<void> _pinRestoredFacts(String deckId, _Checkpoint cp) async {
    if (cp.remote.sourceDeckId.isEmpty) return;
    final pinned = await _pinMediaVersions(deckId, cp.facts, const {});
    _checkHalted(deckId);
    final changed = [
      for (var i = 0; i < pinned.length; i++)
        if (!identical(pinned[i], cp.facts[i])) pinned[i],
    ];
    if (changed.isEmpty) return;
    await _store.putFacts(changed);
    cp.facts
      ..clear()
      ..addAll(pinned);
  }

  /// False too when the fact ids cannot be read, so the facts are fetched.
  Future<bool> _listsSameFacts(String deckId, _Checkpoint cp) async {
    final ids = await _liveFactIds(deckId);
    return ids != null && ids.length == cp.facts.length && !_missesAny(cp, ids);
  }

  void _restartFacts(_Checkpoint cp, int? total) {
    cp.facts.clear();
    cp.tags.clear();
    cp.factTotal = total;
    cp.factsDone = false;
  }

  bool _missesAny(_Checkpoint cp, List<String> ids) {
    final got = {for (final f in cp.facts) f.id};
    return ids.any((id) => !got.contains(id));
  }

  Future<void> _fetchFactPages(
    String deckId,
    _Checkpoint cp,
    Map<String, OfflineFact> stored, {
    required bool imported,
  }) async {
    final total = cp.factTotal;
    OfflineFactsPage page;
    do {
      // First the pages a restored checkpoint holds, then each page fetched.
      if (total != null && total > 0) {
        _report(deckId, _deckShare + _factsShare * cp.facts.length / total);
      }
      page = await _fetchFactsPage(deckId, factsPageSize, cp.facts.length);
      final facts = imported
          ? await _pinMediaVersions(deckId, page.facts, stored)
          : page.facts;
      _checkHalted(deckId);
      await _store.putFacts(facts);
      cp.facts.addAll(facts);
      for (final t in page.tags) {
        cp.tags[t.id] = t;
      }
      await _store.putDownloadCheckpoint(deckId, cp.toJson());
    } while (page.hasMore && page.facts.isNotEmpty);
  }

  /// Fact count for the progress only; null when it cannot be read.
  Future<int?> _factCount(String deckId) async {
    try {
      return (await _fetchFactIds(deckId))?.length;
    } catch (_) {
      return null;
    }
  }

  /// The unpaged fact ids, which prove which facts exist; null when they
  /// cannot be read.
  Future<List<String>?> _liveFactIds(String deckId) async {
    try {
      return await _fetchFactIds(deckId);
    } catch (e) {
      logger.w('Offline fact ids of deck=$deckId failed: $e');
      return null;
    }
  }

  /// Offset paging skips facts when the deck changes meanwhile, so only the
  /// unpaged id list [ids] proves a fact was deleted.
  Future<void> _dropDeletedFacts(String deckId, List<String> ids) async {
    final live = ids.toSet();
    final gone = [
      for (final f in await _store.getFacts(deckId))
        if (!live.contains(f.id)) f.id,
    ];
    _checkHalted(deckId);
    if (gone.isNotEmpty) await _store.deleteFacts(deckId, gone);
  }

  /// Stored facts, when they were resolved against the same import snapshot.
  Future<Map<String, OfflineFact>> _factsAtSnapshot(OfflineDeck deck) async {
    final local = await _store.getDeck(deck.id);
    if (local?.sourceVersion != deck.sourceVersion) return const {};
    return {for (final f in await _store.getFacts(deck.id)) f.id: f};
  }

  /// Imported decks may only fetch the author's media at a pinned version.
  /// A failed lookup leaves the fact unresolved (retried on the next sync).
  /// One failing after the app left the foreground pauses the download before
  /// the page is saved, so it runs again on resume.
  Future<List<OfflineFact>> _pinMediaVersions(
    String deckId,
    List<OfflineFact> facts,
    Map<String, OfflineFact> stored,
  ) async {
    final result = [...facts];
    final pending = <int>[];
    for (var i = 0; i < result.length; i++) {
      final ids = result[i].mediaIds;
      if (result[i].mediaVersions != null || ids.isEmpty) continue;
      final old = stored[result[i].id];
      final reusable =
          old?.mediaVersions != null &&
          old!.mediaIds.length == ids.length &&
          old.mediaIds.containsAll(ids);
      if (reusable) {
        result[i] = result[i].withMediaVersions(old.mediaVersions);
      } else {
        pending.add(i);
      }
    }
    var next = 0;
    Future<void> worker() async {
      // Leaving the app starts no new lookup; those running settle first.
      while (next < pending.length && !_leftForeground.contains(deckId)) {
        final i = pending[next++];
        final fact = result[i];
        result[i] = fact.withMediaVersions(await _lookupVersions(deckId, fact));
      }
    }

    await Future.wait([
      for (var w = 0; w < versionLookupConcurrency; w++) worker(),
    ]);
    if (next < pending.length) throw const _DownloadInterrupted();
    return result;
  }

  Future<Map<String, int>?> _lookupVersions(
    String deckId,
    OfflineFact fact,
  ) async {
    try {
      final versions = await _fetchMediaVersions(deckId, fact.id);
      // The lookup reads any failure as null, which one cut off by leaving
      // the app must not save as an unpinned fact.
      if (versions == null && _leftForeground.contains(deckId)) {
        throw const _DownloadInterrupted();
      }
      return versions;
    } catch (e, s) {
      if (_leftForeground.contains(deckId)) rethrow;
      logger.e(
        'Offline media versions of ${fact.id} failed: $e',
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> _seedCards(String deckId) async {
    String row(OfflineCard c) => jsonEncode(c.toJson());
    final before = {
      for (final c in await _store.getCards(deckId)) c.id: row(c),
    };
    final remote = await _fetchCards(deckId);
    _checkHalted(deckId);
    final local = await _store.getCards(deckId);
    // A card written while the list was in flight (e.g. an upload confirmed
    // it) is newer than the listed copy.
    final keepIds = {
      for (final c in local)
        if (c.dirty || before[c.id] != row(c)) c.id,
      for (final op in await _store.getOperations())
        if (op.deckId == deckId) op.cardId,
    };
    final updates = [
      for (final c in remote)
        if (!keepIds.contains(c.id)) c,
    ];
    if (updates.isNotEmpty) await _store.putCards(updates);
    // Cards deleted on the server; dirty ones are dropped by their sync's 404.
    final remoteIds = {for (final c in remote) c.id};
    final gone = [
      for (final c in local)
        if (!remoteIds.contains(c.id) && !keepIds.contains(c.id)) c.id,
    ];
    if (gone.isNotEmpty) await _store.deleteCards(deckId, gone);
  }

  /// Returns false when any file failed to download.
  Future<bool> _downloadFactMedia(
    String deckId,
    List<OfflineFact> facts,
  ) async {
    final mediaKeys = {
      for (final f in facts)
        for (final e in f.entries) ...[
          f.mediaKey(e.audio),
          f.mediaKey(e.image),
        ],
    }..remove('');
    var complete = true;
    var interrupted = false;
    final keys = mediaKeys.toList();
    var next = 0;
    var done = 0;
    Future<void> worker() async {
      // Leaving the foreground pauses the download: files in flight finish,
      // no new one starts, and it resumes when the app is back.
      while (next < keys.length &&
          !interrupted &&
          !_leftForeground.contains(deckId)) {
        final key = keys[next++];
        try {
          await _downloadOne(deckId, key);
        } on _DownloadHalted {
          rethrow;
        } catch (e, s) {
          if (_leftForeground.contains(deckId)) {
            interrupted = true;
            logger.w('Offline media $key paused with the app: $e');
            continue; // Not saved, so not counted in the progress.
          } else {
            complete = false;
            logger.e('Offline media $key failed: $e', stackTrace: s);
          }
        }
        const started = _deckShare + _factsShare;
        const span = 1 - _cardsShare - started;
        _report(deckId, started + span * ++done / keys.length);
      }
    }

    await Future.wait([
      for (var w = 0; w < mediaDownloadConcurrency; w++) worker(),
    ]);
    if (interrupted || _leftForeground.contains(deckId)) {
      throw const _DownloadInterrupted();
    }
    return complete;
  }

  Future<void> _downloadOne(String deckId, String mediaKey) async {
    final cached = await _store.getMediaPath(mediaKey);
    if (cached != null && await File(cached).exists()) return;
    final base = '$_mediaRootDir/$deckId/${mediaKey.replaceFirst('?', '_')}';
    final tmpPath = '$base.part';
    final url = Api.mediaById.replaceFirst('{id}', mediaKey);
    final written = await _downloadMedia(url, tmpPath);
    if (_isHalted(deckId)) {
      final tmp = File(tmpPath);
      if (await tmp.exists()) await tmp.delete();
      throw _DownloadHalted();
    }
    if (written == null || written.isEmpty) {
      throw StateError('download returned no file');
    }
    final path = '$base${await mediaFileExtension(tmpPath)}';
    await File(tmpPath).rename(path);
    await _store.putMediaPath(mediaKey, path);
  }
}

/// Deletes cached media files no stored fact references any more (facts
/// deleted or edited, decks removed).
Future<void> pruneUnusedMedia(OfflineLearningStore store) async {
  final used = <String>{
    for (final deck in await store.getDecks())
      for (final fact in await store.getFacts(deck.id))
        for (final id in fact.mediaIds) fact.mediaKey(id),
  };
  for (final MapEntry(:key, :value) in (await store.getMediaPaths()).entries) {
    if (used.contains(key)) continue;
    final file = File(value);
    if (await file.exists()) await file.delete();
    await store.deleteMedia(key);
  }
}

/// File extension (with dot) sniffed from the file's leading bytes, or '' when
/// the format is unknown. Players and image decoders rely on it.
Future<String> mediaFileExtension(String path) async {
  final file = await File(path).open();
  final head = await file.read(12);
  await file.close();
  bool at(int offset, List<int> bytes) =>
      head.length >= offset + bytes.length &&
      [for (var i = 0; i < bytes.length; i++) head[offset + i]].join(',') ==
          bytes.join(',');
  const riff = [0x52, 0x49, 0x46, 0x46];
  if (at(0, [0x89, 0x50, 0x4E, 0x47])) return '.png';
  if (at(0, [0xFF, 0xD8, 0xFF])) return '.jpg';
  if (at(0, [0x47, 0x49, 0x46, 0x38])) return '.gif';
  if (at(0, riff) && at(8, [0x57, 0x45, 0x42, 0x50])) return '.webp';
  if (at(0, riff) && at(8, [0x57, 0x41, 0x56, 0x45])) return '.wav';
  // MP3 frame sync (11 set bits) with layer III of any MPEG version; AAC ADTS
  // sync (12 set bits) with layer 00.
  final sync = head.length >= 2 && head[0] == 0xFF;
  if (at(0, [0x49, 0x44, 0x33]) ||
      (sync && head[1] & 0xE0 == 0xE0 && head[1] & 0x06 == 0x02)) {
    return '.mp3';
  }
  if (sync && head[1] & 0xF6 == 0xF0) return '.aac';
  if (at(0, [0x66, 0x4C, 0x61, 0x43])) return '.flac';
  if (at(0, [0x4F, 0x67, 0x67, 0x53])) return '.ogg';
  if (at(0, [0x1A, 0x45, 0xDF, 0xA3])) return '.webm';
  if (at(4, [0x66, 0x74, 0x79, 0x70])) return '.m4a';
  return '';
}

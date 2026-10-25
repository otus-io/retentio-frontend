import 'dart:convert';
import 'dart:io';

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
  }) : _store = store,
       _mediaRootDir = mediaRootDir,
       _fetchDeck = fetchDeck ?? DeckService.of.getDeckDetail,
       _fetchFactsPage = fetchFactsPage ?? fetchOfflineFactsPage,
       _fetchFactIds = fetchFactIds ?? fetchOfflineFactIds,
       _fetchCards = fetchCards ?? fetchOfflineCards,
       _downloadMedia = downloadMedia ?? ApiService.downloadFile,
       _fetchMediaVersions = fetchMediaVersions ?? fetchOfflineMediaVersions,
       _nowSec = nowSec ?? _defaultNowSec,
       _isOnline = isOnline ?? hasNetworkConnection;

  static const int factsPageSize = 200;
  static const int versionLookupConcurrency = 4;
  static const int refreshIntervalSec = 3600;

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
  final Map<String, Future<bool>> _inFlight = {};
  final Map<String, int> _halts = {};
  var _haltsAll = 0;

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

  /// Returns true when the deck is study-ready offline. Concurrent calls for
  /// one deck share a single download (they would write the same files).
  /// [fresh] skips a download already running, which may have listed the
  /// deck before a just-made edit, and runs a new one after it.
  Future<bool> download(String deckId, {bool fresh = false}) {
    if (_isHalted(deckId)) return Future.value(false);
    final running = _inFlight[deckId];
    if (running != null && !fresh) return running;
    final started = running == null
        ? _download(deckId)
        : running.then((_) => _download(deckId));
    return _trackInFlight(deckId, started);
  }

  /// A later [download] with `fresh: true` replaces the map entry; only that
  /// one may clear it when it finishes.
  Future<bool> _trackInFlight(String deckId, Future<bool> started) {
    late final Future<bool> tracked;
    tracked = started.whenComplete(() {
      if (identical(_inFlight[deckId], tracked)) _inFlight.remove(deckId);
    });
    return _inFlight[deckId] = tracked;
  }

  Future<bool> _download(String deckId) async {
    try {
      _checkHalted(deckId);
      final fetchedAt = _nowSec();
      final remote = await _fetchDeck(deckId);
      _checkHalted(deckId);
      final before = await _store.getDeck(deckId);
      final (facts, tags) = await _syncFacts(
        deckId,
        _buildDeck(deckId, remote, before, const []),
      );
      await _seedCards(deckId);
      final mediaComplete = await _downloadFactMedia(deckId, facts);
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
      return true;
    } on _DownloadHalted {
      logger.i('Offline download of deck=$deckId stopped for removal');
      return false;
    } catch (e, s) {
      logger.e('Offline download failed for deck=$deckId: $e', stackTrace: s);
      return false;
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

  /// Returns the facts and their distinct tags ordered by id, the order of
  /// `GET /api/tags` used by the online tag filter.
  Future<(List<OfflineFact>, List<Tag>)> _syncFacts(
    String deckId,
    OfflineDeck deck,
  ) async {
    final imported = deck.sourceDeckId.isNotEmpty;
    final stored = imported
        ? await _factsAtSnapshot(deck)
        : <String, OfflineFact>{};
    final all = <OfflineFact>[];
    final tags = <String, Tag>{};
    OfflineFactsPage page;
    do {
      page = await _fetchFactsPage(deckId, factsPageSize, all.length);
      final facts = imported
          ? await _pinMediaVersions(deckId, page.facts, stored)
          : page.facts;
      _checkHalted(deckId);
      await _store.putFacts(facts);
      all.addAll(facts);
      for (final t in page.tags) {
        tags[t.id] = t;
      }
    } while (page.hasMore && page.facts.isNotEmpty);
    await _dropDeletedFacts(deckId);
    return (all, tags.values.toList()..sort((a, b) => a.id.compareTo(b.id)));
  }

  /// Offset paging skips facts when the deck changes meanwhile, so only the
  /// unpaged id list proves a fact was deleted. Kept when it cannot be read.
  Future<void> _dropDeletedFacts(String deckId) async {
    final List<String>? ids;
    try {
      ids = await _fetchFactIds(deckId);
    } catch (e) {
      logger.w('Offline fact ids of deck=$deckId failed: $e');
      return;
    }
    if (ids == null) return;
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
      while (next < pending.length) {
        final i = pending[next++];
        final fact = result[i];
        result[i] = fact.withMediaVersions(await _lookupVersions(deckId, fact));
      }
    }

    await Future.wait([
      for (var w = 0; w < versionLookupConcurrency; w++) worker(),
    ]);
    return result;
  }

  Future<Map<String, int>?> _lookupVersions(
    String deckId,
    OfflineFact fact,
  ) async {
    try {
      return await _fetchMediaVersions(deckId, fact.id);
    } catch (e, s) {
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
    for (final key in mediaKeys) {
      try {
        await _downloadOne(deckId, key);
      } on _DownloadHalted {
        rethrow;
      } catch (e, s) {
        complete = false;
        logger.e('Offline media $key failed: $e', stackTrace: s);
      }
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
  if (at(0, [0x49, 0x44, 0x33]) || at(0, [0xFF, 0xFB])) return '.mp3';
  if (at(0, [0x4F, 0x67, 0x67, 0x53])) return '.ogg';
  if (at(0, [0x1A, 0x45, 0xDF, 0xA3])) return '.webm';
  if (at(4, [0x66, 0x74, 0x79, 0x70])) return '.m4a';
  return '';
}

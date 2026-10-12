import 'dart:io';

import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
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

/// Assembles a deck's offline study package (deck, facts, cards, media) into
/// [OfflineLearningStore]. Server card schedules replace local ones unless the
/// card has unsynced local changes.
class OfflinePackageDownloader {
  OfflinePackageDownloader({
    required OfflineLearningStore store,
    required String mediaRootDir,
    FetchDeckFn? fetchDeck,
    FetchFactsPageFn? fetchFactsPage,
    FetchCardsFn? fetchCards,
    DownloadMediaFn? downloadMedia,
    FetchMediaVersionsFn? fetchMediaVersions,
    int Function()? nowSec,
  }) : _store = store,
       _mediaRootDir = mediaRootDir,
       _fetchDeck = fetchDeck ?? DeckService.of.getDeckDetail,
       _fetchFactsPage = fetchFactsPage ?? fetchOfflineFactsPage,
       _fetchCards = fetchCards ?? fetchOfflineCards,
       _downloadMedia = downloadMedia ?? ApiService.downloadFile,
       _fetchMediaVersions = fetchMediaVersions ?? fetchOfflineMediaVersions,
       _nowSec = nowSec ?? _defaultNowSec;

  static const int factsPageSize = 200;
  static const int versionLookupConcurrency = 4;

  final OfflineLearningStore _store;
  final String _mediaRootDir;
  final FetchDeckFn _fetchDeck;
  final FetchFactsPageFn _fetchFactsPage;
  final FetchCardsFn _fetchCards;
  final DownloadMediaFn _downloadMedia;
  final FetchMediaVersionsFn _fetchMediaVersions;
  final int Function() _nowSec;
  final Map<String, Future<bool>> _inFlight = {};

  /// Returns true when the deck is study-ready offline. Concurrent calls for
  /// one deck share a single download (they would write the same files).
  Future<bool> download(String deckId) =>
      _inFlight[deckId] ??= _download(deckId).whenComplete(() {
        _inFlight.remove(deckId);
      });

  Future<bool> _download(String deckId) async {
    try {
      final remote = await _fetchDeck(deckId);
      final (facts, tags) = await _syncFacts(
        deckId,
        _buildDeck(deckId, remote, await _store.getDeck(deckId), const []),
      );
      await _seedCards(deckId);
      await _downloadFactMedia(deckId, facts);
      // Re-read: sync flushes and tag loads may have written the row meanwhile.
      final local = await _store.getDeck(deckId);
      await _store.putDeck(_buildDeck(deckId, remote, local, tags));
      return true;
    } catch (e, s) {
      logger.e('Offline download failed for deck=$deckId: $e', stackTrace: s);
      return false;
    }
  }

  OfflineDeck _buildDeck(
    String deckId,
    Deck remote,
    OfflineDeck? local,
    List<Tag> tags,
  ) => OfflineDeck(
    id: deckId,
    name: remote.name,
    fields: remote.fields,
    rate: remote.rate,
    sourceDeckId: remote.sourceDeckId,
    sourceVersion: remote.sourceVersion,
    totalReviews: local?.totalReviews ?? remote.stats.totalReviews,
    totalReviewsToday:
        local?.totalReviewsToday ?? remote.stats.totalReviewsToday,
    downloadedAt: local != null && local.isReady
        ? local.downloadedAt
        : _nowSec(),
    lastSyncedAt: local?.lastSyncedAt ?? 0,
    tags: tags,
  );

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
      await _store.putFacts(facts);
      all.addAll(facts);
      for (final t in page.tags) {
        tags[t.id] = t;
      }
    } while (page.hasMore && page.facts.isNotEmpty);
    return (all, tags.values.toList()..sort((a, b) => a.id.compareTo(b.id)));
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
    final remote = await _fetchCards(deckId);
    final dirtyIds = {
      for (final c in await _store.getCards(deckId))
        if (c.dirty) c.id,
      for (final op in await _store.getOperations())
        if (op.deckId == deckId) op.cardId,
    };
    final updates = [
      for (final c in remote)
        if (!dirtyIds.contains(c.id)) c,
    ];
    if (updates.isNotEmpty) await _store.putCards(updates);
  }

  Future<void> _downloadFactMedia(
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
    for (final key in mediaKeys) {
      try {
        await _downloadOne(deckId, key);
      } catch (e, s) {
        logger.e('Offline media $key failed: $e', stackTrace: s);
      }
    }
  }

  Future<void> _downloadOne(String deckId, String mediaKey) async {
    final cached = await _store.getMediaPath(mediaKey);
    if (cached != null && await File(cached).exists()) return;
    final base = '$_mediaRootDir/$deckId/${mediaKey.replaceFirst('?', '_')}';
    final tmpPath = '$base.part';
    final url = Api.mediaById.replaceFirst('{id}', mediaKey);
    final written = await _downloadMedia(url, tmpPath);
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

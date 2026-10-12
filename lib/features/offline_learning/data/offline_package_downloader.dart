import 'dart:io';

import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/utils/log.dart';

int _defaultNowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Assembles a deck's offline study package (deck, facts, cards, media) into
/// [OfflineLearningStore]. Local card schedules win over the server once seeded.
class OfflinePackageDownloader {
  OfflinePackageDownloader({
    required OfflineLearningStore store,
    required String mediaRootDir,
    FetchDeckFn? fetchDeck,
    FetchFactsPageFn? fetchFactsPage,
    FetchCardsFn? fetchCards,
    DownloadMediaFn? downloadMedia,
    int Function()? nowSec,
  }) : _store = store,
       _mediaRootDir = mediaRootDir,
       _fetchDeck = fetchDeck ?? DeckService.of.getDeckDetail,
       _fetchFactsPage = fetchFactsPage ?? fetchOfflineFactsPage,
       _fetchCards = fetchCards ?? fetchOfflineCards,
       _downloadMedia = downloadMedia ?? ApiService.downloadFile,
       _nowSec = nowSec ?? _defaultNowSec;

  static const int factsPageSize = 200;

  final OfflineLearningStore _store;
  final String _mediaRootDir;
  final FetchDeckFn _fetchDeck;
  final FetchFactsPageFn _fetchFactsPage;
  final FetchCardsFn _fetchCards;
  final DownloadMediaFn _downloadMedia;
  final int Function() _nowSec;

  /// Returns true when the deck is study-ready offline.
  Future<bool> download(String deckId) async {
    try {
      final deck = await _buildDeck(deckId);
      final facts = await _syncFacts(deckId);
      await _seedCards(deckId);
      await _downloadFactMedia(deckId, facts);
      await _store.putDeck(
        deck.isReady ? deck : deck.copyWith(downloadedAt: _nowSec()),
      );
      return true;
    } catch (e, s) {
      logger.e('Offline download failed for deck=$deckId: $e', stackTrace: s);
      return false;
    }
  }

  Future<OfflineDeck> _buildDeck(String deckId) async {
    final remote = await _fetchDeck(deckId);
    final local = await _store.getDeck(deckId);
    return OfflineDeck(
      id: deckId,
      name: remote.name,
      fields: remote.fields,
      rate: remote.rate,
      sourceDeckId: remote.sourceDeckId,
      sourceVersion: remote.sourceVersion,
      totalReviews: local?.totalReviews ?? remote.stats.totalReviews,
      totalReviewsToday:
          local?.totalReviewsToday ?? remote.stats.totalReviewsToday,
      downloadedAt: local?.downloadedAt ?? 0,
      lastSyncedAt: local?.lastSyncedAt ?? 0,
      tags: local?.tags ?? const [],
    );
  }

  Future<List<OfflineFact>> _syncFacts(String deckId) async {
    final all = <OfflineFact>[];
    OfflineFactsPage page;
    do {
      page = await _fetchFactsPage(deckId, factsPageSize, all.length);
      await _store.putFacts(page.facts);
      all.addAll(page.facts);
    } while (page.hasMore && page.facts.isNotEmpty);
    return all;
  }

  Future<void> _seedCards(String deckId) async {
    final remote = await _fetchCards(deckId);
    final localIds = {for (final c in await _store.getCards(deckId)) c.id};
    final newCards = [
      for (final c in remote)
        if (!localIds.contains(c.id)) c,
    ];
    if (newCards.isNotEmpty) await _store.putCards(newCards);
  }

  Future<void> _downloadFactMedia(
    String deckId,
    List<OfflineFact> facts,
  ) async {
    final mediaIds = {
      for (final f in facts)
        for (final e in f.entries) ...[e.audio, e.image],
    }..remove('');
    for (final mediaId in mediaIds) {
      try {
        await _downloadOne(deckId, mediaId);
      } catch (e, s) {
        logger.e('Offline media $mediaId failed: $e', stackTrace: s);
      }
    }
  }

  Future<void> _downloadOne(String deckId, String mediaId) async {
    if (await _store.getMediaPath(mediaId) != null) return;
    final path = '$_mediaRootDir/$deckId/$mediaId';
    final tmpPath = '$path.part';
    final url = Api.mediaById.replaceFirst('{id}', mediaId);
    final written = await _downloadMedia(url, tmpPath);
    if (written == null || written.isEmpty) {
      throw StateError('download returned no file');
    }
    await File(tmpPath).rename(path);
    await _store.putMediaPath(mediaId, path);
  }
}

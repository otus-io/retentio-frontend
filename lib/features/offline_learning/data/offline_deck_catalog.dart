import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_deck_stats.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/models/deck.dart';

/// Deck list with local stats for downloaded decks; offline, only the
/// downloaded decks are listed.
class OfflineDeckCatalog {
  OfflineDeckCatalog({
    Future<OfflineLearningSession?> Function()? session,
    Future<bool> Function()? isOnline,
    int Function()? nowSec,
  }) : _session = session ?? OfflineLearningSessions.instance.current,
       _isOnline = isOnline ?? hasNetworkConnection,
       _nowSec =
           nowSec ?? (() => DateTime.now().millisecondsSinceEpoch ~/ 1000);

  final Future<OfflineLearningSession?> Function() _session;
  final Future<bool> Function() _isOnline;
  final int Function() _nowSec;

  Future<List<Deck>> decks(Future<List<Deck>> Function() fetchRemote) async {
    final OfflineLearningStore? store;
    try {
      store = (await _session())?.store;
    } catch (_) {
      return fetchRemote();
    }
    if (store == null) return fetchRemote();
    final local = {
      for (final d in await store.getDecks())
        if (d.isReady) d.id: d,
    };
    if (!await _isOnline()) return _localDecks(store, local.values);
    final List<Deck> remoteDecks;
    try {
      remoteDecks = await fetchRemote();
    } catch (_) {
      // A network interface is up but the server is unreachable.
      if (local.isEmpty) rethrow;
      return _localDecks(store, local.values);
    }
    await _dropDeletedDecks(local.keys, {for (final d in remoteDecks) d.id});
    return [
      for (final remote in remoteDecks)
        if (local[remote.id] case final d?)
          _deck(remote.toJson(), await _stats(store, d))
        else
          remote,
    ];
  }

  /// Removes the copies of decks the server no longer lists (deleted on
  /// another device). The deck list is not paged, but an empty one is never
  /// trusted: it could be an unreadable response.
  Future<void> _dropDeletedDecks(
    Iterable<String> localIds,
    Set<String> remoteIds,
  ) async {
    if (remoteIds.isEmpty) return;
    for (final id in localIds.toList()) {
      if (remoteIds.contains(id)) continue;
      try {
        await remove(id);
      } catch (_) {
        // Retried on the next listing.
      }
    }
  }

  Future<List<Deck>> _localDecks(
    OfflineLearningStore store,
    Iterable<OfflineDeck> decks,
  ) async => [
    for (final d in decks)
      _deck({
        'id': d.id,
        'name': d.name,
        'fields': d.fields,
        'rate': d.rate,
        'source_deck_id': d.sourceDeckId,
        'source_version': d.sourceVersion,
      }, await _stats(store, d)),
  ];

  /// Ids of the downloaded decks that can be studied offline; empty when the
  /// offline storage is unavailable.
  Future<Set<String>> readyDeckIds() async {
    try {
      final store = (await _session())?.store;
      if (store == null) return const {};
      return {
        for (final d in await store.getDecks())
          if (d.isReady) d.id,
      };
    } catch (_) {
      return const {};
    }
  }

  /// Drops the offline copy of a deck deleted on the server.
  Future<void> remove(String deckId) async =>
      (await _session())?.removeDeck(deckId);

  static Deck _deck(Map<String, dynamic> json, DeckStats stats) =>
      Deck.fromJson({...json, 'stats': stats.toJson()});

  Future<DeckStats> _stats(
    OfflineLearningStore store,
    OfflineDeck deck,
  ) async => computeOfflineDeckStats(
    deck: deck,
    cards: await store.getCards(deck.id),
    factsCount: (await store.getFacts(deck.id)).length,
    queued: await store.getOperations(),
    nowSec: _nowSec(),
  );
}

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
    if (!await _isOnline()) {
      return [
        for (final d in local.values)
          _deck({
            'id': d.id,
            'name': d.name,
            'fields': d.fields,
            'rate': d.rate,
            'source_deck_id': d.sourceDeckId,
            'source_version': d.sourceVersion,
          }, await _stats(store, d)),
      ];
    }
    return [
      for (final remote in await fetchRemote())
        if (local[remote.id] case final d?)
          _deck(remote.toJson(), await _stats(store, d))
        else
          remote,
    ];
  }

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

import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/services/apis/api_service.dart';

typedef FetchDeckFn = Future<Deck> Function(String deckId);
typedef FetchFactsPageFn =
    Future<OfflineFactsPage> Function(String deckId, int limit, int offset);
typedef FetchCardsFn = Future<List<OfflineCard>> Function(String deckId);

/// Returns the written path, or null/empty when the download failed.
typedef DownloadMediaFn = Future<String?> Function(String url, String path);

class OfflineFactsPage {
  const OfflineFactsPage({required this.facts, required this.hasMore});

  final List<OfflineFact> facts;
  final bool hasMore;
}

Future<OfflineFactsPage> fetchOfflineFactsPage(
  String deckId,
  int limit,
  int offset,
) async {
  final res = await ApiService.get(
    Api.facts,
    pathParams: {'id': deckId},
    queryParams: {'limit': limit, 'offset': offset},
  );
  return parseOfflineFactsPage(deckId, res?.data, limit: limit);
}

Future<List<OfflineCard>> fetchOfflineCards(String deckId) async {
  final res = await ApiService.get(Api.cards, pathParams: {'id': deckId});
  return parseOfflineCards(deckId, res?.data);
}

/// `ApiResponse` drops the envelope `meta`, so `has_more` is inferred from a
/// full page.
OfflineFactsPage parseOfflineFactsPage(
  String deckId,
  dynamic data, {
  required int limit,
}) {
  final rawFacts = data is Map ? data['facts'] : null;
  if (rawFacts is! List) {
    throw StateError('facts response is missing the facts list');
  }
  final facts = [
    for (final f in rawFacts.whereType<Map>())
      _parseFact(deckId, Map<String, dynamic>.from(f)),
  ];
  return OfflineFactsPage(facts: facts, hasMore: rawFacts.length >= limit);
}

OfflineFact _parseFact(String deckId, Map<String, dynamic> json) => OfflineFact(
  deckId: deckId,
  id: '${json['id'] ?? ''}',
  entries: [
    for (final e in (json['entries'] as List? ?? const []).whereType<Map>())
      FactEntry.fromJson(Map<String, dynamic>.from(e)),
  ],
  tagIds: [
    for (final t in (json['tags'] as List? ?? const []).whereType<Map>())
      if (t['id'] != null) '${t['id']}',
  ],
);

List<OfflineCard> parseOfflineCards(String deckId, dynamic data) {
  final rawCards = data is Map ? data['cards'] : null;
  if (rawCards is! List) {
    throw StateError('cards response is missing the cards list');
  }
  return [
    for (final c in rawCards.whereType<Map>())
      OfflineCard.fromJson({
        ...Map<String, dynamic>.from(c),
        'deck_id': deckId,
        'dirty': false,
      }),
  ];
}

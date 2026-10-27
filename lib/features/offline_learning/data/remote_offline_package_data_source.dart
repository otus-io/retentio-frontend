import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/card_service.dart';

typedef FetchDeckFn = Future<Deck> Function(String deckId);
typedef FetchFactsPageFn =
    Future<OfflineFactsPage> Function(String deckId, int limit, int offset);
typedef FetchCardsFn = Future<List<OfflineCard>> Function(String deckId);

/// Every fact id of the deck, or null when the list could not be read.
typedef FetchFactIdsFn = Future<List<String>?> Function(String deckId);

/// Pinned media versions of one fact, or null when the lookup failed.
typedef FetchMediaVersionsFn =
    Future<Map<String, int>?> Function(String deckId, String factId);

/// Returns the written path, or null/empty when the download failed.
typedef DownloadMediaFn = Future<String?> Function(String url, String path);

class OfflineFactsPage {
  const OfflineFactsPage({
    required this.facts,
    required this.hasMore,
    this.tags = const [],
  });

  final List<OfflineFact> facts;
  final bool hasMore;

  /// Tag objects of the page's facts, possibly repeated.
  final List<Tag> tags;
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

Future<List<String>?> fetchOfflineFactIds(String deckId) async {
  final res = await ApiService.get(Api.factIds, pathParams: {'id': deckId});
  final ids = res != null && res.isSuccess && res.data is Map
      ? (res.data as Map)['fact_ids']
      : null;
  return ids is List ? [for (final id in ids) '$id'] : null;
}

Future<Map<String, int>?> fetchOfflineMediaVersions(
  String deckId,
  String factId,
) async => (await CardService.getFactDetail(deckId, factId))?.mediaVersions;

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
  final pageVersions = (data as Map)['media_versions'];
  final facts = [
    for (final f in rawFacts.whereType<Map>())
      _withListedVersions(
        _parseFact(deckId, Map<String, dynamic>.from(f)),
        f['media_versions'] ?? pageVersions,
      ),
  ];
  return OfflineFactsPage(
    facts: facts,
    hasMore: rawFacts.length >= limit,
    tags: [
      for (final f in rawFacts.whereType<Map>())
        for (final t in (f['tags'] as List? ?? const []).whereType<Map>())
          if (t['id'] != null)
            Tag(
              id: '${t['id']}',
              name: '${t['name'] ?? ''}',
              description: '${t['description'] ?? ''}',
            ),
    ],
  );
}

/// The list endpoint is not documented to return `media_versions`; use them
/// when present, otherwise leave the fact unresolved.
OfflineFact _withListedVersions(OfflineFact fact, dynamic raw) {
  if (raw is! Map) return fact;
  final versions = <String, int>{};
  for (final id in fact.mediaIds) {
    final value = raw[id];
    final v = value is num ? value.toInt() : int.tryParse('$value');
    if (v != null && v > 0) versions[id] = v;
  }
  return fact.withMediaVersions(versions);
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

import 'package:retentio/models/card.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/utils/log.dart';

class DeckCardsStats {
  const DeckCardsStats({this.totalCards, this.dueCards});

  final int? totalCards;
  final int? dueCards;
}

/// Parses GET `/api/decks/{id}/cards` payload (`data` object).
/// Current API: `{ "stats": { "cards_count", "due_cards", ... }, "cards": [...] }`.
DeckCardsStats? parseDeckCardsStatsData(dynamic data, {int? nowSec}) {
  if (data is! Map) return null;
  final map = Map<String, dynamic>.from(data);

  int? totalCards;
  int? dueCards;

  final statsRaw = map['stats'];
  if (statsRaw is Map) {
    final stats = Map<String, dynamic>.from(statsRaw);
    totalCards = _readInt(stats['cards_count']);
    dueCards = _readInt(stats['due_cards']);
  }

  // Legacy top-level fields (older API docs / clients).
  totalCards ??= _readInt(map['total_cards']);
  dueCards ??= _readInt(map['due_cards']);

  // Fallback: derive from cards list when stats omit counts.
  final cardsRaw = map['cards'];
  if (cardsRaw is List) {
    totalCards ??= cardsRaw.length;
    if (dueCards == null) {
      final now = nowSec ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var due = 0;
      for (final item in cardsRaw) {
        if (item is! Map) continue;
        final card = Map<String, dynamic>.from(item);
        if (card['hidden'] == true) continue;
        final dueDate = _readInt(card['due_date']) ?? 0;
        if (dueDate > 0 && dueDate <= now) due++;
      }
      dueCards = due;
    }
  }

  if (totalCards == null && dueCards == null) return null;
  return DeckCardsStats(totalCards: totalCards, dueCards: dueCards);
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class CardService {
  /// 获取卡组卡片统计，可选 [tagId] 限定到带该标签的词条对应卡片。
  static Future<DeckCardsStats?> getCardsStats(
    String deckId, {
    String? tagId,
  }) async {
    try {
      final res = await ApiService.get(
        Api.cards,
        pathParams: {'id': deckId},
        queryParams: tagId != null ? {'tag_id': tagId} : null,
      );
      return parseDeckCardsStatsData(res?.data);
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  /// 获取卡组卡片总数，可选 [tagId] 限定到带该标签的词条对应卡片。
  static Future<int?> getCardsCount(String deckId, {String? tagId}) async {
    final stats = await getCardsStats(deckId, tagId: tagId);
    return stats?.totalCards;
  }

  /// 获取下一张需要学习的卡片，可选 tagId 筛选
  static Future<CardDetail?> getNextDueCard(
    String deckId, {
    String? tagId,
  }) async {
    try {
      final res = await ApiService.get(
        Api.card,
        pathParams: {'id': deckId},
        queryParams: tagId != null ? {'tag_id': tagId} : null,
      );

      if (res?.data == null) {
        return null;
      }

      return CardDetail.tryFromApiData(res!.data);
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  /// Loads a single fact (entries + fields) for editing.
  static Future<Fact?> getFact(String deckId, String factId) async {
    try {
      final res = await ApiService.get(
        Api.fact,
        pathParams: {'id': deckId, 'factId': factId},
      );
      if (res?.data == null) return null;
      final data = res!.data;
      if (data is! Map) return null;
      final factRaw = data['fact'];
      if (factRaw is! Map) return null;
      return Fact.fromJson(Map<String, dynamic>.from(factRaw));
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  static Future<bool?> updateCard(String deckId, dynamic params) async {
    try {
      final res = await ApiService.patch(
        Api.card,
        pathParams: {'id': deckId},
        params: params,
      );

      final data = res?.data;
      final isEmptyData =
          data == null ||
          (data is Map && data.isEmpty) ||
          (data is List && data.isEmpty) ||
          (data is String && data.isEmpty);
      if (isEmptyData) {
        return null; // 没有需要学习的卡片
      }

      return res?.isSuccess == true;
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  /// Permanently removes one card; fact and sibling cards are unchanged (API contract).
  static Future<ApiResponse?> deleteCard(String deckId, String cardId) async {
    try {
      return await ApiService.delete(
        Api.cardById,
        pathParams: {'id': deckId, 'cardId': cardId},
      );
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  /// Updates a fact (`entries`, optional `fields` per API contract).
  static Future<ApiResponse?> updateFact(
    String deckId,
    String factId,
    Map<String, dynamic> body,
  ) async {
    final res = await ApiService.patch(
      Api.fact,
      pathParams: {'id': deckId, 'factId': factId},
      params: body,
    );
    return res;
  }

  /// Loads fact ids for a deck (paged). Used to detect newly added facts.
  static Future<List<String>> listFactIds(String deckId) async {
    final ids = <String>[];
    var offset = 0;
    const limit = 200;
    while (true) {
      final res = await ApiService.get(
        Api.facts,
        pathParams: {'id': deckId},
        queryParams: {'limit': limit, 'offset': offset},
      );
      final data = res?.data;
      if (data is! Map || data['facts'] is! List) break;
      final facts = data['facts'] as List;
      if (facts.isEmpty) break;
      for (final row in facts) {
        if (row is Map && row['id'] != null) {
          ids.add(row['id'].toString());
        }
      }
      if (facts.length < limit) break;
      offset += facts.length;
      if (offset > 10000) break;
    }
    return ids;
  }

  /// Adds one or more facts (`facts`, optional `template` per API contract).
  static Future<ApiResponse?> addFacts(
    String deckId,
    String operation,
    Map<String, dynamic> body,
  ) async {
    try {
      return await ApiService.post(
        Api.factsWithOperation,
        pathParams: {'id': deckId, 'operation': operation},
        body: body,
      );
    } catch (e) {
      logger.e(e);
      return null;
    }
  }
}

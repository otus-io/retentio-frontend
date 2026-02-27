import 'package:wordupx/models/card.dart';
import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/apis/api_service.dart';
import 'package:wordupx/services/index.dart';
import 'package:wordupx/utils/log.dart';

class CardService {
  /// GET /api/decks/{id}/facts — returns all facts for the deck (backend: GetFacts).
  static Future<List<Fact>> getFacts(String deckId) async {
    final res = await ApiService.get(Api.facts, pathParams: {'id': deckId});
    if (res?.isSuccess != true || res?.data is! Map) return [];
    final data = res!.data as Map<String, dynamic>;
    final list = data['facts'];
    if (list is! List) return [];
    return list
        .map((e) => e is Map<String, dynamic> ? Fact.fromJson(e) : null)
        .whereType<Fact>()
        .toList();
  }

  /// GET /api/decks/{id}/card — next urgent card for review (backend: GetNextCard).
  static Future<CardDetail?> getNextCard(String deckId) async {
    try {
      final res = await ApiService.get(Api.card, pathParams: {'id': deckId});
      if (res?.isSuccess != true || res?.data is! Map) return null;
      return CardDetail.fromJson(Map<String, dynamic>.from(res!.data as Map));
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  static Future<ResBaseModel?> updateCard(
    String deckId,
    Map<String, dynamic> params,
  ) async {
    return ApiService.patch(
      Api.card,
      pathParams: {'id': deckId},
      params: params,
    );
  }

  /// GET /api/decks/{id}/cards — card statistics (backend: GetCards).
  static Future<CardStats?> getCardStats(String deckId) async {
    try {
      final res = await ApiService.get(Api.cards, pathParams: {'id': deckId});
      if (res?.isSuccess != true || res?.data is! Map) return null;
      return CardStats.fromJson(Map<String, dynamic>.from(res!.data as Map));
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  /// DELETE a single card. Fact and other cards for that fact are unchanged.
  static Future<ResBaseModel?> deleteCard(String deckId, String cardId) async {
    return ApiService.delete(
      Api.cardById,
      pathParams: {'id': deckId, 'cardId': cardId},
    );
  }

  /// POST /api/decks/{id}/reschedule — shift due dates by days.
  static Future<ResBaseModel?> reschedule(
    String deckId, {
    required int days,
  }) async {
    return ApiService.post(
      Api.reschedule,
      pathParams: {'id': deckId},
      body: {'days': days},
    );
  }

  static Future<Fact?> getFact(String deckId, String factId) async {
    try {
      final res = await ApiService.get(
        Api.fact,
        pathParams: {'id': deckId, 'factId': factId},
      );
      if (res?.isSuccess != true || res?.data is! Map) return null;
      final data = res!.data as Map<String, dynamic>;
      final factData = data['fact'];
      if (factData is! Map<String, dynamic>) return null;
      return Fact.fromJson(factData);
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  static Future<ResBaseModel?> updateFact(
    String deckId,
    String factId,
    dynamic params,
  ) async {
    return ApiService.patch(
      Api.fact,
      pathParams: {'id': deckId, 'factId': factId},
      params: params,
    );
  }
}

import 'package:retentio/models/card.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/utils/log.dart';

class CardService {
  /// 获取下一张需要学习的卡片
  static Future<CardDetail?> getNextDueCard(String deckId) async {
    try {
      final res = await ApiService.get(Api.card, pathParams: {'id': deckId});

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

      if (res?.data.isEmpty) {
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

import 'package:wordupx/models/card.dart';
import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/apis/api_service.dart';
import 'package:wordupx/services/index.dart';
import 'package:wordupx/utils/log.dart';

class CardService {
  /// 获取指定 deck 的所有卡片
  static Future<List<Fact>> getDeckCards(String deckId) async {
    final res = await ApiService.get(Api.facts, pathParams: {'id': deckId});

    if (res?.isSuccess == true) {
      final fats = List.from(
        res?.data['facts'],
      ).map((e) => Fact.fromJson(e)).toList();
      return fats;
    }

    return [];
  }

  /// 获取下一张需要学习的卡片
  static Future<CardDetail?> getNextDueCard(String deckId) async {
    try {
      final res = await ApiService.get(Api.card, pathParams: {'id': deckId});

      if (res?.data.isEmpty) {
        return null; // 没有需要学习的卡片
      }

      return CardDetail.fromJson(res?.data);
    } catch (e) {
      return null;
    }
  }

  static Future<CardDetail?> updateCard(String deckId, dynamic params) async {
    try {
      final res = await ApiService.patch(
        Api.card,
        pathParams: {'id': deckId},
        params: params,
      );

      if (res?.data.isEmpty) {
        return null; // 没有需要学习的卡片
      }

      return CardDetail.fromJson(res?.data);
    } catch (e) {
      return null;
    }
  }

  /// Returns a specific fact by ID
  static Future<Fact?> getFact(String deckId, String factId) async {
    try {
      final res = await ApiService.get(
        Api.fact,
        pathParams: {'id': deckId, 'factId': factId},
      );

      if (res?.data.isEmpty) {
        return null; // 没有需要学习的卡片
      }

      return Fact.fromJson(res?.data['fact']);
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  /// Updates a fact in a deck
  static Future<ResBaseModel?> updateFact(
    String deckId,
    String factId,
    dynamic params,
  ) async {
    final res = await ApiService.patch(
      Api.fact,
      pathParams: {'id': deckId, 'factId': factId},
      params: params,
    );
    return res;
  }
}

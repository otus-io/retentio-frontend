import 'package:wordupx/models/card.dart';
import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/apis/api_service.dart';
import 'package:wordupx/services/index.dart';

class CardService {
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

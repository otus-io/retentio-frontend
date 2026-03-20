import 'package:retentio/models/card.dart';
import 'package:retentio/models/res_base_model.dart';
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

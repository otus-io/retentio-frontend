import 'package:wordupx/models/card.dart';
import 'package:wordupx/services/apis/api_service.dart';

class CardService {
  /// 获取指定 deck 的卡片统计信息
  static Future<Map<String, dynamic>> getCardStats(String deckId) async {
    final res = await ApiService.get('/api/decks/$deckId/cards');

    if (res?.isSuccess == true) {
      return res!.data as Map<String, dynamic>;
    }

    return {'total_cards': 0, 'hidden_count': 0, 'hidden_facts': []};
  }

  /// 获取下一张需要学习的卡片
  static Future<Card?> getNextUrgentCard(String deckId) async {
    try {
      final res = await ApiService.get('/api/decks/$deckId/urgent-card');

      if (res?.data.isEmpty) {
        return null; // 没有需要学习的卡片
      }

      return Card.fromJson(res?.data);
    } catch (e) {
      return null;
    }
  }
}

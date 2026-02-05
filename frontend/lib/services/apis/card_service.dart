import 'package:wordupx/models/card.dart';
import 'package:wordupx/services/apis/api_service.dart';

class CardService {
  /// 获取指定 deck 的所有卡片
  static Future<List<Card>> getDeckCards(String deckId) async {
    final res = await ApiService.get('/api/decks/$deckId/cards/all-cards');


    if (res?.isSuccess==true) {
      return (res?.data['cards'])
          .map((cardJson) => Card.fromJson(cardJson as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// 获取下一张需要学习的卡片
  static Future<Card?> getNextDueCard(String deckId) async {
    try {
      final res = await ApiService.get('/api/decks/$deckId/next-due-card');

      if (res?.data.isEmpty) {
        return null; // 没有需要学习的卡片
      }

      return Card.fromJson(res?.data);
    } catch (e) {
      print('Error getting next due card: $e');
      return null;
    }
  }
}

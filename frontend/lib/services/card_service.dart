import 'package:wordupx/models/card.dart';
import 'package:wordupx/services/api_service.dart';

class CardService {
  /// 获取指定 deck 的所有卡片
  static Future<List<Card>> getDeckCards(String deckId) async {
    final data = await ApiService.get('/api/decks/$deckId/cards/all-cards');

    print('=== All Cards API Response ===');
    print('Data type: ${data.runtimeType}');
    print('Data keys: ${data.keys}');
    if (data['cards'] != null && data['cards'] is List) {
      print('Cards count: ${(data['cards'] as List).length}');
      if ((data['cards'] as List).isNotEmpty) {
        print('First card sample: ${(data['cards'] as List).first}');
      }
    }
    print('============================');

    if (data['cards'] != null && data['cards'] is List) {
      return (data['cards'] as List)
          .map((cardJson) => Card.fromJson(cardJson as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// 获取下一张需要学习的卡片
  static Future<Card?> getNextDueCard(String deckId) async {
    try {
      final data = await ApiService.get('/api/decks/$deckId/next-due-card');

      if (data.isEmpty) {
        return null; // 没有需要学习的卡片
      }

      return Card.fromJson(data);
    } catch (e) {
      print('Error getting next due card: $e');
      return null;
    }
  }
}

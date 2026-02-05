import 'api_service.dart';
import '../../models/deck.dart';

class DeckService {
  /// 获取所有 decks
  static Future<List<Deck>> getDecks() async {
    try {
      final res = await ApiService.get('/api/decks');
      // 如果返回的 data 包含 decks 字段
      if (res?.data['decks'] != null && res?.data['decks'] is List) {
        final decksList = res?.data['decks'] as List;
        return decksList
            .map((deckJson) => Deck.fromJson(deckJson as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error in getDecks: $e');
      rethrow;
    }
  }

  /// 获取单个 deck 的详细信息（包含 facts）
  static Future<Deck> getDeckDetail(String deckId) async {
    try {
      final res = await ApiService.get('/api/decks/$deckId');
      return Deck.fromJson(res?.data);
    } catch (e) {
      print('Error in getDeckDetail: $e');
      rethrow;
    }
  }
}

import 'package:wordupx/services/index.dart';

import 'api_service.dart';
import '../../models/deck.dart';

class DeckService {
  static final DeckService of = DeckService._();
  DeckService._();

  /// 获取所有 decks
  Future<List<Deck>> getDecks() async {
    try {
      final res = await ApiService.get(Api.decks);
      // 如果返回的 data 包含 decks 字段
      if (res?.data['decks'] != null && res?.data['decks'] is List) {
        final decksList = res?.data['decks'] as List;
        return decksList
            .map((deckJson) => Deck.fromJson(deckJson as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// 获取单个 deck 的详细信息（包含 facts）
  Future<Deck> getDeckDetail(String deckId) async {
    try {
      final res = await ApiService.get(Api.deck, pathParams: {'id': deckId});
      return Deck.fromJson(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 创建 deck
  Future<void> createDeck(dynamic params) async {}
}

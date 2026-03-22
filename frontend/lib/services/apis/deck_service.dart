import 'package:retentio/services/index.dart';

import '../../models/res_base_model.dart';
import 'api_service.dart';
import '../../models/deck.dart';

class DeckService {
  static final DeckService of = DeckService._();
  DeckService._();

  /// 获取所有 decks
  Future<List<Deck>> getDecks() async {
    try {
      final res = await ApiService.get(Api.decks);
      final data = res?.data;
      // `res?.data['k']` is parsed as `(res?.data)['k']` — subscript on null throws.
      if (data is Map && data['decks'] is List) {
        final decksList = data['decks'] as List;
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
      final raw = res?.data;
      if (raw is! Map) {
        throw StateError(
          'getDeckDetail: response data is missing or not a map',
        );
      }
      return Deck.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      rethrow;
    }
  }

  /// 创建 deck
  Future<ResBaseModel?> createDeck(dynamic params) async {
    return ApiService.post(Api.decks, body: params);
  }

  /// 删除 deck
  Future<ResBaseModel?> deleteDeck(String deckId) async {
    return ApiService.delete(Api.deck, pathParams: {'id': deckId});
  }

  Future<ResBaseModel?> updateDeck({
    required String deckId,
    required Map<String, dynamic> params,
  }) async {
    return ApiService.patch(
      Api.deck,
      pathParams: {'id': deckId},
      params: params,
    );
  }
}

import 'package:wordupx/services/index.dart';

import '../../models/res_base_model.dart';
import 'api_service.dart';
import '../../models/deck.dart';

class DeckService {
  static final DeckService of = DeckService._();
  DeckService._();

  /// 获取所有 decks
  Future<List<Deck>> getDecks() async {
    final res = await ApiService.get(Api.decks);
    if (res?.isSuccess != true || res?.data is! Map) return [];
    final data = res!.data as Map<String, dynamic>;
    final decksList = data['decks'];
    if (decksList is! List) return [];
    return decksList
        .map((e) => e is Map<String, dynamic> ? Deck.fromJson(e) : null)
        .whereType<Deck>()
        .toList();
  }

  /// 获取单个 deck 的详细信息（包含 facts）
  Future<Deck> getDeckDetail(String deckId) async {
    final res = await ApiService.get(Api.deck, pathParams: {'id': deckId});
    if (res?.isSuccess != true || res?.data is! Map<String, dynamic>) {
      throw Exception(res?.msg ?? 'Failed to load deck');
    }
    return Deck.fromJson(res!.data as Map<String, dynamic>);
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

import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/index.dart';
import 'api_service.dart';

class FactService {
  /// Add facts to a deck. Operation: append, prepend, shuffle, spread.
  static Future<ResBaseModel?> addFacts(
    String deckId,
    String operation, {
    required List<Map<String, dynamic>> facts,
    List<List<List<int>>>? template,
  }) async {
    final body = <String, dynamic>{
      'facts': facts,
      if (template != null && template.isNotEmpty) 'template': template,
    };
    return ApiService.post(
      Api.factsWithOperation,
      pathParams: {'id': deckId, 'operation': operation},
      body: body,
    );
  }

  /// Add a card for an existing fact (e.g. reversed/sibling).
  /// [template] is [[front indices], [back indices]], e.g. [[0],[1]] or [[1],[0]] for reversed.
  static Future<ResBaseModel?> addCardForFact(
    String deckId,
    String factId, {
    required List<List<int>> template,
  }) async {
    return ApiService.post(
      Api.factsWithOperation,
      pathParams: {'id': deckId, 'operation': 'add_card'},
      body: {'fact_id': factId, 'template': template},
    );
  }

  static Future<ResBaseModel?> deleteFact(String deckId, String factId) async {
    return ApiService.delete(
      Api.fact,
      pathParams: {'id': deckId, 'factId': factId},
    );
  }
}

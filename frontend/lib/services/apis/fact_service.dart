import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/index.dart';
import 'api_service.dart';

/// Add-fact API (POST /api/decks/{id}/facts/{operation}): body is facts and optional template.
/// To add a card from an existing fact, use POST /api/decks/{id}/card (see CardService or addCardForFact below).
class FactService {
  /// Validates add-fact body: facts array is required.
  static String? validateAddFactBody({required bool hasFacts}) {
    if (!hasFacts) return 'Facts array is required.';
    return null;
  }

  /// Add facts to a deck. Operation: append, prepend, shuffle, spread.
  /// Body: facts and optional template (no fact_id).
  static Future<ResBaseModel?> addFacts(
    String deckId,
    String operation, {
    required List<Map<String, dynamic>> facts,
    List<List<List<int>>>? template,
  }) async {
    final err = validateAddFactBody(hasFacts: facts.isNotEmpty);
    if (err != null) {
      return ResBaseModel.fromJson({'success': false, 'msg': err});
    }
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

  /// Add a card for an existing fact (e.g. reversed/sibling). Uses POST /api/decks/{id}/card.
  /// [template] is [[front indices], [back indices]], e.g. [[0],[1]] or [[1],[0]] for reversed.
  /// [operation] controls placement: append, prepend, shuffle, or spread (default: append).
  static Future<ResBaseModel?> addCardForFact(
    String deckId,
    String factId, {
    required List<List<int>> template,
    String operation = 'append',
  }) async {
    if (factId.isEmpty) {
      return ResBaseModel.fromJson({
        'success': false,
        'msg': 'fact_id is required.',
      });
    }
    final body = <String, dynamic>{
      'fact_id': factId,
      'template': template,
      if (operation != 'append') 'operation': operation,
    };
    return ApiService.post(Api.card, pathParams: {'id': deckId}, body: body);
  }

  static Future<ResBaseModel?> deleteFact(String deckId, String factId) async {
    return ApiService.delete(
      Api.fact,
      pathParams: {'id': deckId, 'factId': factId},
    );
  }
}

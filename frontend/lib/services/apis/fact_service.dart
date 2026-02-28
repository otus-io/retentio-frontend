import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/index.dart';
import 'api_service.dart';

/// Fact add API: same as backend — exactly one of these request shapes:
/// (1) facts only, (2) facts + template, (3) fact_id + template.
class FactService {
  /// Validates add-fact body shape. Returns error message or null if valid.
  static String? validateAddFactBody({
    required bool hasFactId,
    required bool hasFacts,
  }) {
    if (hasFactId && hasFacts) {
      return 'Invalid request: use exactly one of (1) facts only, (2) facts + template, (3) fact_id + template — not both fact_id and facts.';
    }
    if (!hasFactId && !hasFacts) {
      return 'Invalid request: use one of (1) facts only, (2) facts + template, (3) fact_id + template.';
    }
    return null;
  }

  /// Add facts to a deck. Operation: append, prepend, shuffle, spread.
  /// Valid shape: (1) facts only or (2) facts + template.
  static Future<ResBaseModel?> addFacts(
    String deckId,
    String operation, {
    required List<Map<String, dynamic>> facts,
    List<List<List<int>>>? template,
  }) async {
    final err = validateAddFactBody(
      hasFactId: false,
      hasFacts: facts.isNotEmpty,
    );
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

  /// Add a card for an existing fact (e.g. reversed/sibling).
  /// Valid shape: (3) fact_id + template.
  /// [template] is [[front indices], [back indices]], e.g. [[0],[1]] or [[1],[0]] for reversed.
  /// [operation] controls placement: append, prepend, shuffle, or spread (default: append).
  static Future<ResBaseModel?> addCardForFact(
    String deckId,
    String factId, {
    required List<List<int>> template,
    String operation = 'append',
  }) async {
    final err = validateAddFactBody(
      hasFactId: factId.isNotEmpty,
      hasFacts: false,
    );
    if (err != null) {
      return ResBaseModel.fromJson({'success': false, 'msg': err});
    }
    return ApiService.post(
      Api.factsWithOperation,
      pathParams: {'id': deckId, 'operation': operation},
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

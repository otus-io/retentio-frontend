import 'package:retentio/models/fact_quality.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';

/// Editorial quality reads/writes used only by QA mode.
///
/// Reads answer `null` on every failure (missing record, 403, offline) so
/// nothing outside QA mode depends on this API being healthy.
class FactQualityService {
  static final FactQualityService of = FactQualityService._();
  FactQualityService._();

  Future<FactQuality?> getFactQuality({
    required String deckId,
    required String factId,
  }) async {
    final res = await ApiService.get(
      Api.factQuality,
      pathParams: {'id': deckId, 'factId': factId},
    );
    final data = res?.data;
    if (res?.isSuccess != true || data is! Map) return null;
    final quality = data['quality'];
    if (quality is! Map) return null;
    return FactQuality.fromJson(Map<String, dynamic>.from(quality));
  }

  Future<FactQualityStats?> getDeckQualityStats(String deckId) async {
    final res = await ApiService.get(
      Api.deckQualityStats,
      pathParams: {'id': deckId},
    );
    final data = res?.data;
    if (res?.isSuccess != true || data is! Map) return null;
    return FactQualityStats.fromJson(Map<String, dynamic>.from(data));
  }

  /// Replaces the whole quality record. Throws with the API `msg` on failure.
  ///
  /// When [columns] is non-empty, the server advances those per-column resume
  /// cursors to [factId] (forward-only).
  Future<void> putFactQuality({
    required String deckId,
    required String factId,
    required Map<String, dynamic> entries,
    List<int>? columns,
  }) async {
    final body = <String, dynamic>{'entries': entries};
    if (columns != null && columns.isNotEmpty) {
      body['columns'] = columns.toList()..sort();
    }
    final res = await ApiService.put(
      Api.factQuality,
      pathParams: {'id': deckId, 'factId': factId},
      body: body,
    );
    if (res == null || !res.isSuccess) {
      throw Exception(res?.msg ?? 'quality_put_failed');
    }
  }
}

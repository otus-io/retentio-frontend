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

  /// The fact's quality record, or `null` when it has none or the read failed.
  /// Use [readFactQuality] when those two must not be confused.
  Future<FactQuality?> getFactQuality({
    required String deckId,
    required String factId,
  }) async => (await readFactQuality(deckId: deckId, factId: factId)).quality;

  /// Reads the quality record. `known` is false when the read failed, so a
  /// `null` quality then does not mean "no record": a PUT replaces the whole
  /// record and would wipe one that merely could not be read.
  Future<({FactQuality? quality, bool known})> readFactQuality({
    required String deckId,
    required String factId,
  }) async {
    final res = await ApiService.get(
      Api.factQuality,
      pathParams: {'id': deckId, 'factId': factId},
    );
    if (res?.exception?.response?.statusCode == 404) {
      return (quality: null, known: true);
    }
    final data = res?.data;
    final quality = data is Map ? data['quality'] : null;
    if (res?.isSuccess != true || quality is! Map) {
      return (quality: null, known: false);
    }
    return (
      quality: FactQuality.fromJson(Map<String, dynamic>.from(quality)),
      known: true,
    );
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
  Future<void> putFactQuality({
    required String deckId,
    required String factId,
    required Map<String, dynamic> entries,
  }) async {
    final res = await ApiService.put(
      Api.factQuality,
      pathParams: {'id': deckId, 'factId': factId},
      body: {'entries': entries},
    );
    if (res == null || !res.isSuccess) {
      throw Exception(res?.msg ?? 'quality_put_failed');
    }
  }
}

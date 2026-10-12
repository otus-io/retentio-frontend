import 'package:retentio/models/api_response.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/services/index.dart';

typedef StudyPatchFn =
    Future<ApiResponse?> Function(
      String deckId,
      Map<String, dynamic> body,
      Map<String, dynamic> headers,
    );
typedef DeckDetailFn = Future<Deck> Function(String deckId);

/// Typed outcome of one `PATCH /api/decks/{id}/card`.
class StudyPatchResult {
  const StudyPatchResult({this.httpStatus, this.data, this.message});

  /// Null when no response was received (network error).
  final int? httpStatus;

  /// `last_review`/`due_date`/`new_interval` or `hidden_status`.
  final Map<String, dynamic>? data;
  final String? message;

  bool get isSuccess =>
      httpStatus != null && httpStatus! >= 200 && httpStatus! < 300;
}

/// Server review counters from `GET /api/decks/{id}` `stats`.
class OfflineDeckCounts {
  const OfflineDeckCounts({
    required this.totalReviews,
    required this.totalReviewsToday,
  });

  final int totalReviews;
  final int totalReviewsToday;
}

class StudySyncRemoteDataSource {
  StudySyncRemoteDataSource({StudyPatchFn? patchFn, DeckDetailFn? deckDetailFn})
    : _patchFn = patchFn ?? _defaultPatch,
      _deckDetailFn = deckDetailFn ?? DeckService.of.getDeckDetail;

  final StudyPatchFn _patchFn;
  final DeckDetailFn _deckDetailFn;

  static Future<ApiResponse?> _defaultPatch(
    String deckId,
    Map<String, dynamic> body,
    Map<String, dynamic> headers,
  ) => ApiService.patch(
    Api.card,
    pathParams: {'id': deckId},
    params: body,
    headers: headers,
  );

  Future<StudyPatchResult> patchCard(
    String deckId,
    Map<String, dynamic> body, {
    required String operationId,
  }) async {
    final res = await _patchFn(deckId, body, {'Idempotency-Key': operationId});
    final error = res?.exception;
    final data = res?.data;
    return StudyPatchResult(
      // Dio only resolves (no exception) for 2xx under the default validateStatus.
      httpStatus: error == null ? 200 : error.response?.statusCode,
      data: data is Map ? Map<String, dynamic>.from(data) : null,
      message: res?.msg,
    );
  }

  Future<OfflineDeckCounts?> fetchDeckCounts(String deckId) async {
    try {
      final stats = (await _deckDetailFn(deckId)).stats;
      return OfflineDeckCounts(
        totalReviews: stats.totalReviews,
        totalReviewsToday: stats.totalReviewsToday,
      );
    } catch (_) {
      return null;
    }
  }
}

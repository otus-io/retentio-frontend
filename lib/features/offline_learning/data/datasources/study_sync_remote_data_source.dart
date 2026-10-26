import 'package:retentio/core/network/interceptors/response_normalize_interceptor.dart';
import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
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
  const StudyPatchResult({
    this.httpStatus,
    this.data,
    this.message,
    this.isApiError = false,
  });

  /// Null when no response was received (network error).
  final int? httpStatus;

  /// `last_review`/`due_date`/`new_interval` or `hidden_status`.
  final Map<String, dynamic>? data;
  final String? message;

  /// The error body is the API JSON envelope (`msg`/`message`), so the status
  /// came from the API rather than a gateway or proxy.
  final bool isApiError;

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
  StudySyncRemoteDataSource({
    StudyPatchFn? patchFn,
    DeckDetailFn? deckDetailFn,
    FetchCardsFn? fetchCardsFn,
  }) : _patchFn = patchFn ?? _defaultPatch,
       _deckDetailFn = deckDetailFn ?? _defaultDeckDetail,
       _fetchCardsFn = fetchCardsFn ?? _defaultFetchCards;

  /// Flush requests run in the background: a stale token must surface as
  /// `needsLogin`, not log the user out via the global 401 handler.
  static const _keepSession = {
    ResponseNormalizeInterceptor.keepSessionOn401: true,
  };

  static Future<Deck> _defaultDeckDetail(String deckId) =>
      DeckService.of.getDeckDetail(deckId, extra: _keepSession);

  static Future<List<OfflineCard>> _defaultFetchCards(String deckId) =>
      fetchOfflineCards(deckId, extra: _keepSession);

  final StudyPatchFn _patchFn;
  final DeckDetailFn _deckDetailFn;
  final FetchCardsFn _fetchCardsFn;

  static Future<ApiResponse?> _defaultPatch(
    String deckId,
    Map<String, dynamic> body,
    Map<String, dynamic> headers,
  ) => ApiService.patch(
    Api.card,
    pathParams: {'id': deckId},
    params: body,
    headers: headers,
    extra: _keepSession,
  );

  Future<StudyPatchResult> patchCard(
    String deckId,
    Map<String, dynamic> body, {
    required String operationId,
  }) async {
    final res = await _patchFn(deckId, body, {'Idempotency-Key': operationId});
    final error = res?.exception;
    final data = res?.data;
    final errorBody = error?.response?.data;
    return StudyPatchResult(
      // Dio only resolves (no exception) for 2xx under the default validateStatus.
      httpStatus: error == null ? 200 : error.response?.statusCode,
      data: data is Map ? Map<String, dynamic>.from(data) : null,
      message: res?.msg,
      isApiError:
          errorBody is Map &&
          (errorBody.containsKey('msg') || errorBody.containsKey('message')),
    );
  }

  /// Server schedules of the deck's cards, or null when they cannot be read.
  Future<List<OfflineCard>?> fetchCards(String deckId) async {
    try {
      return await _fetchCardsFn(deckId);
    } catch (_) {
      return null;
    }
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

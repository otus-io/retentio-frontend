import 'package:retentio/models/review_stats.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';

class ReviewStatsService {
  static final ReviewStatsService of = ReviewStatsService._();
  ReviewStatsService._();

  static const supportedRanges = <int>{7, 30, 90, 365};

  Future<ReviewStatsSeries> getByDay({
    required String deckId,
    required int days,
  }) async {
    if (!supportedRanges.contains(days)) {
      throw ArgumentError.value(days, 'days', 'Unsupported statistics range');
    }
    final response = await ApiService.get(
      Api.reviewsByDay,
      pathParams: {'id': deckId},
      queryParams: {'days': days},
    );
    if (response == null || !response.isSuccess) {
      throw Exception(response?.msg ?? 'review_stats_load_failed');
    }
    return ReviewStatsSeries.fromData(response.data, expectedDays: days);
  }
}

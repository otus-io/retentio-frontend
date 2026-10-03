import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/review_stats.dart';

void main() {
  group('ReviewStatsSeries', () {
    test('parses a dense UTC response and calculates metrics', () {
      final series = ReviewStatsSeries.fromData({
        'timezone': 'UTC',
        'days': [
          {'day': '20260917', 'count': 0},
          {'day': '20260918', 'count': 2},
          {'day': '20260919', 'count': 4},
        ],
      }, expectedDays: 3);

      expect(series.days.first.day, DateTime.utc(2026, 9, 17));
      expect(series.totalReviews, 6);
      expect(series.todayReviews, 4);
      expect(series.activeDays, 2);
      expect(series.dailyAverage, 2);
    });

    test('rejects invalid dates, counts, timezone, and sparse days', () {
      expect(
        () => ReviewStatsSeries.fromData({
          'timezone': 'Asia/Shanghai',
          'days': [
            {'day': '20260919', 'count': 1},
          ],
        }, expectedDays: 1),
        throwsFormatException,
      );
      expect(
        () => ReviewStatsSeries.fromData({
          'timezone': 'UTC',
          'days': [
            {'day': '20260230', 'count': 1},
          ],
        }, expectedDays: 1),
        throwsFormatException,
      );
      expect(
        () => ReviewStatsSeries.fromData({
          'timezone': 'UTC',
          'days': [
            {'day': '20260917', 'count': -1},
          ],
        }, expectedDays: 1),
        throwsFormatException,
      );
      expect(
        () => ReviewStatsSeries.fromData({
          'timezone': 'UTC',
          'days': [
            {'day': '20260917', 'count': 1},
            {'day': '20260919', 'count': 1},
          ],
        }, expectedDays: 2),
        throwsFormatException,
      );
    });

    test('aggregates aligned decks and rejects different date windows', () {
      ReviewStatsSeries make(String first, String second, int count) =>
          ReviewStatsSeries.fromData({
            'timezone': 'UTC',
            'days': [
              {'day': first, 'count': count},
              {'day': second, 'count': count + 1},
            ],
          }, expectedDays: 2);

      final aggregate = ReviewStatsSeries.aggregate([
        make('20260918', '20260919', 1),
        make('20260918', '20260919', 3),
      ]);
      expect(aggregate.days.map((day) => day.count), [4, 6]);

      expect(
        () => ReviewStatsSeries.aggregate([
          make('20260918', '20260919', 1),
          make('20260919', '20260920', 1),
        ]),
        throwsFormatException,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/value_objects/review_interval_range.dart';

void main() {
  group('ReviewIntervalRange.fromTimestamps', () {
    test('urgency >= 1 uses 0.5x and 4x current interval (overdue)', () {
      const lastReview = 1000;
      const dueDate = 2000;
      const nowSec = 2500;
      final r = ReviewIntervalRange.fromTimestamps(
        nowSec: nowSec,
        lastReview: lastReview,
        dueDate: dueDate,
      );

      expect(r.currentIntervalSec, 1000);
      expect(r.urgency, 1.5);
      expect(r.minInterval, 500.0);
      expect(r.maxInterval, 4000.0);
      expect(r.midInterval, 2000.0);
    });

    test('urgency == 1 uses overdue branch', () {
      const lastReview = 1000;
      const dueDate = 2000;
      const nowSec = 2000;
      final r = ReviewIntervalRange.fromTimestamps(
        nowSec: nowSec,
        lastReview: lastReview,
        dueDate: dueDate,
      );

      expect(r.urgency, 1.0);
      expect(r.minInterval, 500.0);
      expect(r.maxInterval, 4000.0);
    });

    test('urgency < 1 interpolates min/max toward current interval', () {
      const lastReview = 1000;
      const dueDate = 2000;
      const nowSec = 1500;
      final r = ReviewIntervalRange.fromTimestamps(
        nowSec: nowSec,
        lastReview: lastReview,
        dueDate: dueDate,
      );

      expect(r.urgency, 0.5);
      expect(r.minInterval, 750.0);
      expect(r.maxInterval, 2500.0);
      expect(r.midInterval, 1500.0);
    });

    test('dueDate == lastReview returns zeros (invalid window)', () {
      final r = ReviewIntervalRange.fromTimestamps(
        nowSec: 5000,
        lastReview: 1000,
        dueDate: 1000,
      );

      expect(r.currentIntervalSec, 0);
      expect(r.minInterval, 0.0);
      expect(r.maxInterval, 0.0);
      expect(r.midInterval, 0.0);
      expect(r.urgency, 0.0);
    });

    test('dueDate < lastReview returns zeros', () {
      final r = ReviewIntervalRange.fromTimestamps(
        nowSec: 5000,
        lastReview: 2000,
        dueDate: 1000,
      );

      expect(r.currentIntervalSec, 0);
      expect(r.minInterval, 0.0);
      expect(r.maxInterval, 0.0);
    });

    test(
      'raw interval under 300s floors basis interval; keeps true currentInterval',
      () {
        const lastReview = 1000;
        const dueDate = 1005;
        const nowSec = 1010;
        final r = ReviewIntervalRange.fromTimestamps(
          nowSec: nowSec,
          lastReview: lastReview,
          dueDate: dueDate,
        );

        expect(r.currentIntervalSec, 5);
        expect(r.urgency, closeTo(10 / 300, 1e-9));
        expect(r.minInterval, 295.0);
        expect(r.maxInterval, 330.0);
        expect(r.midInterval, 310.0);
      },
    );

    test('urgency 0 widens max when rounded bounds collapse', () {
      const lastReview = 1000;
      const dueDate = 1050;
      const nowSec = 1000;
      final r = ReviewIntervalRange.fromTimestamps(
        nowSec: nowSec,
        lastReview: lastReview,
        dueDate: dueDate,
      );

      expect(r.currentIntervalSec, 50);
      expect(r.urgency, 0.0);
      expect(r.minInterval, 300.0);
      expect(r.maxInterval, 1200.0);
      expect(r.midInterval, 300.0);
    });
  });
}

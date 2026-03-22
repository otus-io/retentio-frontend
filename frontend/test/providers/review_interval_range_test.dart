import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/providers/review_interval_range.dart';

void main() {
  group('computeReviewIntervalRange', () {
    test('urgency >= 1 uses 0.5x and 4x current interval (overdue)', () {
      const lastReview = 1000;
      const dueDate = 2000;
      const nowSec = 2500;
      final r = computeReviewIntervalRange(
        nowSec: nowSec,
        lastReview: lastReview,
        dueDate: dueDate,
      );

      expect(r.currentIntervalSec, 1000);
      expect(r.urgency, 1.5);
      expect(r.minInterval, 500.0);
      expect(r.maxInterval, 4000.0);
      expect(r.midInterval, 2250.0);
    });

    test('urgency == 1 uses overdue branch', () {
      const lastReview = 1000;
      const dueDate = 2000;
      const nowSec = 2000;
      final r = computeReviewIntervalRange(
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
      final r = computeReviewIntervalRange(
        nowSec: nowSec,
        lastReview: lastReview,
        dueDate: dueDate,
      );

      expect(r.urgency, 0.5);
      expect(r.minInterval, 750.0);
      expect(r.maxInterval, 2500.0);
      expect(r.midInterval, 1625.0);
    });

    test('dueDate == lastReview returns zeros (invalid window)', () {
      final r = computeReviewIntervalRange(
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
      final r = computeReviewIntervalRange(
        nowSec: 5000,
        lastReview: 2000,
        dueDate: 1000,
      );

      expect(r.currentIntervalSec, -1000);
      expect(r.minInterval, 0.0);
      expect(r.maxInterval, 0.0);
    });
  });
}

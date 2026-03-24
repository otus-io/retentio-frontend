import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/formatters/review_interval_label.dart';

void main() {
  group('formatReviewIntervalLabel', () {
    test('formats seconds range', () {
      expect(formatReviewIntervalLabel(0), '0s');
      expect(formatReviewIntervalLabel(59), '59s');
      expect(formatReviewIntervalLabel(59.1), '60s');
    });

    test('formats minutes range', () {
      expect(formatReviewIntervalLabel(60), '1m');
      expect(formatReviewIntervalLabel(61), '2m');
      expect(formatReviewIntervalLabel(3599), '60m');
    });

    test('formats hours range', () {
      expect(formatReviewIntervalLabel(3600), '1.0h');
      expect(formatReviewIntervalLabel(86399), '24.0h');
    });

    test('formats days range', () {
      expect(formatReviewIntervalLabel(86400), '1.0d');
      expect(formatReviewIntervalLabel(2591999), '30.0d');
    });

    test('formats months and years range', () {
      expect(formatReviewIntervalLabel(2592000), '1.0mo');
      expect(formatReviewIntervalLabel(31103999), '12.0mo');
      expect(formatReviewIntervalLabel(31104000), '1.0y');
    });
  });
}

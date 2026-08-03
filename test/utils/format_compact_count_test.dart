import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/utils/format_compact_count.dart';

void main() {
  group('formatCompactCount', () {
    test('keeps small counts as plain digits', () {
      expect(formatCompactCount(0), '0');
      expect(formatCompactCount(999), '999');
    });

    test('compacts thousands with two decimal places', () {
      expect(formatCompactCount(1000), '1.00k');
      expect(formatCompactCount(1200), '1.20k');
      expect(formatCompactCount(1234), '1.23k');
    });

    test('compacts millions with two decimal places', () {
      expect(formatCompactCount(1500000), '1.50M');
    });
  });
}

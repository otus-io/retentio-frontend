import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';

void main() {
  group('intervalLabelThumbPreferredSize', () {
    test('grows with accessibility text scale', () {
      final normal = intervalLabelThumbPreferredSize(1);
      final large = intervalLabelThumbPreferredSize(1.5);
      final larger = intervalLabelThumbPreferredSize(2);

      expect(normal.height, lessThan(large.height));
      expect(large.height, lessThan(larger.height));
      expect(normal.width, 64);
      expect(large.width, 64);
    });

    test('uses labelHeight floor at normal and small text scales', () {
      final atOne = intervalLabelThumbPreferredSize(1);
      final small = intervalLabelThumbPreferredSize(0.5);
      // Baseline matches pre-scale fixed pill height (thumb + gap + labelHeight)*2.
      expect(atOne.height, 70);
      expect(small.height, atOne.height);
    });
  });
}

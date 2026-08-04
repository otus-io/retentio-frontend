import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_body.dart';

void main() {
  group('studyCardHeight', () {
    test('uses 62% of a tall viewport', () {
      expect(studyCardHeight(800), closeTo(496, 0.0001));
    });

    test('leaves room for the controls when 62% would crowd them', () {
      // 62% of 380 is 235.6, more than the 230 left after the bottom reserve.
      expect(studyCardHeight(380), closeTo(230, 0.0001));
    });

    test(
      'falls back to the minimum on short viewports instead of throwing',
      () {
        // Upper bound (height - 150) drops below the 180 minimum here; clamp
        // throws ArgumentError if the bounds are not ordered.
        for (final height in [330.0, 300.0, 200.0, 100.0, 0.0]) {
          expect(studyCardHeight(height), 180.0, reason: 'height=$height');
        }
      },
    );
  });
}

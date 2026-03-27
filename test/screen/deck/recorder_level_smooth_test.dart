import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/recorder_level_smooth.dart';

void main() {
  group('smoothRecorderVisualizationLevel', () {
    test('blends toward raw sample', () {
      expect(smoothRecorderVisualizationLevel(0, 1), closeTo(0.45, 1e-9));
      expect(smoothRecorderVisualizationLevel(1, 0), closeTo(0.55, 1e-9));
    });

    test('clamps to 0..1', () {
      expect(smoothRecorderVisualizationLevel(1, 1), 1.0);
      expect(smoothRecorderVisualizationLevel(0, 0), 0.0);
      expect(smoothRecorderVisualizationLevel(1, 2), 1.0);
      expect(smoothRecorderVisualizationLevel(0, -1), 0.0);
    });
  });
}

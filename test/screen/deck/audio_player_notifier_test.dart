import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';

void main() {
  group('AudioPlayerNotifier.computeAtEnd (end-of-track detection)', () {
    test('liveDurationMs == 0: never atEnd via position branch', () {
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 0,
          livePositionMs: 0,
        ),
        isFalse,
      );
    });

    test('short clip (≤200ms): position 0 is not atEnd', () {
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 100,
          livePositionMs: 0,
        ),
        isFalse,
      );
    });

    test('short clip (≤200ms): atEnd only when position == full duration', () {
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 100,
          livePositionMs: 100,
        ),
        isTrue,
      );
    });

    test('normal clip (>200ms): position just below threshold → not atEnd', () {
      // threshold = 2000 - 200 = 1800
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 2000,
          livePositionMs: 1799,
        ),
        isFalse,
      );
    });

    test('normal clip (>200ms): position at threshold → atEnd', () {
      // threshold = 2000 - 200 = 1800
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 2000,
          livePositionMs: 1800,
        ),
        isTrue,
      );
    });

    test('processingState.completed is always atEnd regardless of position', () {
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.completed,
          liveDurationMs: 2000,
          livePositionMs: 0,
        ),
        isTrue,
      );
    });

    test('exactly 200ms clip: threshold == liveDuration, position 199 not atEnd', () {
      // 200 > 200 is false → endThresholdMs = liveDurationMs = 200
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 200,
          livePositionMs: 199,
        ),
        isFalse,
      );
    });

    test('exactly 200ms clip: position 200 → atEnd', () {
      expect(
        AudioPlayerNotifier.computeAtEnd(
          processingState: ProcessingState.ready,
          liveDurationMs: 200,
          livePositionMs: 200,
        ),
        isTrue,
      );
    });
  });
}

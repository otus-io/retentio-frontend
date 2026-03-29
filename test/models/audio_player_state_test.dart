import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';

void main() {
  group('AudioPlayerState', () {
    test('copyWith preserves unspecified fields', () {
      final s = AudioPlayerState(
        audioUrl: 'https://x/a.mp3',
        isPlaying: true,
        isReady: true,
        loadFailed: false,
        positionMs: 1500,
        maxDurationMs: 90_000,
        waveform: [0.1, 0.2],
      );
      final u = s.copyWith(positionMs: 2000);
      expect(u.positionMs, 2000);
      expect(u.audioUrl, s.audioUrl);
      expect(u.isPlaying, true);
      expect(u.isReady, true);
      expect(u.maxDurationMs, 90_000);
      expect(u.waveform, s.waveform);
    });

    test('defaults position and maxDuration to zero', () {
      final s = AudioPlayerState();
      expect(s.positionMs, 0);
      expect(s.maxDurationMs, 0);
      expect(s.waveform, isEmpty);
    });
  });
}

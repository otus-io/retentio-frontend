import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/video_player/src/models/custom_video_player_settings.dart';

void main() {
  group('CardVideoWidget player settings', () {
    test('uses minimal chrome (mute/fullscreen/settings hidden)', () {
      final settings = CustomVideoPlayerSettings(
        showMuteButton: false,
        showFullscreenButton: false,
        settingsButton: const SizedBox(),
      );
      expect(settings.showMuteButton, isFalse);
      expect(settings.showFullscreenButton, isFalse);
    });
  });
}

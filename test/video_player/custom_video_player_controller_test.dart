import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/video_player/src/custom_video_player_controller.dart';
import 'package:retentio/video_player/src/models/custom_video_player_settings.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../helpers/test_video_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomVideoPlayerController', () {
    late VideoPlayerPlatform previousPlatform;

    setUp(() {
      previousPlatform = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = TestVideoPlayerPlatform();
    });

    tearDown(() {
      VideoPlayerPlatform.instance = previousPlatform;
    });

    testWidgets('play then pause does not throw (position may be null)', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      final vpc = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/test.mp4'),
      );
      await vpc.initialize();

      final custom = CustomVideoPlayerController(
        context: context,
        videoPlayerController: vpc,
        customVideoPlayerSettings: const CustomVideoPlayerSettings(),
      );

      await vpc.play();
      await tester.pump(const Duration(milliseconds: 150));
      await vpc.pause();
      await tester.pump(const Duration(milliseconds: 50));

      custom.dispose();
      await tester.pump();
    });
  });
}

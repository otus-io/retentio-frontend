import 'package:flutter/material.dart';

import 'custom_video_player_controller.dart';
import 'embedded_video_player.dart';

class CustomVideoPlayer extends StatelessWidget {
  final CustomVideoPlayerController customVideoPlayerController;
  const CustomVideoPlayer({
    super.key,
    required this.customVideoPlayerController,
  });

  @override
  Widget build(BuildContext context) {
    return EmbeddedVideoPlayer(
      isFullscreen: false,
      customVideoPlayerController: customVideoPlayerController,
    );
  }
}

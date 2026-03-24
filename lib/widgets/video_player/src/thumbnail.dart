import 'package:flutter/cupertino.dart';

import 'custom_video_player_controller.dart';

class Thumbnail extends StatelessWidget {
  final CustomVideoPlayerController customVideoPlayerController;
  const Thumbnail({super.key, required this.customVideoPlayerController});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: customVideoPlayerController.isPlayingNotifier,
      builder: ((context, isPlaying, child) {
        if (!isPlaying) {
          if (customVideoPlayerController
              .customVideoPlayerSettings
              .alwaysShowThumbnailOnVideoPaused) {
            return customVideoPlayerController
                    .customVideoPlayerSettings
                    .thumbnailWidget ??
                const SizedBox.shrink();
          } else {
            return ValueListenableBuilder<Duration>(
              valueListenable:
                  customVideoPlayerController.videoProgressNotifier,
              builder: ((context, progress, child) {
                if (progress == Duration.zero) {
                  return customVideoPlayerController
                          .customVideoPlayerSettings
                          .thumbnailWidget ??
                      const SizedBox.shrink();
                } else {
                  return const SizedBox.shrink();
                }
              }),
            );
          }
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

import 'controls/all_controls_overlay.dart';
import 'custom_video_player_controller.dart';
import 'seek_buttons.dart';
import 'thumbnail.dart';
import 'volume_control.dart';

class EmbeddedVideoPlayer extends StatefulWidget {
  final CustomVideoPlayerController customVideoPlayerController;
  final bool isFullscreen;

  const EmbeddedVideoPlayer({
    super.key,
    required this.customVideoPlayerController,
    this.isFullscreen = false,
  });

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  @override
  void initState() {
    super.initState();

    if (!widget.isFullscreen) {
      widget.customVideoPlayerController.updateViewAfterFullscreen =
          _updateVideoState;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget
        .customVideoPlayerController
        .videoPlayerController
        .value
        .isInitialized) {
      return AspectRatio(
        aspectRatio: widget.isFullscreen
            ? widget
                  .customVideoPlayerController
                  .videoPlayerController
                  .value
                  .aspectRatio
            : widget
                      .customVideoPlayerController
                      .customVideoPlayerSettings
                      .customAspectRatio ??
                  widget
                      .customVideoPlayerController
                      .videoPlayerController
                      .value
                      .aspectRatio,
        child: Stack(
          children: [
            Container(color: CupertinoColors.black),
            Center(
              child: AspectRatio(
                aspectRatio: widget
                    .customVideoPlayerController
                    .videoPlayerController
                    .value
                    .aspectRatio,
                child: IgnorePointer(
                  child: VideoPlayer(
                    widget.customVideoPlayerController.videoPlayerController,
                  ),
                ),
              ),
            ),
            Thumbnail(
              customVideoPlayerController: widget.customVideoPlayerController,
            ),
            AllControlsOverlay(
              customVideoPlayerController: widget.customVideoPlayerController,
              updateVideoState: _updateVideoState,
            ),
            if (widget
                .customVideoPlayerController
                .customVideoPlayerSettings
                .showSeekButtons)
              SeekButtons(
                customVideoPlayerController: widget.customVideoPlayerController,
              ),
            VolumeControls(
              customVideoPlayerController: widget.customVideoPlayerController,
            ),
          ],
        ),
      );
    } else {
      return widget
              .customVideoPlayerController
              .customVideoPlayerSettings
              .placeholderWidget ??
          const SizedBox.shrink();
    }
  }

  void _updateVideoState() {
    if (mounted) {
      setState(() {});
    }
  }
}

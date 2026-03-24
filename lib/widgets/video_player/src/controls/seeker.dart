import 'package:flutter/material.dart';

import '../custom_video_player_controller.dart';

class CustomVideoPlayerSeeker extends StatefulWidget {
  final Widget child;
  final CustomVideoPlayerController customVideoPlayerController;
  const CustomVideoPlayerSeeker({
    super.key,
    required this.child,
    required this.customVideoPlayerController,
  });

  @override
  State createState() => _CustomVideoPlayerSeekerState();
}

class _CustomVideoPlayerSeekerState extends State<CustomVideoPlayerSeeker> {
  bool _videoPlaying = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: widget.child,
      onHorizontalDragStart: (DragStartDetails details) {
        if (!widget
            .customVideoPlayerController
            .videoPlayerController
            .value
            .isInitialized) {
          return;
        }
        _videoPlaying = widget
            .customVideoPlayerController
            .videoPlayerController
            .value
            .isPlaying;
        if (_videoPlaying) {
          widget.customVideoPlayerController.videoPlayerController.pause();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!widget
            .customVideoPlayerController
            .videoPlayerController
            .value
            .isInitialized) {
          return;
        }
        changeCurrentVideoPosition(details.globalPosition);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_videoPlaying) {
          widget.customVideoPlayerController.videoPlayerController.play();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!widget
            .customVideoPlayerController
            .videoPlayerController
            .value
            .isInitialized) {
          return;
        }
        changeCurrentVideoPosition(details.globalPosition);
      },
    );
  }

  void changeCurrentVideoPosition(Offset globalPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position =
        widget
            .customVideoPlayerController
            .videoPlayerController
            .value
            .duration *
        relative;
    widget.customVideoPlayerController.videoPlayerController.seekTo(position);
    widget.customVideoPlayerController.videoProgressNotifier.value = position;
  }
}

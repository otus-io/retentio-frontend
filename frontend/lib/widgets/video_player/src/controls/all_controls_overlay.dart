import 'package:flutter/material.dart';

import '../custom_video_player_controller.dart';
import 'control_bar.dart';
import 'video_settings_button.dart';

class AllControlsOverlay extends StatefulWidget {
  final CustomVideoPlayerController customVideoPlayerController;
  final Function updateVideoState;
  const AllControlsOverlay({
    super.key,
    required this.customVideoPlayerController,
    required this.updateVideoState,
  });

  @override
  State<AllControlsOverlay> createState() => _AllControlsOverlayState();
}

class _AllControlsOverlayState extends State<AllControlsOverlay> {
  bool _controlsVisible = true;
  int _visibilityToggleCounter = 0;

  @override
  void initState() {
    super.initState();
    _fadeOutControls();
    widget.customVideoPlayerController.isPlayingNotifier.addListener(
      _listenToPlayStateChanges,
    );
  }

  @override
  void dispose() {
    widget.customVideoPlayerController.isPlayingNotifier.removeListener(
      _listenToPlayStateChanges,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _toggleControlsVisibility(context),
      child: Container(
        padding: widget
            .customVideoPlayerController
            .customVideoPlayerSettings
            .controlsPadding,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: _controlsVisible
              ? Column(
                  children: [
                    if (widget
                        .customVideoPlayerController
                        .customVideoPlayerSettings
                        .settingsButtonAvailable)
                      Align(
                        alignment: Alignment.topLeft,
                        child: VideoSettingsButton(
                          customVideoPlayerController:
                              widget.customVideoPlayerController,
                          updateVideoState: widget.updateVideoState,
                        ),
                      ),
                    const Spacer(),
                    if (widget
                        .customVideoPlayerController
                        .customVideoPlayerSettings
                        .controlBarAvailable)
                      CustomVideoPlayerControlBar(
                        customVideoPlayerController:
                            widget.customVideoPlayerController,
                        updateVideoState: widget.updateVideoState,
                        fadeOutOnPlay: _fadeOutControls,
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  void _listenToPlayStateChanges() {
    if (widget.customVideoPlayerController.isPlayingNotifier.value) {
      _fadeOutControls();
    }
  }

  void _toggleControlsVisibility(BuildContext context) {
    widget.customVideoPlayerController.areControlsVisible.value =
        !_controlsVisible;
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _fadeOutControls();
    }
  }

  Future<void> _fadeOutControls() async {
    widget.customVideoPlayerController.areControlsVisible.value = true;
    _visibilityToggleCounter++;
    await Future.delayed(
      widget
          .customVideoPlayerController
          .customVideoPlayerSettings
          .durationAfterControlsFadeOut,
      () {
        _visibilityToggleCounter--;

        // only toggle visibility if the video is playing
        if (widget
                .customVideoPlayerController
                .customVideoPlayerSettings
                .autoFadeOutControls &&
            widget
                .customVideoPlayerController
                .videoPlayerController
                .value
                .isPlaying) {
          if (_controlsVisible && _visibilityToggleCounter == 0) {
            widget.customVideoPlayerController.areControlsVisible.value = false;
            if (mounted) {
              setState(() {
                _controlsVisible = false;
              });
            }
          }
        }
      },
    );
  }
}

import 'package:flutter/cupertino.dart';

import '../custom_video_player_controller.dart';

class CustomVideoPlayerMuteButton extends StatefulWidget {
  final CustomVideoPlayerController customVideoPlayerController;
  final Function fadeOutOnPlay;

  const CustomVideoPlayerMuteButton({
    super.key,
    required this.customVideoPlayerController,
    required this.fadeOutOnPlay,
  });

  @override
  State<CustomVideoPlayerMuteButton> createState() =>
      _CustomVideoPlayerMuteButtonState();
}

class _CustomVideoPlayerMuteButtonState
    extends State<CustomVideoPlayerMuteButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _muteUnMute(),
      child: isMute
          ? const CustomVideoUnMuteButton()
          : const CustomVideoMuteButton(),
    );
  }

  bool get isMute => volume == 0;

  double get volume =>
      widget.customVideoPlayerController.videoPlayerController.value.volume;

  Future<void> _muteUnMute() async {
    if (isMute) {
      widget.customVideoPlayerController.unMute();
    } else {
      widget.customVideoPlayerController.mute();
    }
    setState(() {});
  }
}

class CustomVideoMuteButton extends StatelessWidget {
  const CustomVideoMuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
      child: Icon(CupertinoIcons.volume_mute, color: CupertinoColors.white),
    );
  }
}

class CustomVideoUnMuteButton extends StatelessWidget {
  const CustomVideoUnMuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
      child: Icon(CupertinoIcons.volume_off, color: CupertinoColors.white),
    );
  }
}

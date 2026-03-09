import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:retentio/services/apis/api_service.dart';
import '../../../widgets/video_player/src/custom_video_player.dart';
import '../../../widgets/video_player/src/custom_video_player_controller.dart';
import '../../../widgets/video_player/src/models/custom_video_player_settings.dart';

class CardVideoWidget extends StatefulWidget {
  const CardVideoWidget({super.key, required this.url});

  final String url;

  @override
  State createState() => _CardVideoWidgetState();
}

class _CardVideoWidgetState extends State<CardVideoWidget>
    with AutomaticKeepAliveClientMixin {
  late final VideoPlayerController _controller;
  late CustomVideoPlayerController _customVideoPlayerController;

  @override
  dispose() {
    _controller.dispose();
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {'Authorization': ApiService.authorization},
    );

    _controller.initialize().then((value) {
      setState(() {
        isInit = true;
        _customVideoPlayerController = CustomVideoPlayerController(
          context: context,
          videoPlayerController: _controller,
          customVideoPlayerSettings: CustomVideoPlayerSettings(
            showMuteButton: false,
            showFullscreenButton: false,
            settingsButton: const SizedBox(),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: isInit
          ? CustomVideoPlayer(
              customVideoPlayerController: _customVideoPlayerController,
            )
          : SizedBox(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

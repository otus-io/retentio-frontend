import 'package:flutter/material.dart';
import 'package:native_cache_video_player/native_cache_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:wordupx/services/apis/api_service.dart';
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
  late final NativeCacheVideoPlayer _player;
  late CustomVideoPlayerController _customVideoPlayerController;

  VideoPlayerController get _controller => _player.controller;

  @override
  dispose() {
    _player.dispose();
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    _player = NativeCacheVideoPlayer.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {'Authorization': ApiService.authorization},
    );

    _player.initialize().then((value) {
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import '../../../mixins/delayed_init_mixin.dart';
import '../../../video_player/src/custom_video_player.dart';
import '../../../video_player/src/custom_video_player_controller.dart';
import '../../../video_player/src/models/custom_video_player_settings.dart';

class CardVideo extends StatefulWidget {
  const CardVideo({super.key, required this.url});

  final String url;

  @override
  State createState() => _CardVideoState();
}

class _CardVideoState extends State<CardVideo>
    with AutomaticKeepAliveClientMixin, DelayedInitMixin {
  late final VideoPlayerController _controller;
  CustomVideoPlayerController? _customVideoPlayerController;
  TabController? _tabController;
  dynamic _flipController;
  int _currentIndex = 0;
  bool _currentIsFront = true;

  void _handleController() {
    final tc = _tabController;
    if (tc == null) return;
    final index = tc.index;
    if (index != _currentIndex) {
      _controller.pause();
    }
  }

  void _handleCardSideChange() {
    final controller = _flipController;
    if (controller == null) return;
    if (_currentIsFront != controller.isFront) {
      _currentIsFront = controller.isFront;
      _controller.pause();
    }
  }

  @override
  void afterFirstLayout() {
    _tabController = DefaultTabController.maybeOf(context);
    _currentIndex = _tabController?.index ?? 0;
    _tabController?.addListener(_handleController);
    try {
      _flipController = context.read<DeckStudyFlipCardControllerCubit>().state;
    } catch (_) {
      _flipController = null;
    }
    _currentIsFront = _flipController?.isFront ?? true;
    _flipController?.addListener(_handleCardSideChange);
  }

  @override
  @override
  void dispose() {
    _tabController?.removeListener(_handleController);
    _flipController?.removeListener(_handleCardSideChange);
    final custom = _customVideoPlayerController;
    if (custom != null) {
      custom.dispose();
    } else {
      _controller.dispose();
    }
    super.dispose();
  }

  bool isInit = false;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {'Authorization': ApiService.authorization},
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
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
    return isInit && _customVideoPlayerController != null
        ? CustomVideoPlayer(
            customVideoPlayerController: _customVideoPlayerController!,
          )
        : isError
        ? Center(
            child: Row(
              mainAxisSize: .min,
              spacing: 5,
              children: [Icon(LucideIcons.bug), Text('Error')],
            ),
          )
        : Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
  }

  @override
  bool get wantKeepAlive => true;
}

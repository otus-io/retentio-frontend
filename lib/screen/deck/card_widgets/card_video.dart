import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';
import 'package:video_player/video_player.dart';
import 'package:retentio/services/apis/api_service.dart';
import '../../../mixins/delayed_init_mixin.dart';
import '../../../video_player/src/custom_video_player.dart';
import '../../../video_player/src/custom_video_player_controller.dart';
import '../../../video_player/src/models/custom_video_player_settings.dart';

class CardVideo extends ConsumerStatefulWidget {
  const CardVideo({super.key, required this.url});

  final String url;

  @override
  ConsumerState createState() => _CardVideoState();
}

class _CardVideoState extends ConsumerState<CardVideo>
    with AutomaticKeepAliveClientMixin, DelayedInitMixin {
  late final VideoPlayerController _controller;
  CustomVideoPlayerController? _customVideoPlayerController;
  TabController? _tabController;
  int _currentIndex = 0;
  bool _currentIsBack = false;

  void _handleController() {
    final tc = _tabController;
    if (tc == null) return;
    final index = tc.index;
    if (index != _currentIndex) {
      _controller.pause();
    }
  }

  @override
  void afterFirstLayout() {
    _tabController = DefaultTabController.maybeOf(context);
    _currentIndex = _tabController?.index ?? 0;
    _tabController?.addListener(_handleController);
    _currentIsBack = ref.read(cardProvider.select((value) => value.showAnswer));
    ref.listenManual(cardProvider.select((value) => value.showAnswer), (
      previous,
      next,
    ) {
      if (_currentIsBack != next) {
        _controller.pause();
      }
    });
  }

  @override
  dispose() {
    _tabController?.removeListener(_handleController);
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

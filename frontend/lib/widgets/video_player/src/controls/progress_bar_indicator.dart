import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../custom_video_player_controller.dart';

class CustomVideoPlayerProgressIndicator extends StatefulWidget {
  final double progress;
  final CustomVideoPlayerController customVideoPlayerController;
  final Color progressColor;
  final Color backgroundColor;

  const CustomVideoPlayerProgressIndicator({
    super.key,
    required this.customVideoPlayerController,
    required this.progressColor,
    required this.backgroundColor,
    required this.progress,
  });

  @override
  State createState() => _State();
}

class _State extends State<CustomVideoPlayerProgressIndicator> {
  Size mySize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return WidgetSize(
      onChange: (size) {
        setState(() {
          mySize = size;
        });
      },
      child: _getProgressBar(),
    );
  }

  Widget _getProgressBar() {
    return Container(
      width: double.infinity,
      height: widget
          .customVideoPlayerController
          .customVideoPlayerSettings
          .customVideoPlayerProgressBarSettings
          .progressBarHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(
          widget
              .customVideoPlayerController
              .customVideoPlayerSettings
              .customVideoPlayerProgressBarSettings
              .progressBarBorderRadius,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          width: _getProgressValue(mySize.width, widget.progress),
          decoration: BoxDecoration(
            color: widget.progressColor,
            borderRadius: BorderRadius.circular(
              widget
                  .customVideoPlayerController
                  .customVideoPlayerSettings
                  .customVideoPlayerProgressBarSettings
                  .progressBarBorderRadius,
            ),
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        ),
      ),
    );
  }

  double _getProgressValue(double maxValue, double? progress) {
    if (!(maxValue > 0) || progress == null || !(progress > 0)) {
      return 0;
    }
    return maxValue * progress;
  }
}

class WidgetSize extends StatefulWidget {
  final Widget child;
  final Function onChange;

  const WidgetSize({super.key, required this.onChange, required this.child});

  @override
  State createState() => _WidgetSizeState();
}

class _WidgetSizeState extends State<WidgetSize> {
  T? _ambiguate<T>(T? value) => value; // to support older flutter versions

  @override
  Widget build(BuildContext context) {
    _ambiguate(
      SchedulerBinding.instance,
    )!.addPostFrameCallback(postFrameCallback);
    return Container(key: widgetKey, child: widget.child);
  }

  GlobalKey widgetKey = GlobalKey();
  Size? oldSize;

  void postFrameCallback(_) {
    BuildContext? context = widgetKey.currentContext;
    if (context == null || context.size == null) return;
    Size newSize = context.size!;
    if (oldSize == newSize) return;

    oldSize = newSize;
    widget.onChange(newSize);
  }
}

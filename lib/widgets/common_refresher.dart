import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../extensions/widget_extension.dart';

const double _kFooterSpacing = 15;
const int _kFooterCompleteDurationMs = 300;
const double _kFooterContentIconSize = 25;
const double _kFooterLoadingStrokeWidth = 2;
const double _kFooterOnSurfaceOpacity = 0.56;

class CommonRefresher extends StatelessWidget {
  const CommonRefresher({
    super.key,
    required this.controller,
    this.scrollController,
    this.onRefresh,
    this.onLoading,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.header,
    this.footer,
    this.onTwoLevel,
    this.dragStartBehavior,
    this.primary,
    this.cacheExtent,
    this.semanticChildCount,
    this.reverse,
    this.physics,
    this.scrollDirection,
    this.child,
    this.isLoading = false,
    this.isEmpty = false,
    this.emptyView,
  });

  final RefreshController controller;
  final ScrollController? scrollController;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoading;
  final bool enablePullDown;
  final bool enablePullUp;
  final Widget? header;
  final Widget? footer;
  final ValueChanged<bool>? onTwoLevel;
  final DragStartBehavior? dragStartBehavior;
  final bool? primary;
  final double? cacheExtent;
  final int? semanticChildCount;
  final bool? reverse;
  final ScrollPhysics? physics;
  final Axis? scrollDirection;
  final Widget? child;

  // TODO: 待完善
  final bool isLoading;
  final bool isEmpty;
  final Widget? emptyView;

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller,
      scrollController: scrollController,
      onRefresh: onRefresh,
      onLoading: onLoading,
      enablePullDown: enablePullDown,
      enablePullUp: enablePullUp,
      header: header,
      footer: footer,
      onTwoLevel: onTwoLevel,
      dragStartBehavior: dragStartBehavior,
      primary: primary,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      reverse: reverse,
      physics: physics,
      scrollDirection: scrollDirection,
      child: isLoading
          ? const CupertinoActivityIndicator().center
          : isEmpty
          ? (emptyView ?? const SizedBox())
          : child,
    );
  }
}

class CustomClassicFooter extends LoadIndicator {
  final String? idleText;
  final String? loadingText;
  final String? noDataText;
  final String? failedText;
  final String? canLoadingText;

  final OuterBuilder? outerBuilder;

  final Widget? idleIcon;
  final Widget? loadingIcon;
  final Widget? noMoreIcon;
  final Widget? failedIcon;
  final Widget? canLoadingIcon;

  final double spacing;

  final IconPosition iconPos;

  final TextStyle? textStyle;

  final Duration completeDuration;

  const CustomClassicFooter({
    super.key,
    super.onClick,
    super.loadStyle,
    super.height,
    this.outerBuilder,
    this.textStyle,
    this.loadingText,
    this.noDataText,
    this.noMoreIcon,
    this.idleText,
    this.failedText,
    this.canLoadingText,
    this.failedIcon,
    this.iconPos = IconPosition.left,
    this.spacing = _kFooterSpacing,
    this.completeDuration = const Duration(
      milliseconds: _kFooterCompleteDurationMs,
    ),
    this.loadingIcon,
    this.canLoadingIcon,
    this.idleIcon,
  });

  @override
  State<StatefulWidget> createState() {
    return _ClassicFooterState();
  }
}

class _ClassicFooterState extends LoadIndicatorState<CustomClassicFooter> {
  TextStyle _textStyle(BuildContext context, ColorScheme scheme) =>
      widget.textStyle ??
      (Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: _kFooterOnSurfaceOpacity),
          ) ??
          TextStyle(
            color: scheme.onSurface.withValues(alpha: _kFooterOnSurfaceOpacity),
          ));

  Widget _statusIcon({required ColorScheme scheme, required IconData icon}) =>
      Icon(
        icon,
        color: scheme.onSurface.withValues(alpha: _kFooterOnSurfaceOpacity),
      );

  Widget _buildText(LoadStatus? mode) {
    final scheme = Theme.of(context).colorScheme;
    RefreshString strings =
        RefreshLocalizations.of(context)?.currentLocalization ??
        EnRefreshString();
    return Text(
      mode == LoadStatus.loading
          ? widget.loadingText ?? strings.loadingText!
          : LoadStatus.noMore == mode
          ? widget.noDataText ?? strings.noMoreText!
          : LoadStatus.failed == mode
          ? widget.failedText ?? strings.loadFailedText!
          : LoadStatus.canLoading == mode
          ? widget.canLoadingText ?? strings.canLoadingText!
          : widget.idleText ?? strings.idleLoadingText!,
      style: _textStyle(context, scheme),
    );
  }

  Widget _buildIcon(LoadStatus? mode) {
    final scheme = Theme.of(context).colorScheme;
    Widget? icon = mode == LoadStatus.loading
        ? widget.loadingIcon ??
              SizedBox(
                width: _kFooterContentIconSize,
                height: _kFooterContentIconSize,
                child: defaultTargetPlatform == TargetPlatform.iOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(
                        strokeWidth: _kFooterLoadingStrokeWidth,
                      ),
              )
        : mode == LoadStatus.noMore
        ? widget.noMoreIcon
        : mode == LoadStatus.failed
        ? widget.failedIcon ??
              _statusIcon(scheme: scheme, icon: Icons.error_outline_rounded)
        : mode == LoadStatus.canLoading
        ? widget.canLoadingIcon ??
              _statusIcon(scheme: scheme, icon: Icons.autorenew_rounded)
        : widget.idleIcon ??
              _statusIcon(scheme: scheme, icon: Icons.arrow_upward_rounded);
    return icon ?? Container();
  }

  @override
  Future endLoading() {
    return Future.delayed(widget.completeDuration);
  }

  @override
  Widget buildContent(BuildContext context, LoadStatus? mode) {
    Widget textWidget = _buildText(mode);
    Widget iconWidget = _buildIcon(mode);
    List<Widget> children = <Widget>[iconWidget, textWidget];
    final Widget container = Wrap(
      spacing: widget.spacing,
      textDirection: widget.iconPos == IconPosition.left
          ? TextDirection.ltr
          : TextDirection.rtl,
      direction:
          widget.iconPos == IconPosition.bottom ||
              widget.iconPos == IconPosition.top
          ? Axis.vertical
          : Axis.horizontal,
      crossAxisAlignment: WrapCrossAlignment.center,
      verticalDirection: widget.iconPos == IconPosition.bottom
          ? VerticalDirection.up
          : VerticalDirection.down,
      alignment: WrapAlignment.center,
      children: children,
    );
    return widget.outerBuilder != null
        ? widget.outerBuilder!(container)
        : SizedBox(
            height: widget.height,
            child: Center(child: container),
          );
  }
}

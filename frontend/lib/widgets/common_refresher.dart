
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../extensions/widget_extension.dart';
/**
 * Created on 2026/2/7
 * Description:
 */

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

  final TextStyle textStyle;

  final Duration completeDuration;

  const CustomClassicFooter({
    super.key,
    super.onClick,
    super.loadStyle,
    super.height,
    this.outerBuilder,
    this.textStyle = const TextStyle(color: Colors.grey),
    this.loadingText,
    this.noDataText,
    this.noMoreIcon,
    this.idleText,
    this.failedText,
    this.canLoadingText,
    this.failedIcon = const Icon(Icons.error, color: Colors.grey),
    this.iconPos = IconPosition.left,
    this.spacing = 15.0,
    this.completeDuration = const Duration(milliseconds: 300),
    this.loadingIcon,
    this.canLoadingIcon = const Icon(Icons.autorenew, color: Colors.grey),
    this.idleIcon = const Icon(Icons.arrow_upward, color: Colors.grey),
  });

  @override
  State<StatefulWidget> createState() {
    return _ClassicFooterState();
  }
}

class _ClassicFooterState extends LoadIndicatorState<CustomClassicFooter> {
  Widget _buildText(LoadStatus? mode) {
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
        style: widget.textStyle);
  }

  Widget _buildIcon(LoadStatus? mode) {
    Widget? icon = mode == LoadStatus.loading
        ? widget.loadingIcon ??
        SizedBox(
          width: 25.0,
          height: 25.0,
          child: defaultTargetPlatform == TargetPlatform.iOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(strokeWidth: 2.0),
        )
        : mode == LoadStatus.noMore
        ? widget.noMoreIcon
        : mode == LoadStatus.failed
        ? widget.failedIcon
        : mode == LoadStatus.canLoading
        ? widget.canLoadingIcon
        : widget.idleIcon;
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
      direction: widget.iconPos == IconPosition.bottom ||
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
        : Container(
      height: widget.height,
      child: Center(
        child: container,
      ),
    );
  }
}

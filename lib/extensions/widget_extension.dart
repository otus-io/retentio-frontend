import 'package:flutter/material.dart';

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});

  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void didUpdateWidget(covariant _KeepAliveWrapper oldWidget) {
    if (oldWidget.keepAlive != widget.keepAlive) {
      // keepAlive 状态需要更新，实现在 AutomaticKeepAliveClientMixin 中
      updateKeepAlive();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get wantKeepAlive => true;
}

extension WidgetKeepAlive on Widget {
  Widget get keepAlive {
    return _KeepAliveWrapper(child: this);
  }
}

extension WidgetExpanded on Widget {
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  Widget flexible({Key? key, FlexFit fit = FlexFit.loose, int flex = 1}) {
    return Flexible(key: key, flex: flex, fit: fit, child: this);
  }

  Widget fittedBox({
    Key? key,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    Clip clipBehavior = Clip.none,
  }) {
    return FittedBox(
      key: key,
      alignment: alignment,
      clipBehavior: clipBehavior,
      fit: fit,
      child: this,
    );
  }
}

extension WidgetClip on Widget {
  Widget oval({
    Key? key,
    CustomClipper<Rect>? clipper,
    Clip clipBehavior = Clip.antiAlias,
  }) => ClipOval(
    key: key,
    clipper: clipper,
    clipBehavior: clipBehavior,
    child: this,
  );
}

extension WidgetCenter on Widget {
  Widget get center => Center(child: this);
}

extension WidgetWithColum on Widget {
  Widget colum({Widget? child}) {
    return child == null
        ? this
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [this, child],
          );
  }
}

extension SafeAreaWrapper on Widget {
  Widget safeArea({
    Key? key,
    bool left = true,
    bool top = true,
    bool right = true,
    bool bottom = true,
    EdgeInsets minimum = EdgeInsets.zero,
    bool maintainBottomViewPadding = false,
  }) => SafeArea(
    key: key,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    minimum: minimum,
    maintainBottomViewPadding: maintainBottomViewPadding,
    child: this,
  );
}

extension CusBadge on Widget {
  Widget badgeWith(
    int count, {
    int maxCount = 99,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? textColor,
  }) {
    if (count <= 0) return this;
    return Badge(
      label: Text(count > maxCount ? '$maxCount+' : '$count'),
      textStyle: textStyle,
      textColor: textColor,
      backgroundColor: backgroundColor,
      child: this,
    );
  }
}

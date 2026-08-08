import 'package:flutter/material.dart';
import 'package:retentio/widgets/dismiss_keyboard_on_tap.dart';

const double _kSheetTopRadius = 20;
const double _kSheetHandleWidth = 40;
const double _kSheetHandleHeight = 4;
const double _kSheetHandleRadius = 2;
const double _kSheetHorizontalPadding = 20;
const double _kSheetTopPadding = 16;
const double _kSheetBottomPadding = 20;
const double _kSheetHandleBottomMargin = 20;
const double _kSheetTitleGapFullScreen = 28;
const double _kSheetTitleGapDraggable = 48;
const double _kSheetHandleOpacity = 0.6;
const double _kSheetFullScreenMinChildSize = 0.35;
const double _kSheetBarrierOpacity = 0.44;

Future<T?> showCommonBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
  String? title,
  double initialChildSize = 0.6,
  double minChildSize = 0.5,
  double maxChildSize = 0.8,

  /// Fills the viewport (create/edit deck, long forms). User can drag down to [minChildSize].
  bool fullScreen = false,

  /// When true, the sheet sizes to fill its parent; use with tall [initialChildSize] / [fullScreen].
  bool expandSheet = false,
}) {
  final resolvedInitial = fullScreen ? 1.0 : initialChildSize;
  final resolvedMax = fullScreen ? 1.0 : maxChildSize;
  final resolvedMin = fullScreen ? _kSheetFullScreenMinChildSize : minChildSize;
  final resolvedExpand = fullScreen || expandSheet;
  final resolvedUseSafeArea = fullScreen || useSafeArea;
  final resolvedSheetAnimationStyle = sheetAnimationStyle;

  return showModalBottomSheet<T>(
    context: context,
    builder: (context) {
      final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final titleStyle = theme.textTheme.titleLarge;
      final handleColor = scheme.outline.withValues(
        alpha: _kSheetHandleOpacity,
      );
      // For full-screen usage (e.g. create/edit deck), avoid DraggableScrollableSheet.
      // Using a plain scroll view prevents the "double sheet" effect when dragging down.
      final Widget sheet;
      if (fullScreen) {
        sheet = ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_kSheetTopRadius),
          ),
          child: Material(
            color: scheme.surface,
            child: RepaintBoundary(
              child: DismissKeyboardOnTap(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: _kSheetHorizontalPadding,
                    top: _kSheetTopPadding,
                    right: _kSheetHorizontalPadding,
                    bottom: _kSheetBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Center(
                        child: Container(
                          width: _kSheetHandleWidth,
                          height: _kSheetHandleHeight,
                          margin: const EdgeInsets.only(
                            bottom: _kSheetHandleBottomMargin,
                          ),
                          decoration: BoxDecoration(
                            color: handleColor,
                            borderRadius: BorderRadius.circular(
                              _kSheetHandleRadius,
                            ),
                          ),
                        ),
                      ),
                      if (title != null && title.isNotEmpty)
                        Text(title, style: titleStyle),
                      const SizedBox(height: _kSheetTitleGapFullScreen),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        sheet = DraggableScrollableSheet(
          initialChildSize: resolvedInitial,
          minChildSize: resolvedMin,
          maxChildSize: resolvedMax,
          expand: resolvedExpand,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_kSheetTopRadius),
              ),
              child: Material(
                color: scheme.surface,
                child: RepaintBoundary(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: DismissKeyboardOnTap(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: _kSheetHorizontalPadding,
                            top: _kSheetTopPadding,
                            right: _kSheetHorizontalPadding,
                            bottom: _kSheetBottomPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Drag indicator.
                              Center(
                                child: Container(
                                  width: _kSheetHandleWidth,
                                  height: _kSheetHandleHeight,
                                  margin: const EdgeInsets.only(
                                    bottom: _kSheetHandleBottomMargin,
                                  ),
                                  decoration: BoxDecoration(
                                    color: handleColor,
                                    borderRadius: BorderRadius.circular(
                                      _kSheetHandleRadius,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  title ?? '',
                                  textAlign: TextAlign.center,
                                  style: titleStyle,
                                ),
                              ),
                              const SizedBox(height: _kSheetTitleGapDraggable),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: sheet,
      );
    },

    backgroundColor: backgroundColor,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(_kSheetTopRadius),
      ),
    ),
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor:
        barrierColor ??
        Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: _kSheetBarrierOpacity),
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: resolvedUseSafeArea,
    transitionAnimationController: transitionAnimationController,
    sheetAnimationStyle: resolvedSheetAnimationStyle,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
  );
}

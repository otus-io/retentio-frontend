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
const double _kSheetTitleGapCompact = 20;
const double _kSheetHandleOpacity = 0.6;
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

  /// Short forms (e.g. create tag): size to content and lift above the keyboard
  /// so actions like Cancel stay visible without using [DraggableScrollableSheet].
  bool liftWithKeyboard = false,
}) {
  final resolvedInitial = fullScreen ? 1.0 : initialChildSize;
  final resolvedMax = fullScreen ? 1.0 : maxChildSize;
  final resolvedMin = fullScreen ? 1.0 : minChildSize;
  final resolvedExpand = fullScreen || expandSheet;
  // Full-screen sheets paint edge-to-edge; SafeArea is applied inside the
  // surface so the home-indicator region is not left as blank barrier.
  final resolvedUseSafeArea = fullScreen ? false : useSafeArea;
  final resolvedEnableDrag = fullScreen ? false : enableDrag;
  final resolvedShowHandle = showDragHandle ?? resolvedEnableDrag;
  final resolvedSheetAnimationStyle = sheetAnimationStyle;
  final resolvedBackgroundColor = liftWithKeyboard
      ? (backgroundColor ?? Colors.transparent)
      : fullScreen
      ? (backgroundColor ?? Theme.of(context).colorScheme.surface)
      : backgroundColor;

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
      final handle = Center(
        child: Container(
          key: const Key('sheet_drag_handle'),
          width: _kSheetHandleWidth,
          height: _kSheetHandleHeight,
          margin: const EdgeInsets.only(bottom: _kSheetHandleBottomMargin),
          decoration: BoxDecoration(
            color: handleColor,
            borderRadius: BorderRadius.circular(_kSheetHandleRadius),
          ),
        ),
      );
      // Outer inset lifts the sheet above the keyboard without shrinking a
      // DraggableScrollableSheet (these paths have none).
      if (fullScreen) {
        return _fullScreenSheetLayout(
          context: context,
          keyboardBottom: keyboardBottom,
          scheme: scheme,
          titleStyle: titleStyle,
          handle: handle,
          resolvedShowHandle: resolvedShowHandle,
          title: title,
          child: child,
        );
      }

      // Short forms (create tag): content-sized sheet that lifts with keyboard
      // so Save/Cancel stay visible above the keys.
      if (liftWithKeyboard) {
        return _liftWithKeyboardSheetLayout(
          context: context,
          keyboardBottom: keyboardBottom,
          scheme: scheme,
          titleStyle: titleStyle,
          handle: handle,
          resolvedShowHandle: resolvedShowHandle,
          title: title,
          isDismissible: isDismissible,
          child: child,
        );
      }

      // Avoid shrinking DraggableScrollableSheet when the keyboard opens (iOS):
      // that combination can pop the modal. Apply inset as scroll padding so
      // content can scroll above the keys without changing sheet maxHeight.
      return _draggableSheetLayout(
        keyboardBottom: keyboardBottom,
        scheme: scheme,
        titleStyle: titleStyle,
        handle: handle,
        resolvedShowHandle: resolvedShowHandle,
        title: title,
        resolvedInitial: resolvedInitial,
        resolvedMin: resolvedMin,
        resolvedMax: resolvedMax,
        resolvedExpand: resolvedExpand,
        child: child,
      );
    },

    // Compact lift sheets size to content; keep the modal chrome transparent so
    // the dimmed barrier shows above the card (not a full-height white panel).
    backgroundColor: resolvedBackgroundColor,
    barrierLabel: barrierLabel,
    elevation: liftWithKeyboard ? 0 : elevation,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(_kSheetTopRadius),
      ),
    ),
    clipBehavior: liftWithKeyboard ? Clip.none : clipBehavior,
    constraints: constraints,
    barrierColor:
        barrierColor ??
        Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: _kSheetBarrierOpacity),
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: resolvedEnableDrag,
    useSafeArea: resolvedUseSafeArea,
    transitionAnimationController: transitionAnimationController,
    sheetAnimationStyle: resolvedSheetAnimationStyle,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
  );
}

Widget _fullScreenSheetLayout({
  required BuildContext context,
  required double keyboardBottom,
  required ColorScheme scheme,
  required TextStyle? titleStyle,
  required Widget handle,
  required bool resolvedShowHandle,
  required String? title,
  required Widget child,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final sheetHeight = (screenHeight - keyboardBottom).clamp(0.0, screenHeight);
  return Padding(
    padding: EdgeInsets.only(bottom: keyboardBottom),
    child: SizedBox(
      height: sheetHeight,
      width: MediaQuery.sizeOf(context).width,
      child: Material(
        color: scheme.surface,
        child: SafeArea(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resolvedShowHandle) handle,
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
    ),
  );
}

Widget _liftWithKeyboardSheetLayout({
  required BuildContext context,
  required double keyboardBottom,
  required ColorScheme scheme,
  required TextStyle? titleStyle,
  required Widget handle,
  required bool resolvedShowHandle,
  required String? title,
  required bool isDismissible,
  required Widget child,
}) {
  // Modal route uses an opaque hit target for the full viewport, so taps
  // on the dimmed area never reach the barrier — dismiss explicitly.
  return Padding(
    padding: EdgeInsets.only(bottom: keyboardBottom),
    child: Stack(
      children: [
        if (isDismissible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: scheme.surface,
            elevation: 6,
            shadowColor: scheme.shadow,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_kSheetTopRadius),
              ),
            ),
            clipBehavior: Clip.antiAlias,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (resolvedShowHandle) handle,
                      if (title != null && title.isNotEmpty)
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                      const SizedBox(height: _kSheetTitleGapCompact),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _draggableSheetLayout({
  required double keyboardBottom,
  required ColorScheme scheme,
  required TextStyle? titleStyle,
  required Widget handle,
  required bool resolvedShowHandle,
  required String? title,
  required double resolvedInitial,
  required double resolvedMin,
  required double resolvedMax,
  required bool resolvedExpand,
  required Widget child,
}) {
  return DraggableScrollableSheet(
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
                    padding: EdgeInsets.only(
                      left: _kSheetHorizontalPadding,
                      top: _kSheetTopPadding,
                      right: _kSheetHorizontalPadding,
                      bottom: _kSheetBottomPadding + keyboardBottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Drag indicator.
                        if (resolvedShowHandle) handle,
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

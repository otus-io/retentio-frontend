import 'package:flutter/material.dart';

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
  final resolvedMin = fullScreen ? 0.35 : minChildSize;
  final resolvedExpand = fullScreen || expandSheet;
  final resolvedUseSafeArea = fullScreen || useSafeArea;

  return showModalBottomSheet<T>(
    context: context,
    builder: (context) {
      // For full-screen usage (e.g. create/edit deck), avoid DraggableScrollableSheet.
      // Using a plain scroll view prevents the "double sheet" effect when dragging down.
      if (fullScreen) {
        final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                top: 16,
                right: 20,
                bottom: 20 + keyboardBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      title ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        );
      }

      return DraggableScrollableSheet(
        initialChildSize: resolvedInitial,
        minChildSize: resolvedMin,
        maxChildSize: resolvedMax,
        expand: resolvedExpand,
        builder: (context, scrollController) {
          // Avoid shrinking the sheet when the keyboard opens (iOS device): that
          // combination with DraggableScrollableSheet can pop the modal. Inset
          // is applied as padding so the scroll view can still scroll above keys.
          final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      top: 16,
                      right: 20,
                      bottom: 20 + keyboardBottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Drag indicator.
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            title ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },

    backgroundColor: backgroundColor,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: resolvedUseSafeArea,
  );
}

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Dismisses the keyboard when the user taps non-editable blank space.
///
/// Uses a [Listener] (not a competing [GestureDetector]) so the first tap on a
/// text field can take focus. A parent [GestureDetector.onTap] participates in
/// the gesture arena and often steals that first tap.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  static bool pointerHitsEditable(Offset globalPosition, int viewId) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);
    for (final entry in result.path) {
      if (entry.target is RenderEditable) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final before = FocusManager.instance.primaryFocus;
        // Nothing focused yet — let this tap focus a field if it hit one.
        if (before == null) return;

        final viewId = View.of(context).viewId;
        final position = event.position;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final after = FocusManager.instance.primaryFocus;
          if (after == null) return;
          // Focus moved (e.g. another field) — keep the new focus.
          if (!identical(after, before)) return;
          // Same focus: keep caret/selection taps on the editable itself.
          if (pointerHitsEditable(position, viewId)) return;
          after.unfocus();
        });
      },
      child: child,
    );
  }
}

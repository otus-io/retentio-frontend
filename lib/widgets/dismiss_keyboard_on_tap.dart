import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Dismisses the keyboard when the user taps non-editable blank space.
///
/// Uses a [Listener] (not a competing [GestureDetector]) so the first tap on a
/// text field can take focus. A parent [GestureDetector.onTap] participates in
/// the gesture arena and often steals that first tap.
///
/// Only a tap dismisses: a pointer that moves past [kTouchSlop] (scroll/drag)
/// or is cancelled leaves focus alone.
class DismissKeyboardOnTap extends StatefulWidget {
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
  State<DismissKeyboardOnTap> createState() => _DismissKeyboardOnTapState();
}

class _DismissKeyboardOnTapState extends State<DismissKeyboardOnTap> {
  int? _pointer;
  Offset? _downPosition;
  FocusNode? _focusAtDown;

  void _reset() {
    _pointer = null;
    _downPosition = null;
    _focusAtDown = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointer = event.pointer;
    _downPosition = event.position;
    // Null when nothing is focused — then the tap just focuses a field, if any.
    _focusAtDown = FocusManager.instance.primaryFocus;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final down = _downPosition;
    if (event.pointer != _pointer || down == null) return;
    if ((event.position - down).distance > kTouchSlop) _reset();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _reset();
  }

  void _onPointerUp(PointerUpEvent event) {
    // Up events are routed to the hit path cached at pointer-down, so they
    // can arrive after this widget was disposed mid-gesture.
    if (!mounted) return;
    final before = _focusAtDown;
    if (event.pointer != _pointer || before == null) return;
    _reset();

    final viewId = View.of(context).viewId;
    final position = event.position;
    // Focus from the tap settles after the gesture arena resolves, so check on
    // the next frame — and make sure one is scheduled.
    SchedulerBinding.instance.ensureVisualUpdate();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final after = FocusManager.instance.primaryFocus;
      if (after == null) return;
      // Focus moved (e.g. another field) — keep the new focus.
      if (!identical(after, before)) return;
      // Same focus: keep caret/selection taps on the editable itself.
      if (DismissKeyboardOnTap.pointerHitsEditable(position, viewId)) return;
      after.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerCancel: _onPointerCancel,
      onPointerUp: _onPointerUp,
      child: widget.child,
    );
  }
}

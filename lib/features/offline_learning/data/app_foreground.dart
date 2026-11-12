import 'package:flutter/widgets.dart';

/// True while the app is resumed. Screen off and other background states are
/// false, so an in-flight download can tell a pause from a real failure.
class AppForeground extends ValueNotifier<bool> with WidgetsBindingObserver {
  AppForeground() : super(_isResumed(WidgetsBinding.instance.lifecycleState)) {
    WidgetsBinding.instance.addObserver(this);
  }

  static bool _isResumed(AppLifecycleState? state) =>
      state == null || state == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    value = _isResumed(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

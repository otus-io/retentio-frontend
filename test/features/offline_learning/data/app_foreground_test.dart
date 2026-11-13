import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/data/app_foreground.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  test('is false while the app is not resumed', () {
    final foreground = AppForeground();
    addTearDown(foreground.dispose);
    expect(foreground.value, isTrue);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
      expect(foreground.value, isFalse);
    }
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(foreground.value, isTrue);
  });

  test('starts false when created in the background', () {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final foreground = AppForeground();
    addTearDown(foreground.dispose);
    expect(foreground.value, isFalse);
  });

  test('stops listening once disposed', () {
    AppForeground().dispose();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  });
}

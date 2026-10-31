import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/presentation/offline_study_lifecycle.dart';
import 'package:retentio/main.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/providers/main_tab_provider.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/in_memory_hydrated_storage.dart';
import 'helpers/test_wrapper.dart';

class _Auth extends AuthNotifier {
  _Auth(this.loggedIn);

  final bool loggedIn;

  @override
  bool build() => loggedIn;
}

void main() {
  setUp(() async {
    await setupTestEnvironment();
    HydratedStorage.instance = InMemoryHydratedStorage();
  });

  tearDown(() {
    HydratedStorage.instance = null;
    tearDownTestEnvironment();
  });

  for (final loggedIn in [true, false]) {
    testWidgets('offline sync runs only when logged in ($loggedIn)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const MainTabScreen(),
          overrides: [isLoginProvider.overrideWith(() => _Auth(loggedIn))],
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(OfflineStudyLifecycle),
        loggedIn ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('rebuilds survive an offline session that fails to open', (
    tester,
  ) async {
    // Secure storage has no test plugin, so opening the session throws.
    SharedPreferences.setMockInitialValues({'username': 'u1'});
    const connectivity = MethodChannel(
      'dev.fluttercommunity.plus/connectivity_status',
    );
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(connectivity, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(connectivity, null));
    await tester.pumpWidget(
      buildTestableWidgetWithOverrides(
        const MainTabScreen(),
        overrides: [isLoginProvider.overrideWith(() => _Auth(true))],
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    ProviderScope.containerOf(
      tester.element(find.byType(MainTabScreen)),
    ).read(selectedTabIndexProvider.notifier).setIndex(1);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OfflineStudyLifecycle), findsOneWidget);
  });
}

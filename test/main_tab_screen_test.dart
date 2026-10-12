import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/presentation/offline_study_lifecycle.dart';
import 'package:retentio/main.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';

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
}

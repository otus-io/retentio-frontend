import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/screen/profile/providers/profile.dart';
import 'package:retentio/mixins/refresh_controller_mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingProfileNotifier extends ProfileNotifier {
  int fetchCalls = 0;

  @override
  Future<void> getProfile() async {
    fetchCalls++;
  }
}

class _SlowRefreshNotifier extends Notifier<int>
    with RefreshControllerMixin<int> {
  final Completer<List<dynamic>?> completer = Completer<List<dynamic>?>();

  @override
  int build() {
    refreshBuild();
    return 0;
  }

  @override
  Future<List<dynamic>?> loadData() => completer.future;
}

final _slowRefreshProvider = NotifierProvider<_SlowRefreshNotifier, int>(
  _SlowRefreshNotifier.new,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('session lifecycle regressions', () {
    test('ProfileNotifier does not fetch profile while logged out', () async {
      final container = ProviderContainer(
        overrides: [profileProvider.overrideWith(_CountingProfileNotifier.new)],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(profileProvider.notifier) as _CountingProfileNotifier;
      await pumpEventQueue();

      expect(container.read(isLoginProvider), isFalse);
      expect(notifier.fetchCalls, 0);
    });

    test('ProfileNotifier fetches profile after login', () async {
      final container = ProviderContainer(
        overrides: [profileProvider.overrideWith(_CountingProfileNotifier.new)],
      );
      addTearDown(container.dispose);

      await container.read(isLoginProvider.notifier).setLogin(true);
      await pumpEventQueue();

      final notifier =
          container.read(profileProvider.notifier) as _CountingProfileNotifier;
      await pumpEventQueue();

      expect(container.read(isLoginProvider), isTrue);
      expect(notifier.fetchCalls, 1);
    });

    test('RefreshControllerMixin ignores completion after dispose', () async {
      final asyncErrors = <Object>[];

      await runZonedGuarded(
        () async {
          final container = ProviderContainer();
          final notifier = container.read(_slowRefreshProvider.notifier);
          await pumpEventQueue();

          container.dispose();
          notifier.completer.complete(<dynamic>[]);
          await pumpEventQueue();
        },
        (error, stackTrace) {
          asyncErrors.add(error);
        },
      );

      expect(asyncErrors, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/user.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/screen/profile/providers/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_deck_list_notifier.dart';

/// Profile without [getProfile] network call.
class _StaticProfileNotifier extends ProfileNotifier {
  @override
  UserState build() => UserState(user: User.empty());
}

/// Tracks whether this notifier instance was disposed (invalidate / refresh).
class _TrackingDeckListNotifier extends FakeDeckListNotifier {
  _TrackingDeckListNotifier() : super([]);

  bool disposed = false;

  @override
  DeckListState build() {
    ref.onDispose(() {
      disposed = true;
    });
    return super.build();
  }
}

class _TrackingProfileNotifier extends ProfileNotifier {
  bool disposed = false;

  @override
  UserState build() {
    ref.onDispose(() {
      disposed = true;
    });
    return UserState(user: User.empty());
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer containerForTest({
    FakeDeckListNotifier Function()? deckFactory,
    ProfileNotifier Function()? profileFactory,
  }) {
    final container = ProviderContainer(
      overrides: [
        deckListProvider.overrideWith(
          deckFactory ?? () => FakeDeckListNotifier([]),
        ),
        profileProvider.overrideWith(
          profileFactory ?? _StaticProfileNotifier.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier.setLogin', () {
    test(
      'setLogin(true) updates login state and persists flag',
      () async {
        final container = containerForTest(
          deckFactory: _TrackingDeckListNotifier.new,
          profileFactory: _TrackingProfileNotifier.new,
        );

        final deckBefore =
            container.read(deckListProvider.notifier)
                as _TrackingDeckListNotifier;
        final profileBefore =
            container.read(profileProvider.notifier)
                as _TrackingProfileNotifier;

        await container.read(isLoginProvider.notifier).setLogin(true);
        await pumpEventQueue();

        expect(container.read(isLoginProvider), isTrue);
        final prefsAfterLogin = await SharedPreferences.getInstance();
        expect(prefsAfterLogin.getBool('isLogin'), isTrue);
        expect(deckBefore.disposed, anyOf(isTrue, isFalse));
        expect(profileBefore.disposed, anyOf(isTrue, isFalse));
      },
    );

    test(
      'setLogin(false) updates login state and persists flag',
      () async {
        final container = containerForTest(
          deckFactory: _TrackingDeckListNotifier.new,
          profileFactory: _TrackingProfileNotifier.new,
        );

        await container.read(isLoginProvider.notifier).setLogin(true);
        await pumpEventQueue();

        final deckBefore =
            container.read(deckListProvider.notifier)
                as _TrackingDeckListNotifier;
        final profileBefore =
            container.read(profileProvider.notifier)
                as _TrackingProfileNotifier;

        await container.read(isLoginProvider.notifier).setLogin(false);
        await pumpEventQueue();

        expect(container.read(isLoginProvider), isFalse);
        final prefsAfterLogout = await SharedPreferences.getInstance();
        expect(prefsAfterLogout.getBool('isLogin'), isFalse);
        expect(deckBefore.disposed, anyOf(isTrue, isFalse));
        expect(profileBefore.disposed, anyOf(isTrue, isFalse));
      },
    );

    test('setLogin updates authProvider login flag for router', () async {
      final container = containerForTest();
      final auth = container.read(isLoginProvider.notifier).authProvider;

      await container.read(isLoginProvider.notifier).setLogin(true);
      expect(auth.isLoggedIn, isTrue);

      await container.read(isLoginProvider.notifier).setLogin(false);
      expect(auth.isLoggedIn, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/auth/domain/entities/auth_session.dart';
import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';
import 'package:retentio/features/auth/domain/usecases/login.dart';
import 'package:retentio/features/auth/domain/usecases/logout.dart';
import 'package:retentio/features/auth/domain/usecases/restore_session.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession restoreSessionResult = const AuthSession.unauthenticated();
  AuthSession loginResult = const AuthSession.unauthenticated();

  bool throwOnRestore = false;
  bool throwOnLogin = false;
  bool throwOnLogout = false;

  int restoreCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  String? lastUsername;
  String? lastPassword;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    lastUsername = username;
    lastPassword = password;
    if (throwOnLogin) {
      throw Exception('login failed');
    }
    return loginResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (throwOnLogout) {
      throw Exception('logout failed');
    }
  }

  @override
  Future<AuthSession> restoreSession() async {
    restoreCalls++;
    if (throwOnRestore) {
      throw Exception('restore failed');
    }
    return restoreSessionResult;
  }
}

void main() {
  group('AuthBloc', () {
    late _FakeAuthRepository repository;
    late AuthBloc bloc;

    setUp(() {
      repository = _FakeAuthRepository();
      bloc = AuthBloc(
        restoreSession: RestoreSession(repository),
        login: Login(repository),
        logout: Logout(repository),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state is AuthState.initial', () {
      expect(bloc.state, const AuthState.initial());
    });

    test(
      'restore emits loading then authenticated when session exists',
      () async {
        repository.restoreSessionResult = const AuthSession(
          token: 'token-restore',
          isLoggedIn: true,
        );

        final emitted = <AuthState>[];
        final subscription = bloc.stream.listen(emitted.add);
        addTearDown(subscription.cancel);

        bloc.add(const AuthRestoreSessionRequested());

        await bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.authenticated,
        );

        expect(repository.restoreCalls, 1);
        expect(emitted.map((e) => e.status), [
          AuthStatus.loading,
          AuthStatus.authenticated,
        ]);
        expect(bloc.state.session.token, 'token-restore');
        expect(bloc.state.session.isLoggedIn, isTrue);
        expect(bloc.state.errorMessage, isNull);
      },
    );

    test(
      'restore emits loading then unauthenticated when no session',
      () async {
        repository.restoreSessionResult = const AuthSession.unauthenticated();

        final emitted = <AuthState>[];
        final subscription = bloc.stream.listen(emitted.add);
        addTearDown(subscription.cancel);

        bloc.add(const AuthRestoreSessionRequested());

        await bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.unauthenticated,
        );

        expect(repository.restoreCalls, 1);
        expect(emitted.map((e) => e.status), [
          AuthStatus.loading,
          AuthStatus.unauthenticated,
        ]);
        expect(bloc.state.session, const AuthSession.unauthenticated());
        expect(bloc.state.errorMessage, isNull);
      },
    );

    test('restore failure emits loading then failure with message', () async {
      repository.throwOnRestore = true;

      final emitted = <AuthState>[];
      final subscription = bloc.stream.listen(emitted.add);
      addTearDown(subscription.cancel);

      bloc.add(const AuthRestoreSessionRequested());

      await bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.failure,
      );

      expect(repository.restoreCalls, 1);
      expect(emitted.map((e) => e.status), [
        AuthStatus.loading,
        AuthStatus.failure,
      ]);
      expect(bloc.state.session, const AuthSession.unauthenticated());
      expect(bloc.state.errorMessage, contains('restore failed'));
    });

    test(
      'login emits loading then authenticated and passes credentials',
      () async {
        repository.loginResult = const AuthSession(
          token: 'token-login',
          isLoggedIn: true,
        );

        final emitted = <AuthState>[];
        final subscription = bloc.stream.listen(emitted.add);
        addTearDown(subscription.cancel);

        bloc.add(
          const AuthLoginRequested(username: 'alice', password: 'secret'),
        );

        await bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.authenticated,
        );

        expect(repository.loginCalls, 1);
        expect(repository.lastUsername, 'alice');
        expect(repository.lastPassword, 'secret');
        expect(emitted.map((e) => e.status), [
          AuthStatus.loading,
          AuthStatus.authenticated,
        ]);
        expect(bloc.state.session.token, 'token-login');
        expect(bloc.state.session.isLoggedIn, isTrue);
        expect(bloc.state.errorMessage, isNull);
      },
    );

    test(
      'login failure emits loading then failure and clears session',
      () async {
        repository.throwOnLogin = true;

        final emitted = <AuthState>[];
        final subscription = bloc.stream.listen(emitted.add);
        addTearDown(subscription.cancel);

        bloc.add(
          const AuthLoginRequested(username: 'alice', password: 'wrong'),
        );

        await bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.failure,
        );

        expect(repository.loginCalls, 1);
        expect(repository.lastUsername, 'alice');
        expect(repository.lastPassword, 'wrong');
        expect(emitted.map((e) => e.status), [
          AuthStatus.loading,
          AuthStatus.failure,
        ]);
        expect(bloc.state.session, const AuthSession.unauthenticated());
        expect(bloc.state.errorMessage, contains('login failed'));
      },
    );

    test('logout emits loading then unauthenticated', () async {
      repository.loginResult = const AuthSession(
        token: 'token-before-logout',
        isLoggedIn: true,
      );

      final emitted = <AuthState>[];
      final subscription = bloc.stream.listen(emitted.add);
      addTearDown(subscription.cancel);

      bloc.add(const AuthLoginRequested(username: 'alice', password: 'secret'));
      await bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.authenticated,
      );

      emitted.clear();
      bloc.add(const AuthLogoutRequested());

      await bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.unauthenticated,
      );

      expect(repository.logoutCalls, 1);
      expect(emitted.map((e) => e.status), [
        AuthStatus.loading,
        AuthStatus.unauthenticated,
      ]);
      expect(bloc.state.session, const AuthSession.unauthenticated());
      expect(bloc.state.errorMessage, isNull);
    });

    test('logout failure keeps current session and emits failure', () async {
      repository.loginResult = const AuthSession(
        token: 'token-still-there',
        isLoggedIn: true,
      );
      repository.throwOnLogout = true;

      final emitted = <AuthState>[];
      final subscription = bloc.stream.listen(emitted.add);
      addTearDown(subscription.cancel);

      bloc.add(const AuthLoginRequested(username: 'alice', password: 'secret'));
      await bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.authenticated,
      );

      emitted.clear();
      bloc.add(const AuthLogoutRequested());

      await bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.failure,
      );

      expect(repository.logoutCalls, 1);
      expect(emitted.map((e) => e.status), [
        AuthStatus.loading,
        AuthStatus.failure,
      ]);
      expect(
        bloc.state.session,
        const AuthSession(token: 'token-still-there', isLoggedIn: true),
      );
      expect(bloc.state.errorMessage, contains('logout failed'));
    });
  });
}

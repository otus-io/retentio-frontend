import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/core/navigation/router_refresh_bridge.dart';
import 'package:retentio/features/auth/domain/entities/auth_session.dart';
import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';
import 'package:retentio/features/auth/domain/usecases/login.dart';
import 'package:retentio/features/auth/domain/usecases/logout.dart';
import 'package:retentio/features/auth/domain/usecases/restore_session.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';
import 'package:retentio/routers/app_pages.dart';
import 'package:retentio/routers/routers.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.restoreResult});

  final AuthSession restoreResult;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return const AuthSession(token: 'login-token', isLoggedIn: true);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> restoreSession() async {
    return restoreResult;
  }
}

GoRoute _studyRouteFromAppPages() {
  final studyRoute = AppPages.routes.configuration.routes
      .whereType<GoRoute>()
      .firstWhere(
        (route) => route.path == AppRoutes.study.path,
        orElse: () =>
            throw StateError('study route not found in AppPages.routes'),
      );
  return studyRoute;
}

Future<AuthBloc> _bootstrapAuthBloc({required bool authenticated}) async {
  final repository = _FakeAuthRepository(
    restoreResult: authenticated
        ? const AuthSession(token: 'restore-token', isLoggedIn: true)
        : const AuthSession.unauthenticated(),
  );

  final bloc = AuthBloc(
    restoreSession: RestoreSession(repository),
    login: Login(repository),
    logout: Logout(repository),
  );

  bloc.add(const AuthRestoreSessionRequested());
  await bloc.stream.firstWhere((state) => state.status != AuthStatus.loading);
  return bloc;
}

GoRouter _buildRouterForTest() {
  return GoRouter(
    initialLocation: AppRoutes.study.path,
    routes: [
      GoRoute(
        path: AppRoutes.login.path,
        builder: (context, state) => const Scaffold(body: Text('Login Screen')),
      ),
      GoRoute(
        path: AppRoutes.main.path,
        builder: (context, state) => const Scaffold(body: Text('Main Screen')),
      ),
      _studyRouteFromAppPages(),
    ],
    redirect: (_, state) {
      final path = AppRoutes.normalizePath(state.uri.path);
      final isAuthExempt = AppRoutes.isAuthExemptPath(path);
      final bridge = sl.isRegistered<RouterRefreshBridge>()
          ? sl<RouterRefreshBridge>()
          : null;
      final authBloc = sl.isRegistered<AuthBloc>() ? sl<AuthBloc>() : null;

      if (bridge == null || authBloc == null) {
        return null;
      }

      final status = authBloc.state.status;
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      final isLoggedIn = bridge.isAuthenticated;
      if (!isLoggedIn && !isAuthExempt) {
        return AppRoutes.login.path;
      }
      if (isLoggedIn && path == AppRoutes.login.path) {
        return AppRoutes.main.path;
      }
      return null;
    },
  );
}

void main() {
  group('/study route extra fallback', () {
    tearDown(() async {
      if (sl.isRegistered<RouterRefreshBridge>()) {
        sl<RouterRefreshBridge>().dispose();
      }
      if (sl.isRegistered<AuthBloc>()) {
        await sl<AuthBloc>().close();
      }
      await sl.reset();
    });

    testWidgets('missing extra shows fallback screen when authenticated', (
      tester,
    ) async {
      final authBloc = await _bootstrapAuthBloc(authenticated: true);
      sl.registerLazySingleton<AuthBloc>(() => authBloc);
      sl.registerLazySingleton<RouterRefreshBridge>(
        () => RouterRefreshBridge(authBloc),
      );

      final router = _buildRouterForTest();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Back to home'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppRoutes.study.path,
      );

      await tester.tap(find.text('Back to home'));
      await tester.pumpAndSettle();

      expect(find.text('Main Screen'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppRoutes.main.path,
      );
    });

    testWidgets('when unauthenticated /study redirects to /login', (
      tester,
    ) async {
      final authBloc = await _bootstrapAuthBloc(authenticated: false);
      sl.registerLazySingleton<AuthBloc>(() => authBloc);
      sl.registerLazySingleton<RouterRefreshBridge>(
        () => RouterRefreshBridge(authBloc),
      );

      final router = _buildRouterForTest();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppRoutes.login.path,
      );
    });
  });
}

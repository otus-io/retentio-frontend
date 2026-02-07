import 'package:flutter/material.dart';
import 'package:wordupx/routers/routers.dart';
import 'package:go_router/go_router.dart';
import 'package:wordupx/screen/login/login_screen.dart';
import 'package:wordupx/screen/register/register_screen.dart';

import '../main.dart';
import '../providers/auth_provider.dart';

/// Created on 2026/2/6
/// Description:
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();
class AppPages {
  AppPages._();

  static const initial = AppRoutes.login;
  static final GoRouter routes = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.main.path,
    routes: [
      GoRoute(
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register.path,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.main.path,
        builder: (context, state) => const MainTabScreen(),

      ),

    ],
    redirect: (context, state) {
      final isLoggedIn = providerContainer.read(isLoginProvider);
      final loggingIn = state.matchedLocation == AppRoutes.login.path;
      if (!isLoggedIn && !loggingIn) return AppRoutes.login.path;
      if (isLoggedIn && loggingIn) {
        return AppRoutes.main.path;
      }
      return null;
    },
    refreshListenable: providerContainer.read(isLoginProvider.notifier).authProvider,
  );
}

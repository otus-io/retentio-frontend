import 'package:wordupx/routers/routers.dart';
import 'package:go_router/go_router.dart';
import 'package:wordupx/screen/login/login_screen.dart';
import 'package:wordupx/screen/register/register_screen.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../screen/deck/deck_learn_screen.dart';
import '../screen/home/home_screen.dart';

/**
 * Created on 2026/2/6
 * Description:
 */
class AppPages {
  AppPages._();

  static const initial = AppRoutes.login;
  static final GoRouter routes = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.main.path,
        builder: (context, state) => const MainTabScreen(),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register.path,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
    redirect: (context,state) {
      final isLoggedIn = providerContainer.read(isLoginProvider);
      final loggingIn = state.matchedLocation == AppRoutes.login.path;
      if(!loggingIn) return AppRoutes.login.path;
      if (isLoggedIn) {
        return AppRoutes.main.path;
      }
      return null;
    },
  );
}

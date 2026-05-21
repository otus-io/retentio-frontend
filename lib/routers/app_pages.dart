import 'package:flutter/material.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/extensions/object_extension.dart';
import 'package:retentio/routers/routers.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/screen/login/login_screen.dart';
import 'package:retentio/screen/register/register_screen.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/core/navigation/router_refresh_bridge.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart'
    as feature_auth;
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';

import '../main.dart';
import '../screen/deck/deck_view_screen.dart';

/// Created on 2026/2/6
/// Description:
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

class AppPages {
  AppPages._();

  static RouterRefreshBridge? get _routerRefreshBridge {
    if (sl.isRegistered<RouterRefreshBridge>()) {
      return sl<RouterRefreshBridge>();
    }
    return null;
  }

  static feature_auth.AuthBloc? get _authBloc {
    if (sl.isRegistered<feature_auth.AuthBloc>()) {
      return sl<feature_auth.AuthBloc>();
    }
    return null;
  }

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
      GoRoute(
        path: AppRoutes.study.path,
        builder: (context, state) {
          final extraMap = state.extra.asMap();
          final deck = extraMap['deck'];
          final deckListCubit = extraMap['deckListCubit'];
          if (deck is! Deck) {
            // Keep route compatible while avoiding crashes when extra is absent.
            return const _MissingStudyExtraScreen();
          }
          if (deckListCubit is DeckListCubit) {
            return BlocProvider<DeckListCubit>.value(
              value: deckListCubit,
              child: DeckViewScreen(deck: deck),
            );
          }
          return DeckViewScreen(deck: deck);
        },
      ),
    ],
    redirect: (context, state) {
      final path = AppRoutes.normalizePath(state.uri.path);
      final isAuthExempt = AppRoutes.isAuthExemptPath(path);
      final bridge = _routerRefreshBridge;
      final authBloc = _authBloc;

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
    refreshListenable: _routerRefreshBridge,
  );
}

class _MissingStudyExtraScreen extends StatelessWidget {
  const _MissingStudyExtraScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go(AppRoutes.main.path),
          child: const Text('Back to home'),
        ),
      ),
    );
  }
}

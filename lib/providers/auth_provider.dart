import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart'
    as feature_auth;
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/screen/profile/providers/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/app_service_locator.dart';

final isLoginProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  static feature_auth.AuthBloc? _authBloc;
  static bool _didRestore = false;
  static SharedPreferences? _prefs;

  StreamSubscription<AuthState>? _subscription;
  final AuthProvider authProvider = AuthProvider();

  @override
  bool build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _initialize();
    final bloc = _authBloc;
    if (bloc == null) {
      return false;
    }
    return bloc.state.status == AuthStatus.authenticated;
  }

  Future<void> _initialize() async {
    final bloc = await _getAuthBlocFromDi();
    if (bloc == null) {
      return;
    }
    _subscription ??= bloc.stream.listen(_onAuthStateChanged);

    if (!_didRestore && bloc.state.status == AuthStatus.initial) {
      _didRestore = true;
      bloc.add(const AuthRestoreSessionRequested());
    }
  }

  Future<feature_auth.AuthBloc?> _getAuthBlocFromDi() async {
    final cached = _authBloc;
    if (cached != null) {
      return cached;
    }

    if (!sl.isRegistered<feature_auth.AuthBloc>()) {
      return null;
    }
    final bloc = sl<feature_auth.AuthBloc>();
    _authBloc = bloc;
    return bloc;
  }

  void _onAuthStateChanged(AuthState authState) {
    final next = authState.status == AuthStatus.authenticated;
    if (state == next) {
      return;
    }
    state = next;
    authProvider.setLoginStatus(next);
    _invalidateSessionScopedProviders();
  }

  void _invalidateSessionScopedProviders() {
    // Ensure previous notifier instances are disposed across session switches.
    ref.invalidate(deckListProvider);
    ref.invalidate(profileProvider);
  }

  Future<void> setLogin(bool value) async {
    final prefs = await _preferences();
    await prefs.setBool('isLogin', value);

    state = value;
    authProvider.setLoginStatus(value);
    _invalidateSessionScopedProviders();

    if (!value) {
      final bloc = await _getAuthBlocFromDi();
      if (bloc == null) {
        return;
      }
      bloc.add(const AuthLogoutRequested());
    }
  }

  void logout() {
    unawaited(setLogin(false));
  }

  static Future<SharedPreferences> _preferences() async {
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void setLoginStatus(bool status) {
    _isLoggedIn = status;
    notifyListeners(); // 通知 GoRouter 刷新状态
  }

  // 401 时调用这个
  void logout() {
    _isLoggedIn = false;
    notifyListeners(); // ★★★ 关键：这一步会触发 GoRouter 的 redirect
  }
}

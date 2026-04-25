import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/screen/profile/providers/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isLoginProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  AuthProvider authProvider = AuthProvider();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isLogin') ?? false;
  }

  Future<void> setLogin(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogin', value);
    authProvider.setLoginStatus(value);
    // Clear session-scoped caches on login (refetch for new user) and logout
    // (deck list is not autoDispose, so it would otherwise keep the prior session).
    ref.invalidate(deckListProvider);
    ref.invalidate(profileProvider);
  }

  void logout() {
    authProvider.logout();
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

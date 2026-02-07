import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isLoginProvider = NotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isLogin') ?? false;
  }

  Future<void> setLogin(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogin', value);
  }


}
class AuthProvider extends ChangeNotifier {
  // 单例，方便在 Dio 中调用
  static final AuthProvider instance = AuthProvider._();
  AuthProvider._();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void setLoginStatus(bool status) {
    _isLoggedIn = status;
    notifyListeners(); // 通知 GoRouter 刷新状态
  }

  // 401 时调用这个
  void logout() {
    _isLoggedIn = false;
    // 清除 SP/Token 等缓存...
    notifyListeners(); // ★★★ 关键：这一步会触发 GoRouter 的 redirect
  }
}
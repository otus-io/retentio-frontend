import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

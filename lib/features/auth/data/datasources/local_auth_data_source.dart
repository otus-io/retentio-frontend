import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthDataSource {
  static const String tokenKey = 'token';
  static const String loginFlagKey = 'isLogin';

  const LocalAuthDataSource();

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<bool> readLoginFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(loginFlagKey) ?? false;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveLoginFlag(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginFlagKey, isLoggedIn);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}

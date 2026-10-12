import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthDataSource {
  static const String tokenKey = 'token';
  static const String loginFlagKey = 'isLogin';

  /// Kept across logout so offline data of the same account can be resumed.
  static const String usernameKey = 'username';

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

  Future<String?> readUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(usernameKey);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usernameKey, username);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}

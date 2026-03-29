// auth_service.dart
import 'package:retentio/main.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/services/index.dart';
import 'api_service.dart';

class AuthService {
  static Future<ApiResponse?> register({
    required String email,
    required String username,
    required String password,
  }) async {
    return ApiService.post(
      Api.register,
      body: {'email': email, 'username': username, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await ApiService.post(
      Api.login,
      body: {'username': username, 'password': password},
    );

    final token = res?.data is Map ? (res!.data as Map)['token'] : null;
    if (token is String && token.isNotEmpty) {
      await ApiService.setToken(token);
      providerContainer.read(isLoginProvider.notifier).setLogin(true);
    }

    final dataMap = res?.data is Map
        ? Map<String, dynamic>.from(res!.data as Map)
        : <String, dynamic>{};
    if (dataMap['token'] == null &&
        res != null &&
        res.msg.isNotEmpty &&
        res.msg != 'Unknown error') {
      dataMap['message'] = res.msg;
    }
    return dataMap;
  }

  /// Logout: invalidates token on server and clears local state.
  static Future<ApiResponse?> logout() async {
    final res = await ApiService.post(Api.logout);
    await ApiService.clearToken();
    providerContainer.read(isLoginProvider.notifier).setLogin(false);
    return res;
  }

  /// Request password reset; server returns reset_token (e.g. for email flow).
  static Future<ApiResponse?> forgotPassword({required String email}) async {
    return ApiService.post(Api.forgotPassword, body: {'email': email});
  }

  /// Reset password using token from forgot-password.
  static Future<ApiResponse?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return ApiService.post(
      Api.resetPassword,
      body: {'token': token, 'new_password': newPassword},
    );
  }
}

// auth_service.dart
import 'package:wordupx/main.dart';
import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/providers/auth_provider.dart';
import 'package:wordupx/services/index.dart';
import 'api_service.dart';

class AuthService {
  /// 注册
  static Future<ResBaseModel?> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final data = await ApiService.post(
      Api.register,
      body: {'email': email, 'username': username, 'password': password},
    );
    return data;
  }

  /// 登录
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await ApiService.post(
      Api.login,
      body: {'username': username, 'password': password},
    );

    // 若返回里有 token，则顺便保存，后续请求会自动带上
    final token = res?.data['token'];

    if (token is String && token.isNotEmpty) {
      ApiService.setToken(token);
      // 登录成功后设置 isLogin 为 true
      providerContainer.read(isLoginProvider.notifier).setLogin(true);
    }

    return res?.data ?? {};
  }

  /// 登出（可选）
  static Future<void> logout() async {
    // 如果有后端登出接口，这里可调用：
    // await ApiService.post('/auth/logout');
    ApiService.clearToken();
    providerContainer.read(isLoginProvider.notifier).setLogin(false);
  }
}

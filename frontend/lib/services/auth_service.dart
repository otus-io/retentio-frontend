// auth_service.dart
import 'package:wordupx/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

// 需要一个全局的 ProviderContainer 实例
final _container = ProviderContainer();

class AuthService {
  /// 注册
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final data = await ApiService.post(
      '/auth/register',
      body: {'email': email, 'username': username, 'password': password},
    );
    return data;
  }

  /// 登录
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final data = await ApiService.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );

    // 若返回里有 token，则顺便保存，后续请求会自动带上
    final token = data['token'];

    if (token is String && token.isNotEmpty) {
      ApiService.setToken(token);
      // 登录成功后设置 isLogin 为 true
      _container.read(isLoginProvider.notifier).setLogin(true);
    }

    return data;
  }

  /// 登出（可选）
  static Future<void> logout() async {
    // 如果有后端登出接口，这里可调用：
    // await ApiService.post('/auth/logout');
    ApiService.clearToken();
    _container.read(isLoginProvider.notifier).setLogin(false);
  }
}

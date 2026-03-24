import 'package:shared_preferences/shared_preferences.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/services/index.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';

class ApiService {
  static String? _token;

  static String get authorization => _token ?? '';

  /// 初始化时加载 token
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  /// 设置 token（登录成功后调用）
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  /// 清除 token（登出时调用）
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// 通用 POST 请求
  static Future<ApiResponse?> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await dioClient.post(endpoint, params: body);

    return response;
  }

  /// 通用 Delete请求
  static Future<ApiResponse?> delete(
    String endpoint, {
    Map<String, String>? pathParams,
  }) {
    return dioClient.delete(endpoint, pathParams: pathParams);
  }

  /// 通用 GET 请求
  static Future<ApiResponse?> get(
    String endpoint, {
    Map<String, String>? pathParams,
  }) async {
    final response = await dioClient.get(endpoint, pathParams: pathParams);
    return response;
  }

  /// 通用 Patch 请求
  static Future<ApiResponse?> patch(
    String endpoint, {
    Map<String, String>? pathParams,
    dynamic params,
  }) {
    return dioClient.patch(endpoint, pathParams: pathParams, params: params);
  }

  /// 构建 headers（自动附加 Authorization）
  static Map<String, dynamic> buildHeaders(Map<String, dynamic>? headers) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return {...defaultHeaders, if (headers != null) ...headers};
  }

  /// 处理 401 未授权，跳转到登录页
  static void handle401Unauthorized() async {
    // 清除 token
    await clearToken();

    // 更新登录状态

    try {
      final authNotifier = providerContainer.read(isLoginProvider.notifier);
      await authNotifier.setLogin(false);
    } catch (e) {
      // 忽略错误
    }
    providerContainer.read(isLoginProvider.notifier);
  }

  static Future<String?> downloadFile(String audioUrl, String path) async {
    return dioClient.downLoadFile(audioUrl, path, (value) {}, () {});
  }
}

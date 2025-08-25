import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ApiService {
  static String? _token;

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
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$kApiBaseUrl$endpoint');
    final mergedHeaders = _buildHeaders(headers);

    final response = await http.post(
      url,
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  /// 通用 GET 请求
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$kApiBaseUrl$endpoint');
    final mergedHeaders = _buildHeaders(headers);

    final response = await http.get(url, headers: mergedHeaders);
    return _handleResponse(response);
  }

  /// 构建 headers（自动附加 Authorization）
  static Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return {...defaultHeaders, if (headers != null) ...headers};
  }

  /// 统一处理响应
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body)['data'] : {};
    } else {
      throw Exception(
        'Request failed [${response.statusCode}]: ${response.body}',
      );
    }
  }
}

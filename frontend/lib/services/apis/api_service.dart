import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/index.dart';
import '../../constants.dart';
import '../../providers/auth_provider.dart';

class ApiService {
  static String? _token;
  static GlobalKey<NavigatorState>? navigatorKey;
  static ProviderContainer? providerContainer;

  /// 设置全局导航键
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// 设置 Provider Container
  static void setProviderContainer(ProviderContainer container) {
    providerContainer = container;
  }

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
  static Future<ResBaseModel?> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {

    final response = await dioClient.post(endpoint, params: body);

    return response;
  }

  /// 通用 GET 请求
  static Future<ResBaseModel?> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {

    final response = await dioClient.get(endpoint,params: params);
    return response;
  }

  /// 构建 headers（自动附加 Authorization）
  static Map<String, String> _buildHeaders(Map<String, String>? headers) {
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
    if (providerContainer != null) {
      try {
        final authNotifier = providerContainer!.read(isLoginProvider.notifier);
        await authNotifier.setLogin(false);
      } catch (e) {
        // 忽略错误
      }
    }

    // 跳转到登录页
    if (navigatorKey?.currentContext != null) {
      final context = navigatorKey!.currentContext!;
      // 清除所有路由并跳转到登录页
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

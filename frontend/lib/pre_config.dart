import 'package:flutter/material.dart' show WidgetsFlutterBinding;
import 'package:wordupx/services/apis/api_service.dart';
import 'package:wordupx/services/index.dart';

import 'main.dart';

/**
 * Created on 2026/2/5
 * Description: 预配置类，用于初始化应用所需的全局配置和服务。
 */
class PreConfig {
  /// 标记是否已完成初始化，避免重复初始化。
  static bool _didInit = false;

  /**
   * 初始化预配置服务。
   *
   * 该方法用于初始化应用的核心服务，包括API服务、网络客户端配置等。
   * 只有在首次调用时才会执行初始化逻辑，后续调用将直接返回。
   *
   * Returns:
   *   Future<void>: 表示初始化完成的异步任务。
   */
  static Future<void> init() async {
    // 检查是否已初始化，避免重复执行
    if (!_didInit) {
      // 初始化API服务
      await ApiService.init();
      ApiService.setNavigatorKey(navigatorKey);
      ApiService.setProviderContainer(providerContainer);

      // 配置网络客户端（Dio）
      DioClient.of.config(
        Env.host,
        interceptors: [
          HttpHeaderInterceptors(),       // HTTP头部拦截器
          ResponseInterceptors(),         // 响应拦截器
          if (!Env.isDistribute) LogInterceptors(), // 日志拦截器（仅在非分发环境下启用）
        ],
        proxyInterceptor: ProxyInterceptor.interceptor, // 代理拦截器
      );

      // 标记初始化完成
      _didInit = true;
      return Future.value();
    }
  }
}


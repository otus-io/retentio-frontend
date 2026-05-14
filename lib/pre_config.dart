import 'package:path_provider/path_provider.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';

/// Created on 2026/2/5
/// Description: 预配置类，用于初始化应用所需的全局配置和服务。
class PreConfig {
  /// 标记是否已完成初始化，避免重复初始化。
  static bool _didInit = false;

  /// 初始化预配置服务。
  ///
  /// 该方法用于初始化应用的核心服务，包括API服务、网络客户端配置等。
  /// 只有在首次调用时才会执行初始化逻辑，后续调用将直接返回。
  ///

  static Future<void> init() async {
    // 检查是否已初始化，避免重复执行
    if (!_didInit) {
      // 获取应用文档目录，用于存储持久化数据
      final appDir = await getApplicationDocumentsDirectory();
      // 构建Hive持久化存储实例，指定存储路径
      final storage = await HiveHydratedStorage.build(
        storageDirectory: appDir.path,
      );
      // 设置全局HydratedStorage实例，供应用其他部分使用
      HydratedStorage.instance = storage;
      // 初始化API服务
      await ApiService.init();

      // 配置网络客户端（Dio）
      networkDioClient.configure(
        baseUrl: Env.host,
        interceptors: [
          HeaderInterceptor(),
          ResponseNormalizeInterceptor(),
          if (!Env.isDistribute) NetworkLoggingInterceptor(),
        ],
        proxyClientFactory: ProxyClientFactory.create,
      );

      // 标记初始化完成
      _didInit = true;
      return Future.value();
    }
  }
}

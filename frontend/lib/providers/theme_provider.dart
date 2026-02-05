import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用主题模式枚举，定义了三种主题模式：系统默认、浅色和深色。
enum AppThemeMode { system, light, dark }

/// 提供一个 `NotifierProvider` 实例，用于管理应用的主题模式状态。
/// 该 Provider 使用 `ThemeModeNotifier` 类来处理主题模式的逻辑。
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

/// 主题模式通知器类，继承自 `Notifier<AppThemeMode>`。
/// 负责加载和保存用户的主题偏好设置，并提供切换主题的方法。
class ThemeModeNotifier extends Notifier<AppThemeMode> {
  /// 构建方法，在初始化时调用 `_load()` 方法从本地存储中读取用户保存的主题模式，
  /// 并返回默认的主题模式（系统默认）。
  @override
  AppThemeMode build() {
    _load();
    return AppThemeMode.system;
  }

  /// 异步加载用户保存的主题模式。
  /// 从 `SharedPreferences` 中获取保存的主题模式字符串，并根据其值更新当前状态。
  /// 如果没有找到对应的值或值无效，则使用系统默认主题。
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('themeMode');
    switch (value) {
      case 'light':
        state = AppThemeMode.light;
        break;
      case 'dark':
        state = AppThemeMode.dark;
        break;
      default:
        state = AppThemeMode.system;
    }
  }

  /// 设置并保存新的主题模式。
  ///
  /// 参数:
  /// - [mode]: 新的主题模式，类型为 `AppThemeMode`。
  ///
  /// 功能:
  /// 1. 更新当前的状态为指定的主题模式。
  /// 2. 将新主题模式保存到 `SharedPreferences` 中，以便下次启动时恢复。
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}

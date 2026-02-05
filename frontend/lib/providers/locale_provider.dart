import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 提供一个用于管理应用本地化设置的状态提供器。
/// 该提供器使用 Riverpod 的 NotifierProvider 来管理 Locale 类型的状态。
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
    LocaleNotifier.new
);

/// 负责管理应用本地化状态的 Notifier 类。
/// 该类继承自 Notifier<Locale>，用于加载和设置应用的语言环境。
class LocaleNotifier extends Notifier<Locale> {

  /// 构建并初始化本地化状态。
  /// 在构建时会调用 [_load] 方法从持久化存储中加载语言代码，
  /// 如果没有找到则默认返回中文（'zh'）作为初始语言环境。
  ///
  /// 返回值：当前的应用语言环境（Locale 对象）。
  @override
  Locale build() {
    _load();
    return  Locale('zh');
  }

  /// 从 SharedPreferences 中异步加载已保存的语言代码。
  /// 如果存在有效的语言代码，则更新当前状态为对应的 Locale。
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('localeCode');
    if (code != null) {
      state = Locale(code);
    }
  }

  /// 设置新的语言环境并将其保存到 SharedPreferences 中。
  ///
  /// 参数：
  /// - [locale]：要设置的新语言环境（Locale 对象）。
  ///
  /// 功能：
  /// 1. 更新当前状态为指定的语言环境；
  /// 2. 将语言代码持久化保存到 SharedPreferences 中。
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localeCode', locale.languageCode);
  }

}

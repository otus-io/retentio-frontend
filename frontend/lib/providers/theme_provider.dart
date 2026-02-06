import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage/hydrated_notifier.dart';

/// 一个用于管理应用主题模式的状态通知器。
///
/// 该类继承自 [HydratedNotifier]，支持持久化存储主题模式状态。
/// 它提供了设置、切换主题模式以及序列化/反序列化功能。
class ThemeModeNotifier extends HydratedNotifier<ThemeMode> {
  /// 构建初始状态。
  ///
  /// 如果存在持久化数据，则从中恢复状态；否则默认使用系统主题模式。
  @override
  ThemeMode build() => hydrate() ?? ThemeMode.system;

  /// 设置当前的主题模式。
  ///
  /// [mode] 指定要设置的主题模式（light、dark 或 system）。
  void setThemeMode(ThemeMode mode) => state = mode;

  /// 切换当前主题模式。
  ///
  /// 根据当前状态在 light、dark 和 system 之间循环切换。
  void toggle() {
    state = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
  }

  /// 将当前状态序列化为 JSON 格式。
  ///
  /// [state] 当前的主题模式状态。
  /// 返回一个包含主题模式索引的 Map，格式为 {'mode': index}。
  @override
  Map<String, dynamic>? toJson(ThemeMode state) => {'mode': state.index};

  /// 从 JSON 数据中反序列化主题模式状态。
  ///
  /// [json] 包含主题模式索引的 Map。
  /// 返回对应的 [ThemeMode] 实例，如果数据无效则返回 null。
  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    final index = json['mode'] as int?;
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return null;
    }
    return ThemeMode.values[index];
  }
}

/// 提供 [ThemeModeNotifier] 的 Riverpod 状态提供者。
///
/// 用于在应用中访问和管理主题模式状态。
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

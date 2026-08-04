import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage/hydrated_notifier.dart';

enum AppThemeMode { light, dark, sepia, system }

class ThemeModeNotifier extends HydratedNotifier<AppThemeMode> {
  @override
  AppThemeMode build() => hydrate() ?? AppThemeMode.dark;

  void setThemeMode(AppThemeMode mode) => state = mode;

  void toggle() {
    state = switch (state) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.sepia,
      AppThemeMode.sepia => AppThemeMode.light,
      AppThemeMode.system => AppThemeMode.dark,
    };
  }

  @override
  Map<String, dynamic>? toJson(AppThemeMode state) => {'mode': state.index};

  @override
  AppThemeMode? fromJson(Map<String, dynamic> json) {
    final index = json['mode'] as int?;
    if (index == null || index < 0 || index >= AppThemeMode.values.length) {
      return null;
    }
    return AppThemeMode.values[index];
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

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
  Map<String, dynamic>? toJson(AppThemeMode state) => {'mode': state.name};

  @override
  AppThemeMode? fromJson(Map<String, dynamic> json) {
    final mode = json['mode'];
    if (mode is String) {
      for (final value in AppThemeMode.values) {
        if (value.name == mode) return value;
      }
      return null;
    }
    // Older builds stored Flutter's ThemeMode index, whose order differs from
    // AppThemeMode. Names are stored instead so reordering stays harmless.
    if (mode is int) {
      const legacy = [
        AppThemeMode.system,
        AppThemeMode.light,
        AppThemeMode.dark,
      ];
      return mode >= 0 && mode < legacy.length ? legacy[mode] : null;
    }
    return null;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

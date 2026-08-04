import 'package:flutter/material.dart';

import 'theme_tokens.dart';

class AppThemeColorScheme {
  AppThemeColorScheme._();

  static ColorScheme sepia() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppThemeTokens.sepiaPrimary,
      brightness: Brightness.light,
    );
    return baseScheme.copyWith(
      primary: AppThemeTokens.sepiaPrimary,
      onPrimary: Colors.white,
      secondary: AppThemeTokens.sepiaSecondary,
      onSecondary: Colors.white,
      tertiary: AppThemeTokens.sepiaTertiary,
      onTertiary: Colors.white,
      surface: AppThemeTokens.sepiaSurface,
      surfaceContainer: const Color(0xFFEDE3CE),
      surfaceContainerHigh: const Color(0xFFF0E8D5),
      surfaceContainerHighest: AppThemeTokens.sepiaSurfaceHigh,
      surfaceBright: const Color(0xFFFFFCF3),
      surfaceDim: const Color(0xFFEADDBE),
      onSurfaceVariant: const Color(0xFF5A4832),
      outline: AppThemeTokens.sepiaOutline,
      outlineVariant: const Color(0xFFDDD0B8),
      onSurface: AppThemeTokens.sepiaOnSurface,
      shadow: const Color(0xFF1A0F00),
    );
  }

  static ColorScheme resolve(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark
          ? AppThemeTokens.darkPrimary
          : AppThemeTokens.lightPrimary,
      brightness: brightness,
    );

    if (isDark) {
      return baseScheme.copyWith(
        primary: AppThemeTokens.darkPrimary,
        onPrimary: const Color(0xFF0A0F2E),
        secondary: AppThemeTokens.darkSecondary,
        onSecondary: const Color(0xFF022B1A),
        tertiary: AppThemeTokens.darkTertiary,
        onTertiary: const Color(0xFF0A1E33),
        surface: AppThemeTokens.darkSurface,
        surfaceContainer: const Color(0xFF191D24),
        surfaceContainerHigh: const Color(0xFF1C2028),
        surfaceContainerHighest: AppThemeTokens.darkSurfaceHigh,
        surfaceBright: const Color(0xFF252B34),
        surfaceDim: const Color(0xFF0D1015),
        onSurfaceVariant: const Color(0xFF9AA0AC),
        outline: AppThemeTokens.darkOutline,
        outlineVariant: const Color(0xFF333844),
        onSurface: AppThemeTokens.darkOnSurface,
        shadow: const Color(0xFF000000),
      );
    }

    return baseScheme.copyWith(
      primary: AppThemeTokens.lightPrimary,
      onPrimary: Colors.white,
      secondary: AppThemeTokens.lightSecondary,
      onSecondary: Colors.white,
      tertiary: AppThemeTokens.lightTertiary,
      onTertiary: Colors.white,
      surface: AppThemeTokens.lightSurface,
      surfaceContainer: const Color(0xFFEEF2FF),
      surfaceContainerHigh: const Color(0xFFF0F4FF),
      surfaceContainerHighest: AppThemeTokens.lightSurfaceHigh,
      surfaceBright: Colors.white,
      surfaceDim: const Color(0xFFE5E9F5),
      onSurfaceVariant: const Color(0xFF4A5568),
      outline: AppThemeTokens.lightOutline,
      outlineVariant: const Color(0xFFDDE1EE),
      onSurface: AppThemeTokens.lightOnSurface,
      shadow: const Color(0xFF0F1729),
    );
  }
}

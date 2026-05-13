import 'package:flutter/material.dart';

import 'theme_tokens.dart';

class AppThemeColorScheme {
  AppThemeColorScheme._();

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
        onTertiary: const Color(0xFF1A1040),
        surface: AppThemeTokens.darkSurface,
        surfaceContainer: const Color(0xFF111827),
        surfaceContainerHigh: const Color(0xFF1A2035),
        surfaceContainerHighest: AppThemeTokens.darkSurfaceHigh,
        surfaceBright: const Color(0xFF2D3748),
        surfaceDim: const Color(0xFF080C14),
        onSurfaceVariant: const Color(0xFF94A3B8),
        outline: AppThemeTokens.darkOutline,
        outlineVariant: const Color(0xFF1E293B),
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

import 'package:flutter/material.dart';

import 'theme_color_scheme.dart';
import 'theme_components.dart';
import 'theme_tokens.dart';
import 'theme_typography.dart';
import 'theme_typography_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = AppThemeColorScheme.resolve(brightness);
    final textTheme = AppThemeTypography.build(brightness);
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        AppTypographySemantic.fromTextTheme(textTheme),
      ],
      scaffoldBackgroundColor: colorScheme.surface,
    );

    return AppThemeComponents.apply(
      base: baseTheme,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
    );
  }

  static List<Color> loginBackground(Brightness brightness) {
    return AppThemeTokens.loginBackground(brightness);
  }
}

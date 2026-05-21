import 'package:flutter/material.dart';

class AppThemeTokens {
  AppThemeTokens._();

  static const Color lightPrimary = Color(0xFF4361EE);
  static const Color lightSecondary = Color(0xFF10B981);
  static const Color lightTertiary = Color(0xFF7C6FF7);
  static const Color lightSurface = Color(0xFFF8F9FB);
  static const Color lightSurfaceHigh = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFC5CAD8);

  static const Color darkPrimary = Color(0xFF7B96F5);
  static const Color darkSecondary = Color(0xFF34D399);
  static const Color darkTertiary = Color(0xFFA78BFA);
  static const Color darkSurface = Color(0xFF0D1117);
  static const Color darkSurfaceHigh = Color(0xFF161B2E);
  static const Color darkOutline = Color(0xFF2D3748);

  static const Color lightOnSurface = Color(0xFF111827);
  static const Color darkOnSurface = Color(0xFFF1F5FF);

  static const double radiusXs = 6;
  static const double radiusS = 8;
  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusPill = 1000;
  static const double radiusSheet = 28;
  static const double borderWidthHairline = 0.8;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 22;

  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius borderRadiusS = BorderRadius.all(
    Radius.circular(radiusS),
  );
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusXxl = BorderRadius.all(
    Radius.circular(radiusXxl),
  );
  static const BorderRadius borderRadiusPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const EdgeInsets listTileContentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 2,
  );

  static List<Color> loginBackground(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [Color(0xFF0D1117), Color(0xFF111827), Color(0xFF0F172A)];
    }
    return const [Color(0xFFEEF2FF), Color(0xFFF8F9FB), Color(0xFFF0F4FF)];
  }
}

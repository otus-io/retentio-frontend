import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'theme_typography_tokens.dart';

class AppThemeTypography {
  AppThemeTypography._();

  static TextTheme build(Brightness brightness) {
    final source = ThemeData(brightness: brightness).textTheme;
    final body = source.apply(fontFamily: AppFontFamilies.atkinsonHyperlegible);

    TextStyle headingStyle(TextStyle? base, FontWeight weight) {
      return (base ?? const TextStyle()).copyWith(
        fontFamily: AppFontFamilies.crimsonPro,
        fontWeight: weight,
      );
    }

    return body.copyWith(
      displayLarge:
          headingStyle(
            source.displayLarge,
            AppTypographyTokens.weightSemiBold,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingDisplayLarge,
            height: AppTypographyTokens.lineHeightDisplayLarge,
          ),
      displayMedium:
          headingStyle(
            source.displayMedium,
            AppTypographyTokens.weightSemiBold,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingDisplayMedium,
            height: AppTypographyTokens.lineHeightDisplayMedium,
          ),
      displaySmall:
          headingStyle(
            source.displaySmall,
            AppTypographyTokens.weightMedium,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingDisplaySmall,
            height: AppTypographyTokens.lineHeightDisplaySmall,
          ),
      headlineLarge:
          headingStyle(
            source.headlineLarge,
            AppTypographyTokens.weightMedium,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingHeadlineLarge,
            height: AppTypographyTokens.lineHeightHeadlineLarge,
          ),
      headlineMedium:
          headingStyle(
            source.headlineMedium,
            AppTypographyTokens.weightMedium,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingHeadlineMedium,
            height: AppTypographyTokens.lineHeightHeadlineMedium,
          ),
      headlineSmall:
          headingStyle(
            source.headlineSmall,
            AppTypographyTokens.weightMedium,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingHeadlineSmall,
            height: AppTypographyTokens.lineHeightHeadlineSmall,
          ),
      titleLarge:
          headingStyle(
            source.titleLarge,
            AppTypographyTokens.weightSemiBold,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingTitleLarge,
            height: AppTypographyTokens.lineHeightTitleLarge,
          ),
      titleMedium:
          headingStyle(
            source.titleMedium,
            AppTypographyTokens.weightSemiBold,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingTitleMedium,
            height: AppTypographyTokens.lineHeightTitleMedium,
          ),
      titleSmall:
          headingStyle(
            source.titleSmall,
            AppTypographyTokens.weightSemiBold,
          ).copyWith(
            letterSpacing: AppTypographyTokens.trackingTitleSmall,
            height: AppTypographyTokens.lineHeightTitleSmall,
          ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontWeight: AppTypographyTokens.weightRegular,
        letterSpacing: AppTypographyTokens.trackingBodyLarge,
        height: AppTypographyTokens.lineHeightBodyLarge,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontWeight: AppTypographyTokens.weightRegular,
        letterSpacing: AppTypographyTokens.trackingBodyMedium,
        height: AppTypographyTokens.lineHeightBodyMedium,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontWeight: AppTypographyTokens.weightRegular,
        letterSpacing: AppTypographyTokens.trackingBodySmall,
        height: AppTypographyTokens.lineHeightBodySmall,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: AppTypographyTokens.weightBold,
        letterSpacing: AppTypographyTokens.trackingLabelLarge,
        height: AppTypographyTokens.lineHeightLabelLarge,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontWeight: AppTypographyTokens.weightBold,
        letterSpacing: AppTypographyTokens.trackingLabelMedium,
        height: AppTypographyTokens.lineHeightLabelMedium,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: AppTypographyTokens.weightMedium,
        letterSpacing: AppTypographyTokens.trackingLabelSmall,
        height: AppTypographyTokens.lineHeightLabelSmall,
      ),
    );
  }
}

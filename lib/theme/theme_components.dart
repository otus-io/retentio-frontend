import 'package:flutter/material.dart';

import 'theme_tokens.dart';
import 'theme_typography_tokens.dart';

class AppThemeComponents {
  AppThemeComponents._();

  static ThemeData apply({
    required ThemeData base,
    required Brightness brightness,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final semanticTypography = base.semanticTypography;
    final inputBorder = OutlineInputBorder(
      borderRadius: AppThemeTokens.borderRadiusLg,
      borderSide: BorderSide(
        color: colorScheme.outline,
        width: AppThemeTokens.borderWidthHairline,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: semanticTypography.appBarTitle.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppThemeTokens.borderRadiusXl,
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: AppThemeTokens.borderWidthHairline,
          ),
        ),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusMd,
          ),
          textStyle: semanticTypography.controlLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: colorScheme.outline,
            width: AppThemeTokens.borderWidthHairline,
          ),
          padding: AppThemeTokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusMd,
          ),
          textStyle: semanticTypography.controlLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusSm,
          ),
          textStyle: semanticTypography.controlLabel,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
            : colorScheme.surfaceContainer,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppThemeTokens.borderWidthHairline,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppThemeTokens.borderWidthHairline,
          ),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppThemeTokens.borderWidthHairline,
          ),
        ),
        contentPadding: AppThemeTokens.inputContentPadding,
        hintStyle: semanticTypography.inputHint.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        labelStyle: semanticTypography.inputText.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return semanticTypography.navigationLabel.copyWith(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected
                ? AppTypographyTokens.weightBold
                : AppTypographyTokens.weightMedium,
          );
        }),
      ),
      iconTheme: IconThemeData(size: 22, color: colorScheme.onSurface),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppThemeTokens.borderRadiusMd,
        ),
        contentPadding: AppThemeTokens.listTileContentPadding,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: AppThemeTokens.borderRadiusXl,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppThemeTokens.radiusSheet),
          ),
        ),
      ),
    );
  }
}

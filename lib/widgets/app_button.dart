import 'package:flutter/material.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/theme/theme_typography_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.fullWidth = false,
    this.leading,
    this.trailing,
    this.child,
    this.style,
    this.useElevated = false,
  });

  final String? label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final Widget? leading;
  final Widget? trailing;
  final Widget? child;
  final ButtonStyle? style;
  final bool useElevated;

  double get _height => switch (size) {
    AppButtonSize.sm => 36,
    AppButtonSize.md => 44,
    AppButtonSize.lg => 52,
  };

  double get _hPadding => switch (size) {
    AppButtonSize.sm => 12,
    AppButtonSize.md => 16,
    AppButtonSize.lg => 20,
  };

  Widget _buildChild(BuildContext context) {
    final typography = Theme.of(context).semanticTypography;
    final textStyle = switch (size) {
      AppButtonSize.sm => (Theme.of(context).textTheme.labelMedium ?? typography.caption).copyWith(
        fontWeight: AppTypographyTokens.weightBold,
      ),
      AppButtonSize.md => typography.controlLabel,
      AppButtonSize.lg => typography.controlLabel.copyWith(
        fontWeight: AppTypographyTokens.weightSemiBold,
      ),
    };
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (child != null) {
      return child!;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Text(label ?? '', style: textStyle.copyWith(color: null)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !useElevated || variant == AppButtonVariant.primary,
      'useElevated is only supported with AppButtonVariant.primary to keep styling consistent.',
    );
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;
    final padding = EdgeInsets.symmetric(horizontal: _hPadding);
    final fixedSize = Size.fromHeight(_height);
    final childWidget = _buildChild(context);

    if (label == null && child == null) {
      throw ArgumentError('Either label or child must be provided');
    }

    if (useElevated) {
      Widget button = ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          padding: padding,
          fixedSize: fixedSize,
        ).merge(style),
        child: childWidget,
      );
      if (fullWidth) {
        button = SizedBox(width: double.infinity, child: button);
      }
      return button;
    }

    Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          padding: padding,
          fixedSize: fixedSize,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusMd,
          ),
        ).merge(style),
        child: childWidget,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          fixedSize: fixedSize,
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outline,
            width: AppThemeTokens.borderWidthHairline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusMd,
          ),
        ).merge(style),
        child: childWidget,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          padding: padding,
          fixedSize: fixedSize,
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusSm,
          ),
        ).merge(style),
        child: childWidget,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          padding: padding,
          fixedSize: fixedSize,
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          shape: RoundedRectangleBorder(
            borderRadius: AppThemeTokens.borderRadiusMd,
          ),
        ).merge(style),
        child: childWidget,
      ),
    };

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

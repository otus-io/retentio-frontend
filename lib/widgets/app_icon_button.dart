import 'package:flutter/material.dart';
import 'package:retentio/theme/theme_tokens.dart';

enum AppIconButtonVariant { defaultVariant, subtle, danger }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.variant = AppIconButtonVariant.defaultVariant,
    this.size = 20,
    this.tooltip,
    this.color,
    this.onLongPress,
    this.padding,
    this.constraints,
    this.visualDensity,
    this.iconSize,
    this.outlined = false,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final double size;
  final String? tooltip;
  final Color? color;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final VisualDensity? visualDensity;
  final double? iconSize;
  final bool outlined;

  Color _resolveColor(ColorScheme colorScheme) {
    if (color != null) return color!;
    return switch (variant) {
      AppIconButtonVariant.defaultVariant => colorScheme.onSurface,
      AppIconButtonVariant.subtle => colorScheme.onSurface.withValues(
        alpha: 0.6,
      ),
      AppIconButtonVariant.danger => colorScheme.error,
    };
  }

  Color _overlayColor(ColorScheme colorScheme) {
    return switch (variant) {
      AppIconButtonVariant.defaultVariant => colorScheme.onSurface.withValues(
        alpha: 0.08,
      ),
      AppIconButtonVariant.subtle => colorScheme.onSurface.withValues(
        alpha: 0.06,
      ),
      AppIconButtonVariant.danger => colorScheme.error.withValues(alpha: 0.12),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedEnabledColor = _resolveColor(colorScheme);
    final resolvedDisabledColor = Theme.of(context).disabledColor;
    final overlayColor = _overlayColor(colorScheme);
    final Widget resolvedIcon = iconWidget ?? Icon(icon, size: size);

    return IconButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      icon: resolvedIcon,
      tooltip: tooltip,
      padding: padding ?? EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: constraints != null ? constraints!.minWidth.clamp(44.0, double.infinity) : 44,
        minHeight: constraints != null ? constraints!.minHeight.clamp(44.0, double.infinity) : 44,
      ),
      visualDensity: visualDensity,
      iconSize: iconSize,
      color: resolvedEnabledColor,
      disabledColor: resolvedDisabledColor,
      style: ButtonStyle(
        side: outlined
            ? WidgetStatePropertyAll(
                BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.75),
                  width: AppThemeTokens.borderWidthHairline,
                ),
              )
            : null,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppThemeTokens.borderRadiusSm),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!outlined) return null;
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          return colorScheme.surfaceContainerHighest.withValues(alpha: 0.95);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return overlayColor;
          }
          return null;
        }),
      ),
    );
  }
}

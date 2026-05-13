import 'package:flutter/material.dart';

class DeckTextStyles {
  DeckTextStyles._();

  static TextStyle? pageSubtitle(ThemeData theme) => theme.textTheme.bodySmall
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.64));

  static TextStyle? deckTitle(ThemeData theme) => theme.textTheme.titleMedium;

  static TextStyle? countChip(ThemeData theme) =>
      theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface);

  static TextStyle? metricValue(ThemeData theme, Color color) =>
      theme.textTheme.titleSmall?.copyWith(color: color);

  static TextStyle? metricLabel(ThemeData theme) => theme.textTheme.labelSmall
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.62));

  static TextStyle? progressLabel(ThemeData theme) => theme.textTheme.labelMedium
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55));

  static TextStyle? progressValue(ThemeData theme) => theme.textTheme.labelMedium
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7));

  static TextStyle? rateValue(ThemeData theme) => theme.textTheme.bodyMedium;

  static TextStyle? selectedRateValue(ThemeData theme) => theme
      .textTheme
      .titleLarge
      ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);

  static TextStyle? rateLabel(ThemeData theme) => theme.textTheme.bodyMedium;

  static TextStyle? rateHint(ThemeData theme) => theme.textTheme.bodySmall
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.64));

  static TextStyle? fieldLabel(ThemeData theme) => theme.textTheme.labelSmall
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.72));

  static TextStyle? fieldInput(ThemeData theme) => theme.textTheme.bodyMedium;

  static TextStyle? feedbackMessage(ThemeData theme, Color color) =>
      theme.textTheme.bodyMedium?.copyWith(color: color);
}

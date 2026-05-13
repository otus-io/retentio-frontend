# Typography Theming Guide

This project uses a centralized typography system under `lib/theme`.

## Files

- `theme_typography_tokens.dart`
  - `AppTypographyTokens`: reusable font weight, letter spacing, and line-height tokens.
  - `AppTypographySemantic`: semantic typography API via `ThemeExtension`.
  - `ThemeData.semanticTypography` extension getter.
- `theme_typography.dart`
  - Builds `TextTheme` from Inter and applies tokenized metrics (no magic numbers).
- `app_theme.dart`
  - Registers `AppTypographySemantic` in `ThemeData.extensions`.
- `theme_components.dart`
  - Uses semantic typography for app bar/button/input/navigation component themes.

## Why

- Avoid scattered hard-coded typography values.
- Keep a single source of truth for font rhythm across all pages/components.
- Make future visual tuning possible by changing only tokens/semantic mappings.

## How to use in widgets

Prefer semantic typography for component-level styles:

```dart
final typography = Theme.of(context).semanticTypography;

Text('Section', style: typography.sectionTitle);
Text('Body', style: typography.bodyPrimary);
```

For Material text roles, continue using `Theme.of(context).textTheme` where appropriate.

## Rules

- Do not hardcode `fontSize`, `height`, `letterSpacing`, or `FontWeight` in business pages unless explicitly required.
- If a new visual role appears repeatedly, add it to `AppTypographySemantic`.
- If global rhythm changes are needed, update `AppTypographyTokens` first.

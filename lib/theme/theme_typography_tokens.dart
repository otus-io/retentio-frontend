import 'package:flutter/material.dart';

class AppTypographyTokens {
  AppTypographyTokens._();

  // Font weights
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Letter spacing
  static const double trackingDisplayLarge = -0.25;
  static const double trackingDisplayMedium = 0;
  static const double trackingDisplaySmall = 0;
  static const double trackingHeadlineLarge = 0;
  static const double trackingHeadlineMedium = 0;
  static const double trackingHeadlineSmall = 0;
  static const double trackingTitleLarge = 0;
  static const double trackingTitleMedium = 0.15;
  static const double trackingTitleSmall = 0.1;
  static const double trackingBodyLarge = 0.5;
  static const double trackingBodyMedium = 0.25;
  static const double trackingBodySmall = 0.4;
  static const double trackingLabelLarge = 0.1;
  static const double trackingLabelMedium = 0.5;
  static const double trackingLabelSmall = 0.5;

  // Line-height ratios
  static const double lineHeightDisplayLarge = 64 / 57;
  static const double lineHeightDisplayMedium = 52 / 45;
  static const double lineHeightDisplaySmall = 44 / 36;
  static const double lineHeightHeadlineLarge = 40 / 32;
  static const double lineHeightHeadlineMedium = 36 / 28;
  static const double lineHeightHeadlineSmall = 32 / 24;
  static const double lineHeightTitleLarge = 28 / 22;
  static const double lineHeightTitleMedium = 24 / 16;
  static const double lineHeightTitleSmall = 20 / 14;
  static const double lineHeightBodyLarge = 24 / 16;
  static const double lineHeightBodyMedium = 20 / 14;
  static const double lineHeightBodySmall = 16 / 12;
  static const double lineHeightLabelLarge = 20 / 14;
  static const double lineHeightLabelMedium = 16 / 12;
  static const double lineHeightLabelSmall = 16 / 11;
}

@immutable
class AppTypographySemantic extends ThemeExtension<AppTypographySemantic> {
  const AppTypographySemantic({
    required this.pageTitle,
    required this.sectionTitle,
    required this.blockTitle,
    required this.bodyPrimary,
    required this.bodySecondary,
    required this.caption,
    required this.controlLabel,
    required this.inputText,
    required this.inputHint,
    required this.appBarTitle,
    required this.navigationLabel,
    required this.menuLabel,
  });

  factory AppTypographySemantic.fromTextTheme(TextTheme textTheme) {
    return AppTypographySemantic(
      pageTitle: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
        fontWeight: AppTypographyTokens.weightSemiBold,
      ),
      sectionTitle: (textTheme.titleLarge ?? const TextStyle()).copyWith(
        fontWeight: AppTypographyTokens.weightSemiBold,
      ),
      blockTitle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
        fontWeight: AppTypographyTokens.weightSemiBold,
      ),
      bodyPrimary: textTheme.bodyMedium ?? const TextStyle(),
      bodySecondary: textTheme.bodySmall ?? const TextStyle(),
      caption: textTheme.labelSmall ?? const TextStyle(),
      controlLabel: (textTheme.labelLarge ?? const TextStyle()).copyWith(
        fontWeight: AppTypographyTokens.weightBold,
      ),
      inputText: textTheme.bodyMedium ?? const TextStyle(),
      inputHint: textTheme.bodyMedium ?? const TextStyle(),
      appBarTitle: (textTheme.titleLarge ?? const TextStyle()).copyWith(
        fontWeight: AppTypographyTokens.weightSemiBold,
      ),
      navigationLabel: (textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontWeight: AppTypographyTokens.weightMedium,
      ),
      menuLabel: textTheme.bodyMedium ?? const TextStyle(),
    );
  }

  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle blockTitle;
  final TextStyle bodyPrimary;
  final TextStyle bodySecondary;
  final TextStyle caption;
  final TextStyle controlLabel;
  final TextStyle inputText;
  final TextStyle inputHint;
  final TextStyle appBarTitle;
  final TextStyle navigationLabel;
  final TextStyle menuLabel;

  @override
  AppTypographySemantic copyWith({
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? blockTitle,
    TextStyle? bodyPrimary,
    TextStyle? bodySecondary,
    TextStyle? caption,
    TextStyle? controlLabel,
    TextStyle? inputText,
    TextStyle? inputHint,
    TextStyle? appBarTitle,
    TextStyle? navigationLabel,
    TextStyle? menuLabel,
  }) {
    return AppTypographySemantic(
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      blockTitle: blockTitle ?? this.blockTitle,
      bodyPrimary: bodyPrimary ?? this.bodyPrimary,
      bodySecondary: bodySecondary ?? this.bodySecondary,
      caption: caption ?? this.caption,
      controlLabel: controlLabel ?? this.controlLabel,
      inputText: inputText ?? this.inputText,
      inputHint: inputHint ?? this.inputHint,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      navigationLabel: navigationLabel ?? this.navigationLabel,
      menuLabel: menuLabel ?? this.menuLabel,
    );
  }

  @override
  AppTypographySemantic lerp(
    covariant ThemeExtension<AppTypographySemantic>? other,
    double t,
  ) {
    if (other is! AppTypographySemantic) {
      return this;
    }
    return AppTypographySemantic(
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t) ?? pageTitle,
      sectionTitle:
          TextStyle.lerp(sectionTitle, other.sectionTitle, t) ?? sectionTitle,
      blockTitle: TextStyle.lerp(blockTitle, other.blockTitle, t) ?? blockTitle,
      bodyPrimary:
          TextStyle.lerp(bodyPrimary, other.bodyPrimary, t) ?? bodyPrimary,
      bodySecondary:
          TextStyle.lerp(bodySecondary, other.bodySecondary, t) ?? bodySecondary,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      controlLabel:
          TextStyle.lerp(controlLabel, other.controlLabel, t) ?? controlLabel,
      inputText: TextStyle.lerp(inputText, other.inputText, t) ?? inputText,
      inputHint: TextStyle.lerp(inputHint, other.inputHint, t) ?? inputHint,
      appBarTitle:
          TextStyle.lerp(appBarTitle, other.appBarTitle, t) ?? appBarTitle,
      navigationLabel:
          TextStyle.lerp(navigationLabel, other.navigationLabel, t) ??
          navigationLabel,
      menuLabel: TextStyle.lerp(menuLabel, other.menuLabel, t) ?? menuLabel,
    );
  }
}

extension AppTypographySemanticThemeX on ThemeData {
  AppTypographySemantic get semanticTypography {
    return extension<AppTypographySemantic>() ??
        AppTypographySemantic.fromTextTheme(textTheme);
  }
}

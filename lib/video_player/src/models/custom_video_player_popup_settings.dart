import 'package:flutter/material.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/theme/theme_typography_tokens.dart';

class CustomVideoPlayerPopupSettings {
  final String popupTitle;
  final String popupQualityTitle;
  final String popupPlaybackSpeedTitle;
  final String defaultPlaybackspeedDescription;
  final TextStyle popupTitleTextStyle;
  final BoxDecoration popupDecoration;
  final double popupWidth;
  final EdgeInsets popupPadding;
  final TextStyle popupItemsTextStyle;
  final EdgeInsets popupItemsPadding;
  final BoxDecoration popupItemsDecoration;
  const CustomVideoPlayerPopupSettings({
    this.popupTitle = 'Video Settings',
    this.popupQualityTitle = 'Video Quality',
    this.popupPlaybackSpeedTitle = 'Playback Speed',
    this.popupTitleTextStyle = const TextStyle(
      color: Colors.white,
      fontWeight: AppTypographyTokens.weightSemiBold,
      letterSpacing: AppTypographyTokens.trackingTitleLarge,
      height: AppTypographyTokens.lineHeightTitleLarge,
    ),
    this.popupDecoration = const BoxDecoration(
      color: Color.fromARGB(255, 41, 40, 40),
      borderRadius: AppThemeTokens.borderRadiusS,
    ),
    this.popupWidth = 300,
    this.popupPadding = const EdgeInsets.all(8),
    this.popupItemsTextStyle = const TextStyle(
      color: Colors.white,
      fontWeight: AppTypographyTokens.weightRegular,
      letterSpacing: AppTypographyTokens.trackingBodyMedium,
      height: AppTypographyTokens.lineHeightBodyMedium,
    ),
    this.popupItemsPadding = const EdgeInsets.all(8),
    this.popupItemsDecoration = const BoxDecoration(),
    this.defaultPlaybackspeedDescription = 'Default',
  });
}

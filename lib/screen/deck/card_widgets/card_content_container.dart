import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/buttons_tab_bar.dart';

class CardContentContainer extends HookWidget {
  static const _kTabBarBorderWidth = AppThemeTokens.borderWidthHairline;
  static const _kTabRadius = 12.0;
  static const _kTabContentPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );

  const CardContentContainer({
    super.key,
    required this.cards,
    required this.color,
    this.accentColor,
    this.textColor,
    this.trailing,
    this.typographyDeckId,
    this.typographyIsFront = true,
  });

  final List<CardSlot> cards;
  final Color color;
  final Color? accentColor;
  final Color? textColor;
  final Widget? trailing;
  final String? typographyDeckId;
  final bool typographyIsFront;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final effectiveAccentColor = accentColor ?? color;
    final effectiveTextColor = textColor ?? color;

    // No fields: show empty content with optional menu
    if (cards.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: FactContent(
              items: const [],
              color: color,
              typographyDeckId: typographyDeckId,
              typographyIsFront: typographyIsFront,
            ),
          ),
          if (trailing != null)
            Positioned(top: 4, right: 4, child: trailing!),
        ],
      );
    }

    // Always show field tab bar (even for a single field, so the field name is visible)
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: _kTabBarBorderWidth,
                color: scheme.outline.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              ButtonsTabBar(
                backgroundColor: Colors.transparent,
                unselectedBackgroundColor: Colors.transparent,
                borderWidth: 0,
                radius: _kTabRadius,
                borderColor: Colors.transparent,
                unselectedBorderColor: Colors.transparent,
                contentPadding: _kTabContentPadding,
                buttonMargin: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 5,
                ),
                labelStyle:
                    textTheme.labelMedium?.copyWith(
                      color: effectiveAccentColor,
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: effectiveAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                unselectedLabelStyle:
                    textTheme.labelMedium?.copyWith(
                      color: effectiveTextColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ) ??
                    TextStyle(
                      color: effectiveTextColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                tabs: cards.map((e) => Tab(text: e.field)).toList(),
              ).expanded(),
              ?trailing,
            ],
          ),
        ),
        TabBarView(
          children: cards
              .map(
                (e) => FactContent(
                  items: e.items,
                  color: color,
                  typographyDeckId: typographyDeckId,
                  typographyIsFront: typographyIsFront,
                ),
              )
              .toList(),
        ).expanded(),
      ],
    );
  }
}

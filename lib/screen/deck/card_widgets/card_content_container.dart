import 'package:flutter/material.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/buttons_tab_bar.dart';

class CardContentContainer extends StatelessWidget {
  static const _kTabBarBorderWidth = AppThemeTokens.borderWidthHairline;
  static const _kTabRadius = 12.0;
  static const _kTabContentPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );

  static const _kContentPadding = EdgeInsets.fromLTRB(14, 12, 14, 16);
  static const _kContentPaddingWithMenu = EdgeInsets.fromLTRB(14, 40, 14, 16);
  static const _kSectionGap = 6.0;
  static const _kSectionSpacing = 14.0;
  static const _kDividerAlpha = 0.35;

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
    if (typographyIsFront) {
      return _buildTabbedContent(context);
    }
    return _buildStackedContent(context);
  }

  Widget _buildTabbedContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final effectiveAccentColor = accentColor ?? color;
    final effectiveTextColor = textColor ?? color;

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
          if (trailing != null) Positioned(top: 4, right: 4, child: trailing!),
        ],
      );
    }

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

  Widget _buildStackedContent(BuildContext context) {
    final padding = trailing != null
        ? _kContentPaddingWithMenu
        : _kContentPadding;

    if (cards.isEmpty) {
      return _CardContentShell(
        trailing: trailing,
        padding: padding,
        child: FactContent(
          items: const [],
          color: color,
          typographyDeckId: typographyDeckId,
          typographyIsFront: typographyIsFront,
        ),
      );
    }

    if (cards.length == 1) {
      return _CardContentShell(
        trailing: trailing,
        padding: padding,
        child: FactContent(
          items: cards.first.items,
          color: color,
          typographyDeckId: typographyDeckId,
          typographyIsFront: typographyIsFront,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final effectiveAccentColor = accentColor ?? color;

    return _CardContentShell(
      trailing: trailing,
      padding: padding,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        separatorBuilder: (context, index) => Divider(
          height: _kSectionSpacing * 2,
          thickness: AppThemeTokens.borderWidthHairline,
          color: scheme.outline.withValues(alpha: _kDividerAlpha),
        ),
        itemBuilder: (context, index) {
          final slot = cards[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldSectionLabel(
                label: slot.field,
                accentColor: effectiveAccentColor,
              ),
              SizedBox(height: _kSectionGap),
              FactContent(
                items: slot.items,
                color: color,
                typographyDeckId: typographyDeckId,
                typographyIsFront: typographyIsFront,
                inline: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardContentShell extends StatelessWidget {
  const _CardContentShell({required this.child, this.trailing, this.padding});

  final Widget child;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
        if (trailing != null) Positioned(top: 4, right: 4, child: trailing!),
      ],
    );
  }
}

class _FieldSectionLabel extends StatelessWidget {
  static const _kLabelAccentWidth = 2.0;
  static const _kLabelAccentHeight = 12.0;

  const _FieldSectionLabel({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      header: true,
      label: label,
      child: Row(
        children: [
          Container(
            width: _kLabelAccentWidth,
            height: _kLabelAccentHeight,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.labelSmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ) ??
                  TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

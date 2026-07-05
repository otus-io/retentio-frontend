import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/screen/deck/providers/deck_card_typography.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

class CardText extends HookConsumerWidget {
  static const _kFallbackLetterSpacing = 0.2;
  static const _kFallbackHeight = 1.42;
  static const _kInlinePadding = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 4,
  );
  static const _kScrollPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  const CardText({
    super.key,
    required this.text,
    required this.color,
    this.scrollable = true,
    this.typographyDeckId,
    this.typographyIsFront = true,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final Color color;

  /// When set, font sizes and Noto Sans JP match [deckSidesTypographyProvider] for this deck.
  final String? typographyDeckId;

  /// Which card side to use when [typographyDeckId] is set (front vs back sizes).
  final bool typographyIsFront;

  /// When false, only the text is rendered (no internal scroll) for embedding in
  /// a parent [SingleChildScrollView], e.g. text + audio on one tab.
  final bool scrollable;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseThemeStyle = Theme.of(context).textTheme.titleLarge;
    final deckId = typographyDeckId;
    final typography = deckId == null
        ? null
        : ref
              .watch(deckSidesTypographyProvider(deckId))
              .forSide(typographyIsFront);
    final style =
        typography?.baseTextStyle(color) ??
        baseThemeStyle?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: _kFallbackLetterSpacing,
          height: _kFallbackHeight,
          color: color,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: _kFallbackLetterSpacing,
          height: _kFallbackHeight,
          color: color,
        );
    final rubyStyle = typography?.rubyTextStyle(color);
    final textWidget = WikiRubyMarkup.looksLikeMarkup(text)
        ? wikiRubyWrappedText(
            text: text,
            baseStyle: style,
            rubyStyle: rubyStyle,
            textAlign: textAlign,
          )
        : Text(text, textAlign: textAlign, style: style);
    if (!scrollable) {
      return Padding(padding: _kInlinePadding, child: textWidget);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final alignment = switch (textAlign) {
          TextAlign.center || TextAlign.justify => Alignment.center,
          TextAlign.end || TextAlign.right => Alignment.centerRight,
          _ => Alignment.centerLeft,
        };
        final alignedChild = Align(alignment: alignment, child: textWidget);
        return SingleChildScrollView(
          padding: _kScrollPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: alignedChild,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/screen/deck/providers/deck_card_typography.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

class CardText extends ConsumerWidget {
  const CardText({
    super.key,
    required this.text,
    required this.color,
    this.scrollable = true,
    this.typographyDeckId,
    this.typographyIsFront = true,
  });

  final String text;
  final Color color;

  /// When set, font sizes and Noto Sans JP match [deckSidesTypographyProvider] for this deck.
  final String? typographyDeckId;

  /// Which card side to use when [typographyDeckId] is set (front vs back sizes).
  final bool typographyIsFront;

  /// When false, only the text is rendered (no internal scroll) for embedding in
  /// a parent [SingleChildScrollView], e.g. combined text + audio in one column.
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckId = typographyDeckId;
    final typography = deckId == null
        ? null
        : ref
              .watch(deckSidesTypographyProvider(deckId))
              .forSide(typographyIsFront);
    final style =
        typography?.baseTextStyle(color) ??
        TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color,
        );
    final rubyStyle = typography?.rubyTextStyle(color);
    final textWidget = WikiRubyMarkup.looksLikeMarkup(text)
        ? wikiRubyWrappedText(
            text: text,
            baseStyle: style,
            rubyStyle: rubyStyle,
          )
        : Text(text, textAlign: TextAlign.center, style: style);
    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: textWidget,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: textWidget),
          ),
        );
      },
    );
  }
}

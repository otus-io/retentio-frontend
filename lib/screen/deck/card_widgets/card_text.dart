import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardText extends ConsumerWidget {
  const CardText({
    super.key,
    required this.text,
    required this.color,
    this.scrollable = true,
  });

  final String text;
  final Color color;

  /// When false, only the text is rendered (no internal scroll) for embedding in
  /// a parent [SingleChildScrollView], e.g. text + audio on one tab.
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: color,
    );
    final textWidget = Text(text, textAlign: TextAlign.center, style: style);
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

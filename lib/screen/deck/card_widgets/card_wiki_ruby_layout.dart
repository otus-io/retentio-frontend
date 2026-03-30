import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

TextStyle wikiRubyReadingStyle(TextStyle base) => base.copyWith(
  fontSize: (base.fontSize ?? 18) * 0.55,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.0,
);

Widget _wikiRubyCell(WikiSegRuby seg, TextStyle base, TextStyle ruby) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(seg.reading, style: ruby),
          Text(seg.kanji, style: base),
        ],
      ),
    );

/// Inline widgets for composed surface `[pos, end)`, or null if a ruby unit is split.
List<Widget>? wikiRubyRowWidgetsForRange(
  WikiRubyParseResult parsed,
  int pos,
  int end,
  TextStyle base,
  TextStyle ruby,
) {
  final out = <Widget>[];
  var p = pos;
  while (p < end) {
    final seg = parsed.segmentAt(p);
    if (seg == null) return null;
    if (seg is WikiSegRuby) {
      if (p != seg.composedStart || seg.composedEnd > end) return null;
      out.add(_wikiRubyCell(seg, base, ruby));
      p = seg.composedEnd;
    } else if (seg is WikiSegPlain) {
      final from = p - seg.composedStart;
      final to = math.min(end, seg.composedEnd) - seg.composedStart;
      if (from < 0 || to > seg.text.length || from >= to) return null;
      out.add(Text(seg.text.substring(from, to), style: base));
      p = math.min(end, seg.composedEnd);
    } else {
      return null;
    }
  }
  return out;
}

/// Centered wrap of the full [text] string with `[[kanji|reading]]` ruby segments.
Widget wikiRubyWrappedText({
  required String text,
  required TextStyle baseStyle,
}) {
  final parsed = WikiRubyMarkup.parse(text);
  final rubyStyle = wikiRubyReadingStyle(baseStyle);
  final parts = wikiRubyRowWidgetsForRange(
    parsed,
    0,
    parsed.composed.length,
    baseStyle,
    rubyStyle,
  );
  if (parts == null) {
    return Text(text, textAlign: TextAlign.center, style: baseStyle);
  }
  return Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 0,
    runSpacing: 6,
    children: parts,
  );
}

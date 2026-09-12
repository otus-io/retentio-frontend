import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

TextStyle wikiRubyReadingStyle(TextStyle base, {double? rubyFontSize}) =>
    base.copyWith(
      fontSize: rubyFontSize ?? (base.fontSize ?? 18) * 0.55,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.0,
    );

Widget wikiRubyCellWidget({
  required String kanji,
  required String reading,
  required TextStyle baseStyle,
  required TextStyle rubyStyle,
}) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 1),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(reading, style: rubyStyle),
      Text(kanji, style: baseStyle),
    ],
  ),
);

Widget _wikiRubyCell(WikiSegRuby seg, TextStyle base, TextStyle ruby) {
  // Pending empty reading (inline add) renders as plain base on cards.
  if (seg.reading.isEmpty) {
    return Text(seg.kanji, style: base);
  }
  // Pending empty base (cleared kanji) renders reading as plain.
  if (seg.kanji.isEmpty) {
    return Text(seg.reading, style: base);
  }
  return wikiRubyCellWidget(
    kanji: seg.kanji,
    reading: seg.reading,
    baseStyle: base,
    rubyStyle: ruby,
  );
}

/// Inline widgets for composed surface `[pos, end)`, or null if a ruby unit is split.
///
/// Zero-width [WikiSegRuby] segments (empty-base `[[|reading]]`) are emitted at
/// their anchor index so card layout can still show the reading.
List<Widget>? wikiRubyRowWidgetsForRange(
  WikiRubyParseResult parsed,
  int pos,
  int end,
  TextStyle base,
  TextStyle ruby,
) {
  final out = <Widget>[];
  var p = pos;

  void addZeroWidthRubiesAt(int at) {
    for (final seg in parsed.segments) {
      if (seg is WikiSegRuby &&
          seg.composedStart == at &&
          seg.composedEnd == at) {
        out.add(_wikiRubyCell(seg, base, ruby));
      }
    }
  }

  addZeroWidthRubiesAt(p);
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
    addZeroWidthRubiesAt(p);
  }
  return out;
}

/// Centered wrap of the full [text] string with `[[kanji|reading]]` ruby segments.
Widget wikiRubyWrappedText({
  required String text,
  required TextStyle baseStyle,
  TextStyle? rubyStyle,
  TextAlign textAlign = TextAlign.center,
}) {
  final parsed = WikiRubyMarkup.parse(text);
  final resolvedRuby = rubyStyle ?? wikiRubyReadingStyle(baseStyle);
  final parts = wikiRubyRowWidgetsForRange(
    parsed,
    0,
    parsed.composed.length,
    baseStyle,
    resolvedRuby,
  );
  if (parts == null) {
    return Text(text, textAlign: textAlign, style: baseStyle);
  }
  final wrapAlignment = switch (textAlign) {
    TextAlign.start || TextAlign.left => WrapAlignment.start,
    TextAlign.end || TextAlign.right => WrapAlignment.end,
    _ => WrapAlignment.center,
  };
  return Wrap(
    alignment: wrapAlignment,
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 0,
    runSpacing: 6,
    children: parts,
  );
}

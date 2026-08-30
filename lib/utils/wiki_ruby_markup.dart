/// Parses `[[kanji|reading]]` segments (double brackets + pipe) into plain runs and
/// ruby pairs. Used for deck text without colliding with single `[]`.
sealed class WikiSeg {
  const WikiSeg({required this.composedStart, required this.composedEnd});

  final int composedStart;
  final int composedEnd;
}

class WikiSegPlain extends WikiSeg {
  const WikiSegPlain(
    this.text, {
    required super.composedStart,
    required super.composedEnd,
  });

  final String text;
}

class WikiSegRuby extends WikiSeg {
  const WikiSegRuby({
    required this.kanji,
    required this.reading,
    required super.composedStart,
    required super.composedEnd,
  });

  final String kanji;
  final String reading;
}

class WikiRubyParseResult {
  const WikiRubyParseResult({required this.segments, required this.composed});

  final List<WikiSeg> segments;
  final String composed;

  WikiSeg? segmentAt(int pos) {
    for (final s in segments) {
      if (s.composedStart <= pos && pos < s.composedEnd) return s;
    }
    return null;
  }
}

sealed class WikiRubyComposePiece {
  const WikiRubyComposePiece();
}

class WikiRubyComposePlain extends WikiRubyComposePiece {
  const WikiRubyComposePlain(this.text);

  final String text;
}

class WikiRubyComposeRuby extends WikiRubyComposePiece {
  const WikiRubyComposeRuby({required this.kanji, required this.reading});

  final String kanji;
  final String reading;
}

abstract final class WikiRubyMarkup {
  WikiRubyMarkup._();

  static final RegExp _pair = RegExp(r'\[\[([^\]|]+)\|([^\]]+)\]\]');

  static bool looksLikeMarkup(String s) => _pair.hasMatch(s);

  /// Ordered storage pieces for round-tripping wiki ruby markup.
  static List<WikiRubyComposePiece> decompose(String input) {
    final parsed = parse(input);
    return [
      for (final seg in parsed.segments)
        if (seg is WikiSegPlain)
          WikiRubyComposePlain(seg.text)
        else if (seg is WikiSegRuby)
          WikiRubyComposeRuby(kanji: seg.kanji, reading: seg.reading),
    ];
  }

  /// Rebuilds `[[kanji|reading]]` storage from [pieces].
  static String compose(List<WikiRubyComposePiece> pieces) {
    final buf = StringBuffer();
    for (final piece in pieces) {
      switch (piece) {
        case WikiRubyComposePlain(:final text):
          buf.write(text);
        case WikiRubyComposeRuby(:final kanji, :final reading):
          if (kanji.isNotEmpty && reading.isNotEmpty) {
            buf.write('[[$kanji|$reading]]');
          } else {
            buf.write(kanji);
          }
      }
    }
    return buf.toString();
  }

  /// Parses [input] into ordered segments. Text outside pairs is plain (including
  /// stray `[[` without a closing `]]`).
  static WikiRubyParseResult parse(String input) {
    final segments = <WikiSeg>[];
    final composedBuf = StringBuffer();
    var i = 0;
    var composedLen = 0;

    for (final m in _pair.allMatches(input)) {
      if (m.start > i) {
        final t = input.substring(i, m.start);
        composedLen = _addPlain(segments, composedBuf, t, composedLen);
      }
      final kanji = m.group(1) ?? '';
      final reading = m.group(2) ?? '';
      if (kanji.isNotEmpty && reading.isNotEmpty) {
        final start = composedLen;
        composedLen += kanji.length;
        composedBuf.write(kanji);
        segments.add(
          WikiSegRuby(
            kanji: kanji,
            reading: reading,
            composedStart: start,
            composedEnd: composedLen,
          ),
        );
      } else {
        composedLen = _addPlain(
          segments,
          composedBuf,
          m.group(0) ?? '',
          composedLen,
        );
      }
      i = m.end;
    }
    if (i < input.length) {
      composedLen = _addPlain(
        segments,
        composedBuf,
        input.substring(i),
        composedLen,
      );
    }
    return WikiRubyParseResult(
      segments: segments,
      composed: composedBuf.toString(),
    );
  }

  static int _addPlain(
    List<WikiSeg> segments,
    StringBuffer composedBuf,
    String t,
    int composedLen,
  ) {
    if (t.isEmpty) return composedLen;
    final start = composedLen;
    composedLen += t.length;
    composedBuf.write(t);
    segments.add(
      WikiSegPlain(t, composedStart: start, composedEnd: composedLen),
    );
    return composedLen;
  }

  /// Maps each code unit index in [composed] to a word index, or null if [wordTexts]
  /// do not exactly tile [composed].
  static List<int>? charToWordIndex(String composed, List<String> wordTexts) {
    if (composed.isEmpty) {
      return wordTexts.isEmpty ? <int>[] : null;
    }
    final out = List<int>.filled(composed.length, -1);
    var pos = 0;
    for (var wi = 0; wi < wordTexts.length; wi++) {
      final w = wordTexts[wi];
      if (w.isEmpty) return null;
      if (pos + w.length > composed.length) return null;
      if (composed.substring(pos, pos + w.length) != w) return null;
      for (var j = 0; j < w.length; j++) {
        out[pos + j] = wi;
      }
      pos += w.length;
    }
    if (pos != composed.length) return null;
    return out;
  }
}

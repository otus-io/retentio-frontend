import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/transcript_sync.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

void main() {
  group('WikiRubyMarkup.parse', () {
    test('extracts composed surface and segments for Japanese', () {
      const s = '[[皆|みな]]さんは[[思|おも]]い';
      final p = WikiRubyMarkup.parse(s);
      expect(p.composed, '皆さんは思い');
      expect(p.segments.length, 4);
      expect(p.segments[0], isA<WikiSegRuby>());
      expect((p.segments[0] as WikiSegRuby).kanji, '皆');
      expect((p.segments[0] as WikiSegRuby).reading, 'みな');
      expect((p.segments[1] as WikiSegPlain).text, 'さんは');
      expect((p.segments[2] as WikiSegRuby).kanji, '思');
      expect((p.segments[3] as WikiSegPlain).text, 'い');
    });

    test('supports Chinese base with pinyin reading', () {
      const s = '[[中国|Zhōngguó]]你好';
      final p = WikiRubyMarkup.parse(s);
      expect(p.composed, '中国你好');
      expect(p.segments.length, 2);
      final r = p.segments[0] as WikiSegRuby;
      expect(r.kanji, '中国');
      expect(r.reading, 'Zhōngguó');
      expect((p.segments[1] as WikiSegPlain).text, '你好');
    });

    test('empty input yields empty composed and no segments', () {
      final p = WikiRubyMarkup.parse('');
      expect(p.composed, '');
      expect(p.segments, isEmpty);
    });

    test('plain text without markup is one plain segment', () {
      final p = WikiRubyMarkup.parse('no markup here');
      expect(p.composed, 'no markup here');
      expect(p.segments.length, 1);
      expect((p.segments.single as WikiSegPlain).text, 'no markup here');
    });

    test('stray open brackets remain as plain text', () {
      final p = WikiRubyMarkup.parse('[[not closed');
      expect(p.composed, '[[not closed');
      expect(p.segments.single, isA<WikiSegPlain>());
    });

    test(
      'empty base or reading treats match as literal plain via group(0)',
      () {
        final p = WikiRubyMarkup.parse('[[|x]]');
        expect(p.composed, '[[|x]]');
        expect(p.segments.single, isA<WikiSegPlain>());

        final p2 = WikiRubyMarkup.parse('[[a|]]');
        expect(p2.composed, '[[a|]]');
        expect(p2.segments.single, isA<WikiSegPlain>());
      },
    );

    test('segmentAt returns correct segment for composed index', () {
      final p = WikiRubyMarkup.parse('[[ab|cd]]e');
      expect(p.segmentAt(0), isA<WikiSegRuby>());
      expect(p.segmentAt(1), isA<WikiSegRuby>());
      expect(p.segmentAt(2), isA<WikiSegPlain>());
      expect(p.segmentAt(99), isNull);
    });

    test('composed offsets are contiguous and cover composed length', () {
      final p = WikiRubyMarkup.parse('x[[甲|a]]yz');
      var expectedPos = 0;
      for (final s in p.segments) {
        expect(s.composedStart, expectedPos);
        expectedPos = s.composedEnd;
      }
      expect(expectedPos, p.composed.length);
    });
  });

  group('WikiRubyMarkup.charToWordIndex', () {
    test('maps when words tile composed', () {
      const composed = '皆さんは';
      final words = [
        TranscriptWord(word: '皆さん', start: 0, end: 0.3),
        TranscriptWord(word: 'は', start: 0.3, end: 0.5),
      ];
      final m = WikiRubyMarkup.charToWordIndex(composed, words)!;
      expect(m, [0, 0, 0, 1]);
    });

    test('empty composed with empty words yields empty map', () {
      expect(WikiRubyMarkup.charToWordIndex('', const []), <int>[]);
    });

    test('empty composed with non-empty words returns null', () {
      expect(
        WikiRubyMarkup.charToWordIndex('', [
          TranscriptWord(word: 'a', start: 0, end: 1),
        ]),
        isNull,
      );
    });

    test('returns null when word prefix does not match', () {
      final words = [TranscriptWord(word: 'a', start: 0, end: 1)];
      expect(WikiRubyMarkup.charToWordIndex('ab', words), isNull);
    });

    test('returns null when words leave remainder in composed', () {
      final words = [TranscriptWord(word: 'a', start: 0, end: 1)];
      expect(WikiRubyMarkup.charToWordIndex('a', words), isNotNull);
      expect(WikiRubyMarkup.charToWordIndex('ab', words), isNull);
    });

    test('returns null for empty word token', () {
      expect(
        WikiRubyMarkup.charToWordIndex('a', [
          TranscriptWord(word: '', start: 0, end: 1),
        ]),
        isNull,
      );
    });
  });

  group('WikiRubyMarkup.looksLikeMarkup', () {
    test('true when at least one valid pair exists', () {
      expect(WikiRubyMarkup.looksLikeMarkup('[[a|b]]'), isTrue);
      expect(WikiRubyMarkup.looksLikeMarkup('x [[漢|han]] y'), isTrue);
    });

    test('false for plain text', () {
      expect(WikiRubyMarkup.looksLikeMarkup('plain'), isFalse);
      expect(WikiRubyMarkup.looksLikeMarkup('[a|b]'), isFalse);
    });
  });
}

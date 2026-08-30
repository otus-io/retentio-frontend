import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

void main() {
  group('WikiRubyMarkup.decompose and compose', () {
    test('round-trips Japanese example', () {
      const raw = '[[皆|みな]]さんは[[思|おも]]い';
      final pieces = WikiRubyMarkup.decompose(raw);
      expect(pieces.length, 4);
      expect(pieces[0], isA<WikiRubyComposeRuby>());
      expect((pieces[0] as WikiRubyComposeRuby).kanji, '皆');
      expect((pieces[0] as WikiRubyComposeRuby).reading, 'みな');
      expect((pieces[1] as WikiRubyComposePlain).text, 'さんは');
      expect(WikiRubyMarkup.compose(pieces), raw);
    });

    test('compose omits invalid ruby when reading is empty', () {
      final out = WikiRubyMarkup.compose([
        const WikiRubyComposeRuby(kanji: '建', reading: ''),
        const WikiRubyComposePlain('ます'),
      ]);
      expect(out, '建ます');
    });

    test('decompose empty string yields empty compose pieces', () {
      expect(WikiRubyMarkup.decompose(''), isEmpty);
      expect(WikiRubyMarkup.compose([]), '');
    });
  });

  group('WikiRubyMarkup.wrapSelection', () {
    test('wraps the selected range with reading', () {
      expect(
        WikiRubyMarkup.wrapSelection(
          text: '見せてください',
          start: 0,
          end: 1,
          reading: 'み',
        ),
        '[[見|み]]せてください',
      );
    });

    test('trims reading whitespace', () {
      expect(
        WikiRubyMarkup.wrapSelection(
          text: '家',
          start: 0,
          end: 1,
          reading: ' いえ ',
        ),
        '[[家|いえ]]',
      );
    });

    test('returns null for empty range or blank reading', () {
      expect(
        WikiRubyMarkup.wrapSelection(text: '見', start: 0, end: 0, reading: 'み'),
        isNull,
      );
      expect(
        WikiRubyMarkup.wrapSelection(
          text: '見',
          start: 0,
          end: 1,
          reading: '  ',
        ),
        isNull,
      );
    });

    test('returns null when selection or reading breaks delimiters', () {
      expect(
        WikiRubyMarkup.wrapSelection(
          text: 'a|b',
          start: 0,
          end: 3,
          reading: 'x',
        ),
        isNull,
      );
      expect(
        WikiRubyMarkup.wrapSelection(
          text: '見',
          start: 0,
          end: 1,
          reading: 'み]',
        ),
        isNull,
      );
    });

    test('returns null for out-of-range indexes', () {
      expect(
        WikiRubyMarkup.wrapSelection(
          text: '見',
          start: -1,
          end: 1,
          reading: 'み',
        ),
        isNull,
      );
      expect(
        WikiRubyMarkup.wrapSelection(text: '見', start: 0, end: 2, reading: 'み'),
        isNull,
      );
    });
  });
}

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
}

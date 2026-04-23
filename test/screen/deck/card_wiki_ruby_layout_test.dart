import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

void main() {
  const base = TextStyle(fontSize: 18, color: Colors.black);

  group('wikiRubyRowWidgetsForRange', () {
    final ruby = wikiRubyReadingStyle(base);

    test('returns null when ruby segment is truncated by range end', () {
      final parsed = WikiRubyMarkup.parse('[[甲乙|cd]]');
      expect(wikiRubyRowWidgetsForRange(parsed, 0, 1, base, ruby), isNull);
    });

    test('splits plain segment across word-aligned ranges', () {
      final parsed = WikiRubyMarkup.parse('[[皆|みな]]さんは');
      final w1 = wikiRubyRowWidgetsForRange(parsed, 0, 3, base, ruby);
      final w2 = wikiRubyRowWidgetsForRange(parsed, 3, 4, base, ruby);
      expect(w1, isNotNull);
      expect(w2, isNotNull);
      expect(w1!.length, 2);
      expect(w2!.length, 1);
    });

    testWidgets('pumps row with furigana and following kana', (tester) async {
      final parsed = WikiRubyMarkup.parse('[[皆|みな]]さん');
      final widgets = wikiRubyRowWidgetsForRange(
        parsed,
        0,
        parsed.composed.length,
        base,
        ruby,
      );
      expect(widgets, isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Row(children: widgets!)),
        ),
      );
      expect(find.text('みな'), findsOneWidget);
      expect(find.text('皆'), findsOneWidget);
      expect(find.text('さん'), findsOneWidget);
    });

    testWidgets('Chinese pinyin appears above hanzi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: wikiRubyWrappedText(text: '[[中国|Zhōngguó]]', baseStyle: base),
          ),
        ),
      );
      expect(find.text('中国'), findsOneWidget);
      expect(find.text('Zhōngguó'), findsOneWidget);
    });
  });

  group('wikiRubyReadingStyle', () {
    test('scales font size down', () {
      final r = wikiRubyReadingStyle(const TextStyle(fontSize: 20));
      expect(r.fontSize, closeTo(11, 0.01));
    });

    test('honors explicit rubyFontSize', () {
      final r = wikiRubyReadingStyle(
        const TextStyle(fontSize: 20),
        rubyFontSize: 7.5,
      );
      expect(r.fontSize, 7.5);
    });
  });
}

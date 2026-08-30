import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/wiki_ruby_content_editor.dart';

void main() {
  Future<void> pumpEditor(
    WidgetTester tester, {
    required TextEditingController storage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WikiRubyContentEditor(
            storage: storage,
            baseStyle: const TextStyle(fontSize: 16),
            readingHint: 'Reading',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows card-like ruby without raw markup', (tester) async {
    final storage = TextEditingController(text: '[[皆|みな]]さん');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    expect(find.text('皆'), findsOneWidget);
    expect(find.text('みな'), findsOneWidget);
    expect(find.text('さん'), findsOneWidget);
    expect(find.textContaining('[['), findsNothing);
  });

  testWidgets('tap ruby opens reading editor and updates storage', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[建|た]]てます');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    await tester.tap(find.text('建'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'たて');
    await tester.pump();

    expect(storage.text, '[[建|たて]]てます');
  });

  testWidgets('tab moves from one ruby reading to the next', (tester) async {
    final storage = TextEditingController(text: '[[見|み]]せ[[下|くだ]]');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    await tester.tap(find.text('見'));
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final focused = tester
        .widgetList<TextField>(find.byType(TextField))
        .where((f) => f.focusNode?.hasFocus == true);
    expect(focused.single.controller?.text, 'くだ');
  });

  testWidgets('keeps short ruby sentence on one compact row', (tester) async {
    final storage = TextEditingController(text: '～を[[見|み]]せて[[下|くだ]]さい。');
    addTearDown(storage.dispose);
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEditor(tester, storage: storage);

    final size = tester.getSize(find.byType(WikiRubyContentEditor));
    expect(size.height, lessThan(80));
  });

  testWidgets(
    'empty continuation stays on same row after multiple ruby cells',
    (tester) async {
      final storage = TextEditingController(text: '[[店|みせ]]点[[紅葉|もみじ]]');
      addTearDown(storage.dispose);
      await tester.binding.setSurfaceSize(const Size(400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WikiRubyContentEditor(
              storage: storage,
              baseStyle: const TextStyle(fontSize: 18, height: 1.0),
              readingHint: 'Reading',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstKanjiY = tester.getTopLeft(find.text('店')).dy;
      final secondKanjiY = tester.getTopLeft(find.text('紅葉')).dy;
      final continuationField = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text.isEmpty == true,
      );
      expect(continuationField, findsOneWidget);
      final continuationY = tester.getTopLeft(continuationField).dy;

      expect(secondKanjiY, closeTo(firstKanjiY, 2.0));
      expect(continuationY, closeTo(firstKanjiY, 2.0));

      final continuationWidth = tester.getSize(continuationField).width;
      expect(continuationWidth, lessThan(24));
    },
  );

  testWidgets('plain segment sits tight against adjacent ruby cells', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[店|みせ]]点[[紅葉|もみじ]]');
    addTearDown(storage.dispose);
    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WikiRubyContentEditor(
            storage: storage,
            baseStyle: const TextStyle(fontSize: 18, height: 1.0),
            readingHint: 'Reading',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shopRight = tester.getTopRight(find.text('店')).dx;
    final tenLeft = tester.getTopLeft(find.text('点')).dx;
    final tenRight = tester.getTopRight(find.text('点')).dx;
    final momijiLeft = tester.getTopLeft(find.text('紅葉')).dx;

    expect(tenLeft - shopRight, lessThan(12));
    expect(momijiLeft - tenRight, lessThan(12));

    final shopBottom = tester.getBottomLeft(find.text('店')).dy;
    final tenBottom = tester.getBottomLeft(find.text('点')).dy;
    final momijiBottom = tester.getBottomLeft(find.text('紅葉')).dy;
    expect((tenBottom - shopBottom).abs(), lessThanOrEqualTo(2.0));
    expect((momijiBottom - shopBottom).abs(), lessThanOrEqualTo(2.0));
  });

  testWidgets('plain base text bottom aligns with ruby kanji bottom', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[店|みせ]]点');
    addTearDown(storage.dispose);
    const baseStyle = TextStyle(fontSize: 18, height: 1.0);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WikiRubyContentEditor(
            storage: storage,
            baseStyle: baseStyle,
            readingHint: 'Reading',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final kanjiBottom = tester.getBottomLeft(find.text('店')).dy;
    final plainBottom = tester.getBottomLeft(find.text('点')).dy;
    expect((kanjiBottom - plainBottom).abs(), lessThanOrEqualTo(2.0));
  });

  testWidgets('plain continuation has no fill/border and matches base size', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[店|みせ]]点');
    addTearDown(storage.dispose);
    const baseStyle = TextStyle(fontSize: 18, height: 1.0);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFCCCCCC),
            border: OutlineInputBorder(),
          ),
        ),
        home: Scaffold(
          body: WikiRubyContentEditor(
            storage: storage,
            baseStyle: baseStyle,
            readingHint: 'Reading',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final plainField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == '点',
      ),
    );
    expect(plainField.style?.fontSize, 18);
    expect(plainField.decoration?.filled, isFalse);
    expect(plainField.decoration?.border, InputBorder.none);
    expect(plainField.decoration?.enabledBorder, InputBorder.none);
    expect(plainField.decoration?.focusedBorder, InputBorder.none);
  });

  testWidgets('allows typing after ruby when markup ends on a ruby cell', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[見|み]]');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    final continuationField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.controller?.text.isEmpty == true &&
          w.focusNode?.hasFocus == true,
    );
    expect(continuationField, findsOneWidget);

    await tester.enterText(continuationField, 'せて');
    await tester.pump();

    expect(storage.text, '[[見|み]]せて');
  });

  testWidgets('Ruby toolbar on plain segment wraps and rebuilds slots', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[見|み]]下さい');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    final plainField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '下さい',
    );
    expect(plainField, findsOneWidget);

    final editable = find.descendant(
      of: plainField,
      matching: find.byType(EditableText),
    );
    final state = tester.state<EditableTextState>(editable);
    state.userUpdateTextEditingValue(
      const TextEditingValue(
        text: '下さい',
        selection: TextSelection(baseOffset: 0, extentOffset: 1),
      ),
      SelectionChangedCause.toolbar,
    );
    await tester.pump();
    state.showToolbar();
    await tester.pumpAndSettle();

    expect(find.text('Ruby'), findsOneWidget);
    await tester.tap(find.text('Ruby'));
    await tester.pumpAndSettle();

    expect(find.text('Reading for 下'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'くだ');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(storage.text, '[[見|み]][[下|くだ]]さい');
    expect(find.text('下'), findsOneWidget);
    expect(find.text('くだ'), findsOneWidget);
  });

  test('wikiRubyContentUsesReadingEditor detects markup', () {
    expect(wikiRubyContentUsesReadingEditor('[[甲|a]]'), isTrue);
    expect(wikiRubyContentUsesReadingEditor('hello'), isFalse);
  });
}

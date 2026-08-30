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

  testWidgets('shows card-like ruby without raw markup or text fields', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[皆|みな]]さん');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    expect(find.text('皆'), findsOneWidget);
    expect(find.text('みな'), findsOneWidget);
    expect(find.text('さん'), findsOneWidget);
    expect(find.textContaining('[['), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('tap ruby opens reading editor and updates storage', (
    tester,
  ) async {
    final storage = TextEditingController(text: '[[建|た]]てます');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    await tester.tap(find.text('建'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'たて');
    await tester.pump();

    expect(storage.text, '[[建|たて]]てます');
  });

  testWidgets('tab moves from one ruby reading to the next', (tester) async {
    final storage = TextEditingController(text: '[[見|み]]せ[[下|くだ]]');
    addTearDown(storage.dispose);
    await pumpEditor(tester, storage: storage);

    await tester.tap(find.text('見'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'くだ');
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

  test('wikiRubyContentUsesReadingEditor detects markup', () {
    expect(wikiRubyContentUsesReadingEditor('[[甲|a]]'), isTrue);
    expect(wikiRubyContentUsesReadingEditor('hello'), isFalse);
  });
}

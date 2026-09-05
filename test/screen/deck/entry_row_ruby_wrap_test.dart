import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/screen/deck/fact_add_composer/wiki_ruby_content_editor.dart';

void main() {
  testWidgets('selecting text and applying Ruby switches to card editor', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = '見せて';

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
          body: AddFactEntryRow(
            row: row,
            loc: lookupAppLocalizations(const Locale('en')),
            theme: ThemeData.light(),
            outlineColor: Colors.grey,
            onClearSlot: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WikiRubyContentEditor), findsNothing);

    final editable = find.byType(EditableText);
    final state = tester.state<EditableTextState>(editable);
    state.userUpdateTextEditingValue(
      const TextEditingValue(
        text: '見せて',
        selection: TextSelection(baseOffset: 0, extentOffset: 1),
      ),
      SelectionChangedCause.toolbar,
    );
    await tester.pump();
    state.showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ruby'));
    await tester.pumpAndSettle();

    expect(row.content.text, '[[見|]]せて');
    expect(find.byType(WikiRubyContentEditor), findsOneWidget);
    expect(find.textContaining('[['), findsNothing);

    // Inline empty reading is focused — type reading without a dialog.
    final pendingReading = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.controller?.text.isEmpty == true &&
          w.focusNode?.hasFocus == true,
    );
    expect(pendingReading, findsOneWidget);
    await tester.enterText(pendingReading, 'み');
    await tester.pump();

    expect(row.content.text, '[[見|み]]せて');
  });

  testWidgets('removing last ruby keeps caret in plain field', (tester) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'あ[[見|み]]い';

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
          body: AddFactEntryRow(
            row: row,
            loc: lookupAppLocalizations(const Locale('en')),
            theme: ThemeData.light(),
            outlineColor: Colors.grey,
            onClearSlot: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WikiRubyContentEditor), findsOneWidget);

    final kanjiField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '見',
    );
    await tester.tap(kanjiField);
    await tester.pumpAndSettle();
    await tester.enterText(kanjiField, '');
    await tester.pump();
    expect(row.content.text, 'あ[[|み]]い');

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(row.content.text, 'あい');
    expect(find.byType(WikiRubyContentEditor), findsNothing);
    expect(row.content.selection.baseOffset, 1);

    final focused = tester
        .widgetList<TextField>(find.byType(TextField))
        .where((f) => f.focusNode?.hasFocus == true);
    expect(focused, isNotEmpty);
    expect(focused.single.controller?.text, 'あい');
    expect(focused.single.controller?.selection.baseOffset, 1);
  });
}

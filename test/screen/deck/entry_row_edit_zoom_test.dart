import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';

Widget _harness(AddFactRowModel row, {ThemeData? theme}) {
  final resolvedTheme = theme ?? ThemeData.light();
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: resolvedTheme,
    home: Scaffold(
      body: AddFactEntryRow(
        row: row,
        loc: lookupAppLocalizations(const Locale('en')),
        theme: resolvedTheme,
        outlineColor: Colors.grey,
        onClearSlot: (_) {},
      ),
    ),
  );
}

void main() {
  test('addFactEntryContentEditStyle enlarges explicit fontSize', () {
    const base = TextStyle(fontSize: 14);
    expect(
      addFactEntryContentEditStyle(base).fontSize,
      closeTo(14 * 1.32, 0.001),
    );
  });

  test('addFactEntryContentEditStyle uses fallback when fontSize is null', () {
    expect(
      addFactEntryContentEditStyle(const TextStyle()).fontSize,
      closeTo(14 * 1.32, 0.001),
    );
  });

  test('addFactEntryContentBaseStyle keeps explicit fontSize', () {
    expect(
      addFactEntryContentBaseStyle(const TextStyle(fontSize: 16)).fontSize,
      16,
    );
  });

  test('addFactEntryContentBaseStyle fills null fontSize with fallback', () {
    expect(addFactEntryContentBaseStyle(const TextStyle()).fontSize, 14);
  });

  testWidgets('content uses enlarged style immediately without focus zoom', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'hello';

    final theme = ThemeData.light();

    await tester.pumpWidget(_harness(row, theme: theme));
    await tester.pumpAndSettle();

    expect(find.byType(AnimatedScale), findsNothing);

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final baseSize = addFactEntryContentBaseStyle(
      theme.textTheme.bodyMedium ?? const TextStyle(),
    ).fontSize!;
    final expected = addFactEntryContentEditStyle(
      TextStyle(fontSize: baseSize),
    ).fontSize!;
    expect(editable.style.fontSize, closeTo(expected, 0.001));

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final focused = tester.widget<EditableText>(find.byType(EditableText));
    expect(focused.style.fontSize, closeTo(expected, 0.001));
  });
}

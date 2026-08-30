import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/wiki_ruby_wrap_action.dart';

void main() {
  group('wikiRubyApplyWrapToController', () {
    test('wraps the current selection', () {
      final controller = TextEditingController(text: '見せてください');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );

      expect(wikiRubyApplyWrapToController(controller, 'み'), isTrue);
      expect(controller.text, '[[見|み]]せてください');
    });

    test('returns false when selection is collapsed', () {
      final controller = TextEditingController(text: '見');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 0);

      expect(wikiRubyApplyWrapToController(controller, 'み'), isFalse);
      expect(controller.text, '見');
    });

    test('returns false when reading is blank', () {
      final controller = TextEditingController(text: '見');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );

      expect(wikiRubyApplyWrapToController(controller, '  '), isFalse);
      expect(controller.text, '見');
    });

    test('wraps using explicit start/end when selection collapsed', () {
      final controller = TextEditingController(text: '見せて');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 0);

      expect(
        wikiRubyApplyWrapToController(controller, 'み', start: 0, end: 1),
        isTrue,
      );
      expect(controller.text, '[[見|み]]せて');
    });
  });

  testWidgets('reading dialog returns trimmed reading on Done', (tester) async {
    String? result;
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showWikiRubyReadingDialog(
                  context,
                  baseText: '見',
                  readingHint: 'Reading',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Reading for 見'), findsOneWidget);

    await tester.enterText(find.byType(TextField), ' み ');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, 'み');
  });

  testWidgets('reading dialog cancel returns null', (tester) async {
    var completed = false;
    String? result = 'unset';
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showWikiRubyReadingDialog(
                  context,
                  baseText: '見',
                  readingHint: 'Reading',
                );
                completed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('reading dialog Done with blank reading returns null', (
    tester,
  ) async {
    String? result = 'unset';
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showWikiRubyReadingDialog(
                  context,
                  baseText: '見',
                  readingHint: 'Reading',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('reading dialog submits from keyboard Done', (tester) async {
    String? result;
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showWikiRubyReadingDialog(
                  context,
                  baseText: '見',
                  readingHint: 'Reading',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'み');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, 'み');
  });

  testWidgets('selection toolbar omits Ruby when selection is collapsed', (
    tester,
  ) async {
    final controller = TextEditingController(text: '見');
    addTearDown(controller.dispose);

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
          body: TextField(
            controller: controller,
            contextMenuBuilder: (context, editableTextState) {
              return wikiRubySelectionToolbar(
                context: context,
                editableTextState: editableTextState,
                loc: AppLocalizations.of(context)!,
                readingHint: 'Reading',
                onReadingChosen: (_, {required start, required end}) async {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<EditableTextState>(find.byType(EditableText));
    state.userUpdateTextEditingValue(
      const TextEditingValue(
        text: '見',
        selection: TextSelection.collapsed(offset: 1),
      ),
      SelectionChangedCause.toolbar,
    );
    await tester.pump();
    state.showToolbar();
    await tester.pumpAndSettle();

    expect(find.text('Ruby'), findsNothing);
  });

  testWidgets('Ruby from toolbar shows dialog above a bottom sheet', (
    tester,
  ) async {
    final controller = TextEditingController(text: '見せて');
    addTearDown(controller.dispose);

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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder: (context, editableTextState) {
                        return wikiRubySelectionToolbar(
                          context: context,
                          editableTextState: editableTextState,
                          loc: AppLocalizations.of(context)!,
                          readingHint: 'Reading',
                          onReadingChosen:
                              (reading, {required start, required end}) async {
                                wikiRubyApplyWrapToController(
                                  controller,
                                  reading,
                                  start: start,
                                  end: end,
                                );
                              },
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    final state = tester.state<EditableTextState>(find.byType(EditableText));
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
    await tester.pump(); // schedule post-frame callback
    await tester.pumpAndSettle();

    expect(find.text('Reading for 見'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'み');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(controller.text, '[[見|み]]せて');
  });
}

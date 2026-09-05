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

    test('wraps with empty reading for inline add', () {
      final controller = TextEditingController(text: '見せて');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );

      expect(wikiRubyApplyWrapToController(controller, ''), isTrue);
      expect(controller.text, '[[見|]]せて');
    });

    test('returns false when selection is collapsed', () {
      final controller = TextEditingController(text: '見');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 0);

      expect(wikiRubyApplyWrapToController(controller, 'み'), isFalse);
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
                onRubyWrap: ({required start, required end}) async {},
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

  testWidgets('Ruby from toolbar wraps with empty reading (no dialog)', (
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
                          onRubyWrap: ({required start, required end}) async {
                            wikiRubyApplyWrapToController(
                              controller,
                              '',
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
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Reading for 見'), findsNothing);
    expect(controller.text, '[[見|]]せて');
  });

  testWidgets('toolbar button activates once per gesture and skips cancel', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WikiRubyToolbarButton(
            label: 'Ruby',
            onActivate: () => activations++,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.text('Ruby'));
    final gesture = await tester.startGesture(center);
    // Cancel before the deferred frame callback runs.
    await gesture.cancel();
    await tester.pump();
    expect(activations, 0);

    final gesture2 = await tester.startGesture(center);
    await gesture2.up();
    await tester.pump();
    expect(activations, 1);

    // Second complete gesture can activate again.
    final gesture3 = await tester.startGesture(center);
    await gesture3.up();
    await tester.pump();
    expect(activations, 2);
  });
}

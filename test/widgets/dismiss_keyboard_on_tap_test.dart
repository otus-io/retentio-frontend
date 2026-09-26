import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/dismiss_keyboard_on_tap.dart';

void main() {
  testWidgets('first tap on a text field takes focus without a prior tap', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DismissKeyboardOnTap(child: TextField(focusNode: focus)),
        ),
      ),
    );

    expect(focus.hasFocus, isFalse);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('tap on blank space dismisses an already-focused field', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DismissKeyboardOnTap(
            child: Column(
              children: [
                TextField(focusNode: focus),
                const SizedBox(height: 80, width: 200, child: Text('blank')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.tap(find.text('blank'));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('pointerHitsEditable is false for empty hit targets', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));
    final viewId = tester.view.viewId;
    expect(
      DismissKeyboardOnTap.pointerHitsEditable(Offset.zero, viewId),
      isFalse,
    );
  });

  testWidgets('pointerHitsEditable is true over a focused TextField', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 200, child: TextField())),
        ),
      ),
    );
    final field = tester.getCenter(find.byType(TextField));
    final viewId = tester.view.viewId;
    expect(DismissKeyboardOnTap.pointerHitsEditable(field, viewId), isTrue);
  });
}

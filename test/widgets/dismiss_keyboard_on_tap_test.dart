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

  testWidgets('drag from blank space does not dismiss the keyboard', (
    tester,
  ) async {
    final focus = await _pumpFocusedFieldWithBlank(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('blank')),
    );
    await gesture.moveBy(const Offset(0, 50));
    await gesture.up();
    await tester.pump();

    expect(focus.hasFocus, isTrue);
  });

  testWidgets('cancelled pointer does not dismiss the keyboard', (
    tester,
  ) async {
    final focus = await _pumpFocusedFieldWithBlank(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('blank')),
    );
    await gesture.cancel();
    await tester.pump();

    expect(focus.hasFocus, isTrue);
  });

  testWidgets('small jitter within touch slop still counts as a tap', (
    tester,
  ) async {
    final focus = await _pumpFocusedFieldWithBlank(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('blank')),
    );
    await gesture.moveBy(const Offset(0, 2));
    await gesture.up();
    await tester.pump();

    expect(focus.hasFocus, isFalse);
  });

  testWidgets('only the most recent pointer is tracked', (tester) async {
    final focus = await _pumpFocusedFieldWithBlank(tester);
    final blank = tester.getCenter(find.text('blank'));

    final first = await tester.startGesture(blank, pointer: 1);
    final second = await tester.startGesture(blank, pointer: 2);

    // Events from the superseded pointer are ignored.
    await first.moveBy(const Offset(0, 50));
    await first.cancel();
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await second.up();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('pointer up after dispose mid-gesture is ignored', (
    tester,
  ) async {
    await _pumpFocusedFieldWithBlank(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('blank')),
    );

    // Sheet closes while the finger is still down.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await gesture.up();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose before the post-frame check skips it', (tester) async {
    await _pumpFocusedFieldWithBlank(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('blank')),
    );
    await gesture.up();

    // Unmount in the same frame the post-frame focus check runs.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(tester.takeException(), isNull);
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

Future<FocusNode> _pumpFocusedFieldWithBlank(WidgetTester tester) async {
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
  return focus;
}

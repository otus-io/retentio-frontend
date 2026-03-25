import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/focus.dart';

void main() {
  group('addFactIndexToRemoveOnMinus', () {
    final keys = List.generate(3, (_) => GlobalKey());

    test('returns null when only one row', () {
      expect(
        addFactIndexToRemoveOnMinus(
          rowCount: 1,
          focusContext: null,
          hostKeys: keys,
        ),
        isNull,
      );
    });

    test('returns last index when focus context is null', () {
      expect(
        addFactIndexToRemoveOnMinus(
          rowCount: 3,
          focusContext: null,
          hostKeys: keys,
        ),
        2,
      );
    });
  });

  group('addFactTargetRowIndexForMedia', () {
    test('defaults to 0 when focus is null', () {
      expect(
        addFactTargetRowIndexForMedia(
          focusContext: null,
          hostKeys: [GlobalKey(), GlobalKey()],
        ),
        0,
      );
    });
  });

  group('focus + host keys (widget)', () {
    testWidgets('target index follows focused field host', (tester) async {
      final keys = List.generate(2, (_) => GlobalKey());
      final focus0 = FocusNode();
      final focus1 = FocusNode();
      addTearDown(() {
        focus0.dispose();
        focus1.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KeyedSubtree(
                  key: keys[0],
                  child: TextField(focusNode: focus0),
                ),
                KeyedSubtree(
                  key: keys[1],
                  child: TextField(focusNode: focus1),
                ),
              ],
            ),
          ),
        ),
      );

      focus1.requestFocus();
      await tester.pump();

      final focusCtx = FocusManager.instance.primaryFocus!.context!;
      expect(
        addFactTargetRowIndexForMedia(focusContext: focusCtx, hostKeys: keys),
        1,
      );

      expect(
        addFactFocusedHostRowIndex(focusContext: focusCtx, hostKeys: keys),
        1,
      );
    });
  });
}

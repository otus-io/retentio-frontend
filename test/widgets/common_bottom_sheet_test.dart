import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

/// Sets logical view size so the modal sheet has stable layout (matches other tests).
void _setViewLogicalSize(WidgetTester tester, Size logicalSize) {
  final view = tester.view;
  final dpr = view.devicePixelRatio;
  final saved = view.physicalSize;
  view.physicalSize = Size(logicalSize.width * dpr, logicalSize.height * dpr);
  addTearDown(() {
    view.physicalSize = saved;
  });
}

void main() {
  group('showCommonBottomSheet', () {
    testWidgets(
      'inner Scaffold does not resize for keyboard (inset via padding)',
      (tester) async {
        _setViewLogicalSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        showCommonBottomSheet<void>(
                          context: context,
                          title: 'Test sheet',
                          child: const TextField(
                            key: Key('sheet_field'),
                            decoration: InputDecoration(hintText: 'Type'),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final scaffoldFinder = find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(Scaffold),
        );
        expect(scaffoldFinder, findsNothing);

        final scrollFinder = find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(SingleChildScrollView),
        );
        expect(scrollFinder, findsOneWidget);
      },
    );

    testWidgets('liftWithKeyboard sheet dismisses when tapping dimmed area', (
      tester,
    ) async {
      _setViewLogicalSize(tester, const Size(400, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () {
                      showCommonBottomSheet<void>(
                        context: context,
                        title: 'Compact sheet',
                        liftWithKeyboard: true,
                        child: const Text('Sheet body'),
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Compact sheet'), findsOneWidget);

      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.text('Compact sheet'), findsNothing);
    });

    testWidgets(
      'sheet stays open after keyboard insets and focusing TextField',
      (tester) async {
        _setViewLogicalSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        showCommonBottomSheet<void>(
                          context: context,
                          title: 'Edit Fact',
                          initialChildSize: 0.5,
                          minChildSize: 0.35,
                          maxChildSize: 0.9,
                          child: const TextField(
                            key: Key('sheet_field'),
                            decoration: InputDecoration(hintText: 'Content'),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Fact'), findsOneWidget);

        addTearDown(tester.view.resetViewInsets);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pump();

        await tester.tap(find.byKey(const Key('sheet_field')));
        await tester.pumpAndSettle();

        expect(find.text('Edit Fact'), findsOneWidget);
        expect(find.byKey(const Key('sheet_field')), findsOneWidget);
      },
    );

    testWidgets('fullScreen sheet fills viewport and is not draggable when '
        'enableDrag is false', (tester) async {
      _setViewLogicalSize(tester, const Size(400, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () {
                      showCommonBottomSheet<void>(
                        context: context,
                        title: 'Add fact',
                        fullScreen: true,
                        enableDrag: false,
                        child: const Text('Composer body'),
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.byKey(const Key('sheet_drag_handle')), findsNothing);
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(SizedBox),
        ),
      );
      expect(
        sizedBoxes.any((box) => box.height != null && box.height! >= 790),
        isTrue,
        reason: 'fullScreen sheet should fill the viewport edge-to-edge',
      );
      expect(find.byType(SafeArea), findsWidgets);
    });

    for (final title in <String?>['Add fact', null]) {
      testWidgets('fullScreen sheet closes via close button (title: $title)', (
        tester,
      ) async {
        _setViewLogicalSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        showCommonBottomSheet<void>(
                          context: context,
                          title: title,
                          fullScreen: true,
                          child: const Text('Composer body'),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Composer body'), findsOneWidget);

        await tester.tap(find.byKey(const Key('sheet_close_button')));
        await tester.pumpAndSettle();

        expect(find.text('Composer body'), findsNothing);
      });
    }

    group('fullScreen swipe down on iOS (long, scrolling form)', () {
      Future<void> openLongSheet(
        WidgetTester tester, {
        bool enableDrag = true,
      }) async {
        _setViewLogicalSize(tester, const Size(400, 800));
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => showCommonBottomSheet<void>(
                      context: context,
                      title: 'Add fact',
                      fullScreen: true,
                      enableDrag: enableDrag,
                      child: const SizedBox(
                        key: Key('long_body'),
                        height: 3000,
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('long_body')), findsOneWidget);
      }

      testWidgets('dragging the header handle closes the sheet', (
        tester,
      ) async {
        await openLongSheet(tester);

        await tester.drag(
          find.byKey(const Key('sheet_drag_handle')),
          const Offset(0, 500),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('long_body')), findsNothing);
      });

      testWidgets('pulling content down past the top closes only the sheet', (
        tester,
      ) async {
        await openLongSheet(tester);

        await tester.dragFrom(const Offset(200, 300), const Offset(0, 500));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('long_body')), findsNothing);
        expect(find.text('Open'), findsOneWidget);
      });

      testWidgets('a short pull on content keeps the sheet open', (
        tester,
      ) async {
        await openLongSheet(tester);

        await tester.dragFrom(const Offset(200, 300), const Offset(0, 60));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('long_body')), findsOneWidget);
      });

      testWidgets('enableDrag false ignores pulling content down', (
        tester,
      ) async {
        await openLongSheet(tester, enableDrag: false);

        await tester.dragFrom(const Offset(200, 300), const Offset(0, 500));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('long_body')), findsOneWidget);
      });
    });
  });
}

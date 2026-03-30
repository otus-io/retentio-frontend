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
        expect(scaffoldFinder, findsOneWidget);
        expect(
          tester.widget<Scaffold>(scaffoldFinder).resizeToAvoidBottomInset,
          isFalse,
        );
      },
    );

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
  });
}

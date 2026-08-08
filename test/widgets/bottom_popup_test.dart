import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/bottom_popup.dart';

/// Forces DPR 1 so FakeViewPadding values are logical pixels.
void _setViewLogicalSize(WidgetTester tester, Size logicalSize) {
  final view = tester.view;
  final savedDpr = view.devicePixelRatio;
  final savedSize = view.physicalSize;
  view.devicePixelRatio = 1.0;
  view.physicalSize = logicalSize;
  addTearDown(() {
    view.devicePixelRatio = savedDpr;
    view.physicalSize = savedSize;
  });
}

void _setViewPadding(WidgetTester tester, {double top = 0, double bottom = 0}) {
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  final padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
}

Future<void> _openPopup(
  WidgetTester tester, {
  required Widget child,
  double? height,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              BottomPopup.show(context, child: child, height: height);
            },
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open Sheet'));
  await tester.pumpAndSettle();
}

double? _sheetSizedBoxHeight(WidgetTester tester) {
  final sizedBox = tester.widget<SizedBox>(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.child is SafeArea,
      ),
    ),
  );
  return sizedBox.height;
}

void main() {
  group('BottomPopup Widget', () {
    testWidgets('renders its child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BottomPopup(child: const Text('Test Child'))),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('show method opens a modal bottom sheet', (tester) async {
      await _openPopup(tester, child: const Text('Sheet Content'));

      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('show method uses default height of 320', (tester) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      await _openPopup(tester, child: const Text('Default Height Content'));

      expect(find.text('Default Height Content'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 320);
    });

    testWidgets('show method accepts custom height', (tester) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      await _openPopup(tester, child: const Text('Custom Height'), height: 500);

      expect(find.text('Custom Height'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 500);
    });

    testWidgets('clamps height using top safe-area inset', (tester) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      _setViewPadding(tester, top: 50);

      // available = 800 - 0 - 0 - 50 = 750; request 780 → content 750; box 750
      await _openPopup(
        tester,
        child: const Text('Top Inset Content'),
        height: 780,
      );

      expect(find.text('Top Inset Content'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 750);
    });

    testWidgets(
      'includes bottom safe-area in sheet height and clamps available',
      (tester) async {
        _setViewLogicalSize(tester, const Size(400, 800));
        _setViewPadding(tester, bottom: 34);

        // available = 800 - 0 - 34 - 0 = 766; request 780 → content 766; box 800
        await _openPopup(
          tester,
          child: const Text('Bottom Inset Content'),
          height: 780,
        );

        expect(find.text('Bottom Inset Content'), findsOneWidget);
        expect(_sheetSizedBoxHeight(tester), 800);
      },
    );

    testWidgets('clamps height when keyboard viewInsets are present', (
      tester,
    ) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      addTearDown(tester.view.resetViewInsets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);

      // available = 800 - 300 - 0 - 0 = 500; request 700 → content 500; box 500
      await _openPopup(
        tester,
        child: const Text('Keyboard Content'),
        height: 700,
      );

      expect(find.text('Keyboard Content'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 500);
    });

    testWidgets('clamps with top, bottom, and keyboard insets together', (
      tester,
    ) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      _setViewPadding(tester, top: 47, bottom: 34);
      addTearDown(tester.view.resetViewInsets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);

      // available = 800 - 280 - 34 - 47 = 439; request 900 → content 439; box 473
      await _openPopup(
        tester,
        child: const Text('Combined Insets'),
        height: 900,
      );

      expect(find.text('Combined Insets'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 473);
    });

    testWidgets('floors content height at zero when insets exceed screen', (
      tester,
    ) async {
      _setViewLogicalSize(tester, const Size(400, 200));
      _setViewPadding(tester, top: 80, bottom: 40);
      addTearDown(tester.view.resetViewInsets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 120);

      // available = 200 - 120 - 40 - 80 = -40 → content 0; box 40
      await _openPopup(
        tester,
        child: const Text('Overflow Insets'),
        height: 320,
      );

      expect(find.text('Overflow Insets'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 40);
    });

    testWidgets('requested height below available is not expanded', (
      tester,
    ) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      _setViewPadding(tester, top: 50, bottom: 34);

      // available = 716; request 200 → content 200; box 234
      await _openPopup(tester, child: const Text('Small Request'), height: 200);

      expect(find.text('Small Request'), findsOneWidget);
      expect(_sheetSizedBoxHeight(tester), 234);
    });

    testWidgets('show method can be dismissed by tapping outside', (
      tester,
    ) async {
      await _openPopup(tester, child: const Text('Dismissible Content'));
      expect(find.text('Dismissible Content'), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Dismissible Content'), findsNothing);
    });

    testWidgets('bottom sheet has rounded top corners', (tester) async {
      await _openPopup(tester, child: const Text('Rounded Content'));

      expect(find.text('Rounded Content'), findsOneWidget);

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.shape, isA<RoundedRectangleBorder>());
      final shape = material.shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(16)),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/buttons_tab_bar.dart';

void main() {
  group('ButtonsTabBar', () {
    testWidgets('does not throw when built under DefaultTabController', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  ButtonsTabBar(
                    tabs: const [
                      Tab(icon: Icon(Icons.one_k)),
                      Tab(icon: Icon(Icons.two_k)),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        Center(child: Text('A')),
                        Center(child: Text('B')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ButtonsTabBar), findsOneWidget);
    });

    testWidgets('survives extra frames after pump (post-frame scroll)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  ButtonsTabBar(
                    tabs: const [
                      Tab(text: 'One'),
                      Tab(text: 'Two'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [SizedBox.expand(), SizedBox.expand()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not animate the tab strip into place on mount', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 6,
              initialIndex: 5,
              child: Column(
                children: [
                  ButtonsTabBar(
                    tabs: const [
                      Tab(text: 'Field one'),
                      Tab(text: 'Field two'),
                      Tab(text: 'Field three'),
                      Tab(text: 'Field four'),
                      Tab(text: 'Field five'),
                      Tab(text: 'Field six'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        SizedBox.expand(),
                        SizedBox.expand(),
                        SizedBox.expand(),
                        SizedBox.expand(),
                        SizedBox.expand(),
                        SizedBox.expand(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Let the post-frame attach callback position the strip.
      await tester.pump();

      final strip = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ButtonsTabBar),
          matching: find.byType(Scrollable),
        ),
      );
      final offsetAfterMount = strip.position.pixels;

      // The selected tab is off screen, so the strip must already be scrolled.
      expect(offsetAfterMount, greaterThan(0));

      // No scroll animation may still be running after mount.
      await tester.pump(const Duration(milliseconds: 300));
      expect(strip.position.pixels, offsetAfterMount);
    });

    testWidgets('center mode does not throw when tab strip lays out', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  ButtonsTabBar(
                    center: true,
                    tabs: const [
                      Tab(text: 'A'),
                      Tab(text: 'B'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        Center(child: Text('1')),
                        Center(child: Text('2')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

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

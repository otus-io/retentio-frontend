import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:retentio/widgets/common_refresher.dart';

void main() {
  group('CommonRefresher Widget', () {
    testWidgets('renders child when not loading and not empty', (tester) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              child: ListView(children: const [Text('Content Item')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Content Item'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              isLoading: true,
              child: ListView(children: const [Text('Content Item')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Content Item'), findsNothing);
    });

    testWidgets('shows empty view when isEmpty is true', (tester) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              isEmpty: true,
              emptyView: const Center(child: Text('No data available')),
              child: ListView(children: const [Text('Content Item')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No data available'), findsOneWidget);
      expect(find.text('Content Item'), findsNothing);
    });

    testWidgets('shows SizedBox when isEmpty and no emptyView provided', (
      tester,
    ) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              isEmpty: true,
              child: ListView(children: const [Text('Content Item')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Content Item'), findsNothing);
    });

    testWidgets('uses SmartRefresher internally', (tester) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              child: ListView(children: const [Text('Content')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SmartRefresher), findsOneWidget);
    });

    testWidgets('enablePullDown defaults to true', (tester) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              child: ListView(children: const [Text('Content')]),
            ),
          ),
        ),
      );
      await tester.pump();

      final smartRefresher = tester.widget<SmartRefresher>(
        find.byType(SmartRefresher),
      );
      expect(smartRefresher.enablePullDown, isTrue);
    });

    testWidgets('enablePullUp defaults to false', (tester) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              child: ListView(children: const [Text('Content')]),
            ),
          ),
        ),
      );
      await tester.pump();

      final smartRefresher = tester.widget<SmartRefresher>(
        find.byType(SmartRefresher),
      );
      expect(smartRefresher.enablePullUp, isFalse);
    });

    testWidgets('when both isLoading and isEmpty true shows loading', (
      tester,
    ) async {
      final controller = RefreshController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonRefresher(
              controller: controller,
              isLoading: true,
              isEmpty: true,
              emptyView: const Text('Empty'),
              child: ListView(children: const [Text('Content')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
      expect(find.text('Content'), findsNothing);
    });
  });
}

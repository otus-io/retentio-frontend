import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/extensions/widget_extension.dart';

void main() {
  group('WidgetExpanded', () {
    testWidgets('expanded wraps widget in Expanded with default flex', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Text('test').expanded(),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(Expanded), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('expanded uses custom flex value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Text('test').expanded(flex: 2),
              ],
            ),
          ),
        ),
      );
      final expanded = tester.widget<Expanded>(find.byType(Expanded));
      expect(expanded.flex, 2);
    });

    testWidgets('flexible wraps widget in Flexible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Text('test').flexible(),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(Flexible), findsOneWidget);
    });

    testWidgets('fittedBox wraps widget in FittedBox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('test').fittedBox(),
          ),
        ),
      );
      expect(find.byType(FittedBox), findsOneWidget);
    });
  });

  group('WidgetClip', () {
    testWidgets('oval wraps widget in ClipOval', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox(width: 50, height: 50).oval(),
          ),
        ),
      );
      expect(find.byType(ClipOval), findsOneWidget);
    });
  });

  group('WidgetCenter', () {
    testWidgets('center wraps widget in Center', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('test').center,
          ),
        ),
      );
      expect(find.byType(Center), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
    });
  });

  group('WidgetWithColum', () {
    testWidgets('colum with child creates Column with both widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('first').colum(child: Text('second')),
          ),
        ),
      );
      expect(find.byType(Column), findsOneWidget);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('colum without child returns original widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('alone').colum(),
          ),
        ),
      );
      expect(find.byType(Column), findsNothing);
      expect(find.text('alone'), findsOneWidget);
    });
  });

  group('SafeAreaWrapper', () {
    testWidgets('safeArea wraps widget in SafeArea', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('test').safeArea(),
          ),
        ),
      );
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  group('CusBadge', () {
    testWidgets('badgeWith shows badge when count > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Icon(Icons.notifications).badgeWith(5),
          ),
        ),
      );
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('badgeWith returns original widget when count <= 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Icon(Icons.notifications).badgeWith(0),
          ),
        ),
      );
      expect(find.byType(Badge), findsNothing);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('badgeWith shows maxCount+ when count exceeds maxCount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Icon(Icons.mail).badgeWith(150, maxCount: 99),
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('WidgetKeepAlive', () {
    testWidgets('keepAlive wraps widget in KeepAlive wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('keep').keepAlive,
          ),
        ),
      );
      expect(find.text('keep'), findsOneWidget);
    });
  });
}

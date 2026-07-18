import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/app_toast.dart';

Widget _scaffold({required VoidCallback onPressed}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: ElevatedButton(onPressed: onPressed, child: const Text('tap')),
    ),
  ),
);

void main() {
  group('AppToast', () {
    tearDown(AppToast.dismiss);

    testWidgets('show() presents a centered toast message', (tester) async {
      await tester.pumpWidget(_scaffold(onPressed: () {}));

      final context = tester.element(find.byType(Scaffold));
      AppToast.show(
        context,
        'hello world',
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(find.text('hello world'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
    });

    testWidgets('error() presents a toast', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      AppToast.error(
        ctx,
        'something went wrong',
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(find.text('something went wrong'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
    });

    testWidgets('success() presents a toast', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      AppToast.success(
        ctx,
        'saved!',
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(find.text('saved!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
    });

    testWidgets('warning() presents a toast', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      AppToast.warning(
        ctx,
        'check inputs',
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(find.text('check inputs'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
    });

    testWidgets('info() presents a toast', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      AppToast.info(
        ctx,
        'tap to learn more',
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(find.text('tap to learn more'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
    });

    testWidgets('toast auto dismisses after duration', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      AppToast.show(
        ctx,
        'temporary',
        duration: const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(find.text('temporary'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('temporary'), findsNothing);
    });
  });
}

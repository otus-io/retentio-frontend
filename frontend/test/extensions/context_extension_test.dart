import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';

/// Sets the test view's logical size so MediaQuery sees it. Prefer over
/// [TestWidgetsFlutterBinding.setSurfaceSize] which does not update the view
/// size that MediaQuery uses in some environments.
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
  group('ContextExtension media', () {
    testWidgets('size, width, height reflect MediaQuery', (tester) async {
      _setViewLogicalSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Use MediaQuery.size for Size assertion: BuildContext.size is the
              // layout size (invalid during build). Extension's size is shadowed.
              expect(MediaQuery.of(context).size, const Size(400, 800));
              expect(context.width, 400);
              expect(context.height, 800);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('blockSizeHorizontal and blockSizeVertical', (tester) async {
      _setViewLogicalSize(tester, const Size(100, 200));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.blockSizeHorizontal, 1.0);
              expect(context.blockSizeVertical, 2.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('shortestSide and orientation', (tester) async {
      _setViewLogicalSize(tester, const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.shortestSide, 300);
              expect(context.isPortrait, isTrue);
              expect(context.isLandscape, isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('devicePixelRatio and platformBrightness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.devicePixelRatio, greaterThan(0));
              expect(
                context.platformBrightness,
                anyOf(Brightness.light, Brightness.dark),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension theme', () {
    testWidgets('themeData and color getters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.blue),
          home: Builder(
            builder: (context) {
              expect(context.themeData.primaryColor, Colors.blue);
              expect(context.primaryColor, Colors.blue);
              expect(context.textTheme, isNotNull);
              expect(context.colorScheme, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isLightTheme reflects theme brightness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              expect(context.isLightTheme(), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension breakpoints', () {
    testWidgets('isXs when width < 576', (tester) async {
      _setViewLogicalSize(tester, const Size(400, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isXs, isTrue);
              expect(context.width, 400);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isSm when width in [576, 768)', (tester) async {
      _setViewLogicalSize(tester, const Size(600, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isSm, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isMd when width in [768, 992)', (tester) async {
      _setViewLogicalSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isMd, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isLg when width in [992, 1200)', (tester) async {
      _setViewLogicalSize(tester, const Size(1000, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isLg, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isXl when width in [1200, 1400)', (tester) async {
      _setViewLogicalSize(tester, const Size(1300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isXl, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isXXL when width >= 1400', (tester) async {
      _setViewLogicalSize(tester, const Size(1500, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isXXL, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension padding and insets', () {
    testWidgets('mediaQueryPadding and viewPadding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.mediaQueryPadding, isA<EdgeInsets>());
              expect(context.mediaQueryViewPadding, isA<EdgeInsets>());
              expect(context.mediaQueryViewInsets, isA<EdgeInsets>());
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension text theme', () {
    testWidgets('text theme getters return TextStyle or null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.displayLarge, isA<TextStyle?>());
              expect(context.bodyMedium, isA<TextStyle?>());
              expect(context.labelSmall, isA<TextStyle?>());
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension navigator', () {
    testWidgets('navigator returns NavigatorState', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.navigator, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension unFocus', () {
    testWidgets('unFocus does not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(() => context.unFocus(), returnsNormally);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ContextExtension loc', () {
    testWidgets('loc returns AppLocalizations when delegates provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              expect(context.loc, isA<AppLocalizations>());
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

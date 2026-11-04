import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/discovery/presentation/discovery_screen.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/routers/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retentio/screen/login/login_screen.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../helpers/in_memory_hydrated_storage.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    HydratedStorage.instance = InMemoryHydratedStorage();
  });

  tearDownAll(() {
    HydratedStorage.instance = null;
  });

  group('LoginScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('displays app name', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rete'), findsOneWidget);
    });

    testWidgets('displays username and password fields', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays login button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(4));
    });

    testWidgets('displays register button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      final loc = AppLocalizations.of(context)!;
      expect(find.text(loc.register), findsOneWidget);
    });

    testWidgets('displays forgot password link', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('password field is obscured', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // The second TextField is the password field
      final passwordField = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('can enter username', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'testuser');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('rejects whitespace inside the username', (tester) async {
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      final previous = networkDioClient.dio.httpClientAdapter;
      final adapter = _LoginRequestAdapter();
      networkDioClient.dio.httpClientAdapter = adapter;
      addTearDown(() {
        networkDioClient.dio.httpClientAdapter = previous;
      });

      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a b');
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(adapter.usernames, isEmpty);
      expect(find.text('Username must not contain whitespace'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('submits a short username and password', (tester) async {
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      final previous = networkDioClient.dio.httpClientAdapter;
      final adapter = _LoginRequestAdapter();
      networkDioClient.dio.httpClientAdapter = adapter;
      addTearDown(() {
        networkDioClient.dio.httpClientAdapter = previous;
      });

      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a');
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(adapter.usernames, ['a']);
      expect(adapter.passwords, ['short']);
      expect(find.text('Password must be at least 8 characters'), findsNothing);
      expect(
        find.text('Username must be between 2 and 32 characters'),
        findsNothing,
      );
      expect(find.text('Invalid username or password'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('can enter password', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.pump();

      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets('theme toggle offers light mode on the dark default', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to light mode'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to light mode'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    });

    testWidgets('has language dropdown', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<Locale>), findsOneWidget);
    });

    testWidgets('displays browse discovery entry', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('or'), findsOneWidget);
      expect(find.text('Browse public decks'), findsOneWidget);
      expect(find.byIcon(LucideIcons.compass), findsOneWidget);
    });

    testWidgets('browse discovery opens the discovery route', (tester) async {
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      final previous = networkDioClient.dio.httpClientAdapter;
      networkDioClient.dio.httpClientAdapter = _DelayedErrorAdapter();
      addTearDown(() {
        networkDioClient.dio.httpClientAdapter = previous;
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppPages.routes,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Browse public decks'));
      await tester.tap(find.text('Browse public decks'));
      await tester.pumpAndSettle();

      expect(find.byType(DiscoveryScreen), findsOneWidget);
    });

    testWidgets('browse discovery is disabled while logging in', (
      tester,
    ) async {
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      final previous = networkDioClient.dio.httpClientAdapter;
      networkDioClient.dio.httpClientAdapter = _DelayedErrorAdapter(
        delay: const Duration(seconds: 1),
      );
      addTearDown(() {
        networkDioClient.dio.httpClientAdapter = previous;
      });

      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      AppButton browseButton() => tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Browse public decks'),
      );
      expect(browseButton().onPressed, isNotNull);

      await tester.enterText(find.byType(TextField).first, 'a');
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(browseButton().onPressed, isNull);

      await tester.pump(const Duration(seconds: 9));
      await tester.pump(const Duration(milliseconds: 300));
      expect(browseButton().onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}

class _DelayedErrorAdapter implements HttpClientAdapter {
  _DelayedErrorAdapter({this.delay = Duration.zero});

  final Duration delay;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => Future.delayed(
    delay,
    () => ResponseBody.fromString(
      jsonEncode({
        'code': -1,
        'msg': 'Invalid username or password',
        'data': null,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );

  @override
  void close({bool force = false}) {}
}

class _LoginRequestAdapter implements HttpClientAdapter {
  final usernames = <String>[];
  final passwords = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : <String, dynamic>{};
    usernames.add(body['username']?.toString() ?? '');
    passwords.add(body['password']?.toString() ?? '');
    return ResponseBody.fromString(
      jsonEncode({
        'code': -1,
        'msg': 'Invalid username or password',
        'data': null,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

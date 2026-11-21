import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/screen/profile/profile_settings_dialogs.dart';

import '../../helpers/test_wrapper.dart';

class _Offline extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.reject(DioException(requestOptions: options));
}

class _FakeProfileCubit extends ProfileCubit {
  final calls = <(String, String)>[];
  late Completer<String?> result;

  @override
  Future<void> getProfile() async {}

  @override
  Future<String?> changeEmail(String email, String password) {
    calls.add((email, password));
    return result.future;
  }
}

void main() {
  late _FakeProfileCubit cubit;

  setUp(() async {
    await setupTestEnvironment();
    networkDioClient.dio.interceptors.add(_Offline());
    cubit = _FakeProfileCubit();
  });

  tearDown(() async {
    await cubit.close();
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<void> open(WidgetTester tester) async {
    cubit.result = Completer<String?>();
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showProfileChangeEmailDialog(context, cubit),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(int i) => find
      .descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      )
      .at(i);

  Finder submitButton() => find.widgetWithText(FilledButton, 'Change email');

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(submitButton()).onPressed != null;

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(field(0), email);
    await tester.enterText(field(1), password);
    await tester.pump();
  }

  testWidgets('submit stays disabled until both fields are filled', (
    tester,
  ) async {
    await open(tester);
    expect(submitEnabled(tester), isFalse);

    await tester.enterText(field(0), 'new@example.com');
    await tester.pump();
    expect(submitEnabled(tester), isFalse);

    await tester.enterText(field(1), 'secret');
    await tester.pump();
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('cancel closes without changing anything', (tester) async {
    await open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(cubit.calls, isEmpty);
  });

  testWidgets('success closes the dialog and confirms the new address', (
    tester,
  ) async {
    await open(tester);
    await fill(tester, '  new@example.com ', 'secret');

    await tester.tap(submitButton());
    await tester.pump();
    cubit.result.complete(null);
    await tester.pumpAndSettle();

    expect(cubit.calls, [('new@example.com', 'secret')]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text(
        'Check new@example.com for a confirmation link. '
        'Your email changes when you open it.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('wrong password shows the error under the password field', (
    tester,
  ) async {
    await open(tester);
    await fill(tester, 'new@example.com', 'wrong');

    await tester.tap(submitButton());
    cubit.result.complete('Invalid credentials');
    await tester.pumpAndSettle();

    expect(find.text('Incorrect password'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(field(1), 'wrong2');
    await tester.pump();
    expect(find.text('Incorrect password'), findsNothing);
  });

  testWidgets('rate limit shows the error under the password field', (
    tester,
  ) async {
    await open(tester);
    await fill(tester, 'new@example.com', 'wrong');

    await tester.tap(submitButton());
    cubit.result.complete('Too many attempts. Try again later.');
    await tester.pumpAndSettle();

    final passwordInput = tester.widget<TextField>(field(1));
    expect(
      passwordInput.decoration?.errorText,
      'Too many attempts. Please try again later.',
    );
    expect(tester.widget<TextField>(field(0)).decoration?.errorText, isNull);
  });

  testWidgets('email errors show under the email field and clear on edit', (
    tester,
  ) async {
    await open(tester);
    await fill(tester, 'taken@example.com', 'secret');

    await tester.tap(submitButton());
    cubit.result.complete('Email already in use');
    await tester.pumpAndSettle();

    expect(find.text('Email is already in use'), findsOneWidget);

    await tester.enterText(field(0), 'other@example.com');
    await tester.pump();
    expect(find.text('Email is already in use'), findsNothing);
  });

  testWidgets('unexpected failure shows the fallback error', (tester) async {
    await open(tester);
    await fill(tester, 'new@example.com', 'secret');

    await tester.tap(submitButton());
    cubit.result.completeError(StateError('boom'));
    await tester.pumpAndSettle();

    expect(find.text('An unexpected error occurred'), findsOneWidget);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('a result after the dialog closes is ignored', (tester) async {
    await open(tester);
    await fill(tester, 'new@example.com', 'secret');

    await tester.tap(submitButton());
    await tester.pump();
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    cubit.result.complete('Invalid credentials');
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}

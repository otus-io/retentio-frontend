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
  final passwords = <String>[];
  late Completer<String?> result;
  int logouts = 0;

  @override
  Future<void> getProfile() async {}

  @override
  Future<String?> deleteAccount(String password) {
    passwords.add(password);
    return result.future;
  }

  @override
  Future<void> logout() async => logouts++;
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
            onPressed: () => showProfileDeleteAccountDialog(context, cubit),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder deleteButton() => find.widgetWithText(FilledButton, 'Delete account');

  bool deleteEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(deleteButton()).onPressed != null;

  testWidgets('delete stays disabled until a password is entered', (
    tester,
  ) async {
    await open(tester);

    expect(deleteEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    expect(deleteEnabled(tester), isTrue);
  });

  testWidgets('cancel closes without deleting', (tester) async {
    await open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(cubit.passwords, isEmpty);
    expect(cubit.logouts, 0);
  });

  testWidgets('success closes the dialog and logs out', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();

    await tester.tap(deleteButton());
    await tester.pump();
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    expect(tester.widget<TextButton>(cancel).onPressed, isNull);

    cubit.result.complete(null);
    await tester.pumpAndSettle();

    expect(cubit.passwords, ['secret']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(cubit.logouts, 1);
  });

  testWidgets('wrong password shows an inline error and allows retry', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();

    await tester.tap(deleteButton());
    cubit.result.complete('Invalid credentials');
    await tester.pumpAndSettle();

    expect(find.text('Incorrect password'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(deleteEnabled(tester), isTrue);
    expect(cubit.logouts, 0);

    // Error clears as the user re-types the corrected password.
    await tester.enterText(find.byType(TextField), 'wrong2');
    await tester.pump();
    expect(find.text('Incorrect password'), findsNothing);
  });

  testWidgets('other errors use the shared API messages', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();

    await tester.tap(deleteButton());
    cubit.result.complete('Too many delete attempts. Try again later.');
    await tester.pumpAndSettle();

    expect(
      find.text('Too many attempts. Please try again later.'),
      findsOneWidget,
    );
    expect(cubit.logouts, 0);
  });
}

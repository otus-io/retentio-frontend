import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/screen/register/register_screen.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../helpers/test_wrapper.dart';

class _RegisterApi extends Interceptor {
  _RegisterApi(this.msg);

  /// Null answers 200 with a non-object body, which the client cannot parse.
  final String? msg;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (msg == null) {
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: ['x']),
      );
      return;
    }
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {'msg': msg},
        ),
      ),
    );
  }
}

void main() {
  setUp(setupTestEnvironment);

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<void> register(WidgetTester tester, String? serverMsg) async {
    networkDioClient.dio.interceptors.add(_RegisterApi(serverMsg));
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(const RegisterScreen()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'taken@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'alice');
    await tester.enterText(find.byType(TextField).at(2), 'secret123');
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.tap(find.widgetWithText(AppButton, 'Register'));
    await tester.pumpAndSettle();
  }

  testWidgets('an unreadable response still shows an error', (tester) async {
    await register(tester, null);

    expect(find.textContaining('is not a subtype'), findsOneWidget);
    expect(find.textContaining('Check your email'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('other conflicts keep the shared message', (tester) async {
    await register(tester, 'Username already exists');

    expect(find.text('Username is already taken'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}

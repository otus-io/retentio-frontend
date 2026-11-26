import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/l10n/app_localizations_en.dart';
import 'package:retentio/screen/verify_email/verify_email_screen.dart';

import '../../helpers/test_wrapper.dart';

/// Answers POST /auth/verify-email with [respond].
class _VerifyInterceptor extends Interceptor {
  _VerifyInterceptor(this.respond);

  final void Function(RequestOptions, RequestInterceptorHandler) respond;
  int calls = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'POST' &&
        options.uri.path.endsWith('/auth/verify-email')) {
      calls++;
      respond(options, handler);
      return;
    }
    handler.next(options);
  }
}

void _reject(
  RequestOptions options,
  RequestInterceptorHandler handler,
  String msg, {
  int statusCode = 400,
}) {
  handler.reject(
    DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: statusCode,
        data: {'msg': msg},
      ),
    ),
  );
}

void main() {
  final en = AppLocalizationsEn();
  _VerifyInterceptor? interceptor;

  setUpAll(setupTestEnvironment);
  tearDownAll(tearDownTestEnvironment);
  tearDown(() {
    if (interceptor != null) {
      networkDioClient.dio.interceptors.remove(interceptor);
    }
    interceptor = null;
  });

  Future<void> pumpWith(
    WidgetTester tester,
    void Function(RequestOptions, RequestInterceptorHandler) respond,
  ) async {
    interceptor = _VerifyInterceptor(respond);
    networkDioClient.dio.interceptors.add(interceptor!);
    await tester.pumpWidget(
      buildTestableWidget(const VerifyEmailScreen(token: 'tok')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows success and no retry when the link verifies', (
    tester,
  ) async {
    await pumpWith(tester, (options, handler) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {'msg': 'Email verified successfully'},
          },
        ),
      );
    });

    expect(find.text(en.verifyEmailSuccess), findsWidgets);
    expect(find.text(en.retry), findsNothing);
    // let the success snack's timer finish
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a used link explains itself and hides retry', (tester) async {
    await pumpWith(
      tester,
      (options, handler) =>
          _reject(options, handler, 'Invalid or expired verification token'),
    );

    expect(find.text(en.verifyEmailLinkUsed), findsOneWidget);
    expect(find.text(en.retry), findsNothing);
    expect(find.text(en.backToLogin), findsOneWidget);
  });

  testWidgets('a link for a deleted account explains itself and hides retry', (
    tester,
  ) async {
    await pumpWith(
      tester,
      (options, handler) =>
          _reject(options, handler, 'User not found for verification token'),
    );

    expect(find.text(en.verifyEmailLinkUsed), findsOneWidget);
    expect(find.text(en.retry), findsNothing);
  });

  testWidgets('other API errors keep retry, which calls the API again', (
    tester,
  ) async {
    await pumpWith(
      tester,
      (options, handler) =>
          _reject(options, handler, 'Error verifying email', statusCode: 500),
    );

    expect(find.text(en.verifyEmailLinkUsed), findsNothing);
    expect(find.text(en.retry), findsOneWidget);

    await tester.tap(find.text(en.retry));
    await tester.pumpAndSettle();
    expect(interceptor!.calls, 2);
    expect(find.text(en.retry), findsOneWidget);
  });

  testWidgets('an unexpected response body shows an error with retry', (
    tester,
  ) async {
    await pumpWith(tester, (options, handler) {
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: ['not a map']),
      );
    });

    expect(find.text(en.verifyEmailLinkUsed), findsNothing);
    expect(find.text(en.retry), findsOneWidget);
  });
}

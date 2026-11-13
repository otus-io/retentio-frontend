import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/discovery/presentation/discovery_screen.dart';
import 'package:retentio/l10n/app_localizations_en.dart';

import '../../helpers/test_wrapper.dart';

/// Rejects every request with [error] built from its options.
class _FailingApi extends Interceptor {
  _FailingApi(this.error);

  final DioException Function(RequestOptions) error;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.reject(error(options));
}

void main() {
  final loc = AppLocalizationsEn();

  setUp(setupTestEnvironment);

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<void> pumpWith(
    WidgetTester tester,
    DioException Function(RequestOptions) error,
  ) async {
    networkDioClient.dio.interceptors.add(_FailingApi(error));
    await tester.pumpWidget(buildTestableWidget(const DiscoveryScreen()));
    await tester.pumpAndSettle();
  }

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  ]) {
    testWidgets('${type.name} says offline study still works', (tester) async {
      await pumpWith(
        tester,
        (options) => DioException(requestOptions: options, type: type),
      );

      expect(find.text(loc.discoveryOffline), findsOneWidget);
      expect(find.text(loc.discoveryEmpty), findsNothing);
    });
  }

  testWidgets('retry shows a spinner and loads again', (tester) async {
    var requests = 0;
    await pumpWith(tester, (options) {
      requests++;
      return DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    final before = requests;

    await tester.tap(find.text(loc.discoveryRetry));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(loc.discoveryOffline), findsNothing);

    await tester.pumpAndSettle();

    expect(requests, before + 1);
    expect(find.text(loc.discoveryOffline), findsOneWidget);
  });

  testWidgets('a server error keeps its own message', (tester) async {
    await pumpWith(
      tester,
      (options) => DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 500,
          data: {'msg': 'Error retrieving deck'},
        ),
      ),
    );

    expect(find.text(loc.apiServerRetrieveDeck), findsOneWidget);
    expect(find.text(loc.discoveryOffline), findsNothing);
  });
}

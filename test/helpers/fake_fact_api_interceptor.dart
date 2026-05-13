import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Intercepts GET/PATCH `/facts/{factId}` for [EditFactWidget] tests (no real server).
class FakeFactApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri.toString();
    if (options.method == 'GET' && uri.contains('/facts/')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'data': {
              'fact': {
                'id': 'fact-test-1',
                'entries': [
                  {'text': 'Alpha'},
                  {'text': 'Beta'},
                ],
                'fields': ['FieldA', 'FieldB'],
              },
            },
          },
        ),
      );
      return;
    }
    if (options.method == 'PATCH' && uri.contains('/facts/')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'data': {'fact_id': 'fact-test-1'},
          },
        ),
      );
      return;
    }
    handler.next(options);
  }
}

/// Register [FakeFactApiInterceptor] on the shared [networkDioClient]. Call [remove] in tearDown.
Interceptor attachFakeFactApiInterceptor() {
  final i = FakeFactApiInterceptor();
  networkDioClient.dio.interceptors.add(i);
  return i;
}

void detachFakeFactApiInterceptor(Interceptor i) {
  networkDioClient.dio.interceptors.remove(i);
}

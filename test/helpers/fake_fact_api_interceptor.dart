import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Intercepts fact load/update/add API calls for [FactEdit] / [FactAdd] tests.
class FakeFactApiInterceptor extends Interceptor {
  int getFactCount = 0;
  int patchFactCount = 0;
  int addFactsCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri.toString();

    if (options.method == 'POST' && uri.contains('/facts/append')) {
      addFactsCount++;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {'facts_added': 1},
          },
        ),
      );
      return;
    }

    if (options.method == 'GET' && uri.contains('/facts/')) {
      getFactCount++;
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
      patchFactCount++;
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

FakeFactApiInterceptor attachFakeFactApiInterceptor() {
  final interceptor = FakeFactApiInterceptor();
  networkDioClient.dio.interceptors.add(interceptor);
  return interceptor;
}

void detachFakeFactApiInterceptor(FakeFactApiInterceptor interceptor) {
  networkDioClient.dio.interceptors.remove(interceptor);
}

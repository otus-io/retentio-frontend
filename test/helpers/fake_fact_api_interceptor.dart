import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Intercepts fact load/update/add API calls for [FactEdit] / [FactAdd] tests.
class FakeFactApiInterceptor extends Interceptor {
  FakeFactApiInterceptor({
    List<Map<String, dynamic>>? factEntries,
    this.mediaVersions,
  }) : factEntries = factEntries ?? _defaultFactEntries;

  static const _defaultFactEntries = <Map<String, dynamic>>[
    {'text': 'Alpha'},
    {'text': 'Beta'},
  ];

  final List<Map<String, dynamic>> factEntries;

  /// Snapshot `media_versions` for the GET fact response (omitted when null).
  final Map<String, int>? mediaVersions;

  int getFactCount = 0;
  int patchFactCount = 0;
  int addFactsCount = 0;
  dynamic lastPatchData;

  /// Completes a test wait when the fact PATCH is handled.
  void Function()? onPatch;

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
              'fact': {'id': 'fact-test-1', 'entries': factEntries},
              'media_versions': ?mediaVersions,
            },
          },
        ),
      );
      return;
    }

    if (options.method == 'PATCH' && uri.contains('/facts/')) {
      patchFactCount++;
      lastPatchData = options.data;
      onPatch?.call();
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

FakeFactApiInterceptor attachFakeFactApiInterceptor({
  List<Map<String, dynamic>>? factEntries,
  Map<String, int>? mediaVersions,
}) {
  final interceptor = FakeFactApiInterceptor(
    factEntries: factEntries,
    mediaVersions: mediaVersions,
  );
  networkDioClient.dio.interceptors.add(interceptor);
  return interceptor;
}

void detachFakeFactApiInterceptor(FakeFactApiInterceptor interceptor) {
  networkDioClient.dio.interceptors.remove(interceptor);
}

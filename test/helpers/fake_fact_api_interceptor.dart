import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Intercepts fact load/update/add API calls for [FactEdit] / [FactAdd] tests.
class FakeFactApiInterceptor extends Interceptor {
  FakeFactApiInterceptor({
    List<Map<String, dynamic>>? factEntries,
    this.mediaVersions,
    this.factTags = const [],
    this.contributionEditFails = false,
    this.contributionTagsFails = false,
  }) : factEntries = factEntries ?? _defaultFactEntries;

  static const _defaultFactEntries = <Map<String, dynamic>>[
    {'text': 'Alpha'},
    {'text': 'Beta'},
  ];

  final List<Map<String, dynamic>> factEntries;

  /// Snapshot `media_versions` for the GET fact response (omitted when null).
  final Map<String, int>? mediaVersions;

  /// Tags returned by `GET …/facts/{factId}/tags`.
  final List<Map<String, dynamic>> factTags;

  int getFactCount = 0;
  int patchFactCount = 0;
  int addFactsCount = 0;
  int contributionEditCount = 0;
  int contributionTagsCount = 0;
  dynamic lastPatchData;
  dynamic lastContributionEditBody;
  bool contributionEditFails;
  bool contributionTagsFails;

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

    if (options.method == 'POST' &&
        uri.contains('/contributions/facts/') &&
        uri.endsWith('/edit')) {
      contributionEditCount++;
      lastContributionEditBody = options.data;
      if (contributionEditFails) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 429,
            data: {'code': 429, 'msg': 'daily contribution limit exceeded'},
          ),
        );
        return;
      }
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'code': 0,
            'msg': 'contribution submitted',
            'data': {
              'contribution_id': 'cont-edit-1',
              'type': 'fact_edit',
              'status': 'open',
            },
          },
        ),
      );
      return;
    }

    if (options.method == 'POST' &&
        uri.contains('/contributions/facts/') &&
        uri.endsWith('/tags')) {
      contributionTagsCount++;
      if (contributionTagsFails) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 429,
            data: {'code': 429, 'msg': 'daily contribution limit exceeded'},
          ),
        );
        return;
      }
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'code': 0,
            'msg': 'contribution submitted',
            'data': {
              'contribution_id': 'cont-tags-1',
              'type': 'fact_tag_update',
              'status': 'open',
            },
          },
        ),
      );
      return;
    }

    if (options.method == 'GET' &&
        uri.contains('/facts/') &&
        uri.endsWith('/tags')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'data': {'tags': factTags},
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
  List<Map<String, dynamic>> factTags = const [],
  bool contributionEditFails = false,
  bool contributionTagsFails = false,
}) {
  final interceptor = FakeFactApiInterceptor(
    factEntries: factEntries,
    mediaVersions: mediaVersions,
    factTags: factTags,
    contributionEditFails: contributionEditFails,
    contributionTagsFails: contributionTagsFails,
  );
  networkDioClient.dio.interceptors.add(interceptor);
  return interceptor;
}

void detachFakeFactApiInterceptor(FakeFactApiInterceptor interceptor) {
  networkDioClient.dio.interceptors.remove(interceptor);
}

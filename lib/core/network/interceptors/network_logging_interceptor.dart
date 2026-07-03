import 'package:dio/dio.dart';
import 'package:retentio/core/network/dio_error_log.dart';
import 'package:retentio/utils/log.dart';

Map<String, Object?> _headersForLog(Map<String, dynamic>? headers) {
  if (headers == null || headers.isEmpty) {
    return const {};
  }
  const sensitiveKeys = {'authorization', 'cookie', 'set-cookie'};
  final out = <String, Object?>{};
  for (final e in headers.entries) {
    final k = e.key;
    if (sensitiveKeys.contains(k.toLowerCase())) {
      out[k] = '<redacted>';
    } else {
      out[k] = e.value;
    }
  }
  return out;
}

class NetworkLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d({
      'oRequest method': options.method,
      'oRequest url': options.uri,
      'oRequest header': _headersForLog(options.headers),
      'onRequest params': options.queryParameters,
      'onRequest data': options.data,
    });
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    logger.d({
      'Request': response.requestOptions.uri.toString(),
      'Response': loggableResponseData(response.data),
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logDioError('NetworkLoggingInterceptor.onError', err);
    handler.next(err);
  }
}

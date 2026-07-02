import 'package:dio/dio.dart';
import 'package:retentio/utils/log.dart';

/// Builds a compact, scannable error map from a [DioException] that surfaces the
/// HTTP status code and the server-provided `msg`/`message` so the exact failure
/// (e.g. a specific 400) is visible without parsing the full DioException text.
Map<String, Object?> buildDioErrorLog(DioException err) {
  final response = err.response;
  final data = response?.data;

  String? serverMsg;
  if (data is Map) {
    serverMsg = (data['msg'] ?? data['message'])?.toString();
  } else if (data is String && data.isNotEmpty) {
    serverMsg = data;
  }

  return {
    'method': err.requestOptions.method,
    'url': err.requestOptions.uri.toString(),
    'dio_type': err.type.name,
    'status_code': response?.statusCode,
    'server_msg': serverMsg,
    'response_body': data,
  };
}

void logDioError(String source, DioException err) {
  logger.e({source: buildDioErrorLog(err)});
}

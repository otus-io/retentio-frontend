import 'package:dio/dio.dart';
import 'package:retentio/utils/log.dart';

/// Returns a log-safe representation of a response body: long strings are
/// summarized by length and binary [ResponseBody] payloads are omitted, so large
/// or non-text bodies never get dumped in full.
Object loggableResponseData(dynamic data) {
  if (data == null) return 'null';
  if (data is Map || data is List) return data;
  if (data is String) {
    final n = data.length;
    return n > 256 ? 'String(length=$n)' : data;
  }
  if (data is ResponseBody) {
    return 'ResponseBody (binary, omitted)';
  }
  return '${data.runtimeType}';
}

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
    'response_body': loggableResponseData(data),
  };
}

void logDioError(String source, DioException err) {
  logger.e({source: buildDioErrorLog(err)});
}

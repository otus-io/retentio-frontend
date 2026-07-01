import 'package:dio/dio.dart';
import 'package:retentio/models/api_response.dart';

ApiResponse mapDioExceptionToApiResponse(DioException e) {
  const typeMessageMap = <DioExceptionType, String>{
    DioExceptionType.connectionTimeout: 'Connect timeout',
    DioExceptionType.connectionError: 'Connect error',
    DioExceptionType.badCertificate: 'Bad certificate',
    DioExceptionType.sendTimeout: 'Send timeout',
    DioExceptionType.receiveTimeout: 'Receive timeout',
    DioExceptionType.transformTimeout: 'Transform timeout',
    DioExceptionType.badResponse: 'Bad response',
    DioExceptionType.cancel: 'Request cancel',
  };
  var msg = typeMessageMap[e.type] ?? e.message ?? 'Unknown error';

  final body = e.response?.data;
  if (body is Map) {
    final serverMsg = body['msg'] ?? body['message'];
    if (serverMsg != null && serverMsg.toString().isNotEmpty) {
      msg = serverMsg.toString();
    }
  }

  return ApiResponse(msg: msg, exception: e, code: -1);
}

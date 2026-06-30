import 'package:dio/dio.dart';
import 'package:retentio/models/api_response.dart';

ApiResponse mapDioExceptionToApiResponse(DioException e) {
  var msg = 'Unknown error';
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      msg = 'Connect timeout';
      break;
    case DioExceptionType.connectionError:
      msg = 'Connect error';
      break;
    case DioExceptionType.badCertificate:
      msg = 'Bad certificate';
      break;
    case DioExceptionType.sendTimeout:
      msg = 'Send timeout';
      break;
    case DioExceptionType.receiveTimeout:
      msg = 'Receive timeout';
      break;
    case DioExceptionType.transformTimeout:
      msg = 'Transform timeout';
      break;
    case DioExceptionType.badResponse:
      msg = 'Bad response';
      break;
    case DioExceptionType.cancel:
      msg = 'Request cancel';
      break;
    case DioExceptionType.unknown:
      msg = e.message ?? 'Unknown error';
      break;
  }

  final body = e.response?.data;
  if (body is Map) {
    final serverMsg = body['msg'] ?? body['message'];
    if (serverMsg != null && serverMsg.toString().isNotEmpty) {
      msg = serverMsg.toString();
    }
  }

  return ApiResponse(msg: msg, exception: e, code: -1);
}

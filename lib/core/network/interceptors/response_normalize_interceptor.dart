import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:retentio/core/network/dio_error_log.dart';
import 'package:retentio/services/apis/api_service.dart';

class ResponseNormalizeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var data = response.data ?? <String, dynamic>{};
    if (data is String) {
      data = jsonDecode(data);
    }
    handler.next(response..data = data);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logDioError('ResponseNormalizeInterceptor.onError', err);

    if (err.response?.statusCode == 401) {
      ApiService.handle401Unauthorized();
    }

    handler.next(err);
  }
}

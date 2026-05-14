import 'package:dio/dio.dart';
import 'package:retentio/services/apis/api_service.dart';

class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers = ApiService.buildHeaders(options.headers);
    handler.next(options);
  }
}

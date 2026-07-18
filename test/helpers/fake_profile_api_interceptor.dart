import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Intercepts profile API calls for [ProfileScreen] widget tests.
class FakeProfileApiInterceptor extends Interceptor {
  int getProfileCount = 0;

  static bool _isProfilePath(String path) {
    return path == '/api/profile' || path.endsWith('/api/profile');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;

    if (options.method == 'GET' && _isProfilePath(path)) {
      getProfileCount++;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {'email': 'test@example.com', 'username': 'tester'},
          },
        ),
      );
      return;
    }

    handler.next(options);
  }
}

FakeProfileApiInterceptor attachFakeProfileApiInterceptor() {
  final interceptor = FakeProfileApiInterceptor();
  networkDioClient.dio.interceptors.add(interceptor);
  return interceptor;
}

void detachFakeProfileApiInterceptor(FakeProfileApiInterceptor interceptor) {
  networkDioClient.dio.interceptors.remove(interceptor);
}

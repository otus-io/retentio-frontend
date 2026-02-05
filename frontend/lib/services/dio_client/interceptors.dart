
part of services;

/// 请求拦截器
class HttpHeaderInterceptors extends InterceptorsWrapper {
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    //final cusToken = options.headers["user-token"] as String? ?? '';
    // if (cusToken.isEmpty) {
    //   options.headers['user-token'] = StorageService.of.getToken();
    // }
    // options.headers['device-id'] = DevicesUtil.of.deviceID;
    // options.headers = {
    //   ...options.headers,
    //   ...DevicesUtil.of.headerJson,
    //   ...AppUtil.of.headerJson,
    //   ...LocationUtil.headerJson,
    // };
    super.onRequest(options, handler);
  }
}

/// 日志拦截器
class LogInterceptors extends InterceptorsWrapper {
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    logger.d({
      "oRequest url": options.uri,
      "oRequest header": options.headers,
      "onRequest params": options.queryParameters,
      "onRequest data": options.data
    });
    super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    // if (response.data is Map) {
    logger.d({"Request": response.requestOptions.path, "Response": response.data});
    // }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e({"onError":{"err_url": err.requestOptions.uri,"err_type": err.type,"err_message": err}});
    super.onError(err, handler);
  }
}

/// 响应拦截器
class ResponseInterceptors extends InterceptorsWrapper {
  final _debounce = DebounceUtil(milliseconds: 300);

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    // 兼容 null data
    var data = response.data ?? <String, dynamic>{};
    if (data is String) {
      data = jsonDecode(data);
    }
    if ((data is Map) &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      final dynamic code = data['code'];
      final String msg = data['msg'] ?? '';

      if (code == 401) {
        ApiService.handle401Unauthorized();
      } else if (code != 0 && code != 60001001 && msg.isNotEmpty) {
       // DialogUtil.showToast(msg);
      }
    }
    super.onResponse(response..data = data, handler);
  }
}

class ProxyInterceptor {
  static HttpClient interceptor() {
    final client = HttpClient();
    if (!Env.isProxy) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
      Env.useBadCertificate;
      return client;
    }

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return Env.useBadCertificate;
    };

    client.findProxy = (uri) {
      if (!Env.isProxy) {
        return "DIRECT";
      }
      return "PROXY ${Env.httpProxyHost}:${Env.httpProxyPort}";
    };

    return client;
  }
}

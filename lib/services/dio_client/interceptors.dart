part of '../index.dart';

/// 请求拦截器
class HttpHeaderInterceptors extends InterceptorsWrapper {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers = ApiService.buildHeaders(options.headers);
    //     if (_token != null) 'Authorization': 'Bearer $_token',
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

Object _loggableResponseData(dynamic data) {
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

/// Copy of request headers safe for logs (never log bearer tokens or cookies).
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

/// 日志拦截器
class LogInterceptors extends InterceptorsWrapper {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d({
      "oRequest method": options.method,
      "oRequest url": options.uri,
      "oRequest header": _headersForLog(options.headers),
      "onRequest params": options.queryParameters,
      "onRequest data": options.data,
    });
    super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    logger.d({
      "Request": response.requestOptions.uri.toString(),
      "Response": _loggableResponseData(response.data),
    });
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e({
      "onError": {
        "err_url": err.requestOptions.uri,
        "err_type": err.type,
        "err_message": err,
      },
    });
    super.onError(err, handler);
  }
}

/// 响应拦截器
class ResponseInterceptors extends InterceptorsWrapper {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 兼容 null data
    var data = response.data ?? <String, dynamic>{};
    if (data is String) {
      data = jsonDecode(data);
    }

    super.onResponse(response..data = data, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e({
      "onError": {
        "err_url": err.requestOptions.uri,
        "err_type": err.type,
        "err_message": err,
      },
    });

    if (err.response?.statusCode == 401) {
      ApiService.handle401Unauthorized();
    }

    super.onError(err, handler);
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

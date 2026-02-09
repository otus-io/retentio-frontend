part of '../index.dart';

/// Created on 2026/2/5
/// Description:

DioClient dioClient = DioClient.of;

class DioClient {
  static final DioClient of = DioClient._();
  bool _didConfig = false;

  Dio get dio => _dio;
  final Dio _dio = Dio();

  final _connectTimeout = const Duration(minutes: 1);
  final _receiveTimeout = const Duration(minutes: 1);
  final _sendTimeout = const Duration(minutes: 1);

  DioClient._();

  void config(
    String baseUrl, {
    List<Interceptor>? interceptors,
    BaseOptions? options,
    HttpClient Function()? proxyInterceptor,
  }) {
    if (options != null) {
      _dio.options = options;
    } else {
      final BaseOptions options = BaseOptions(
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        contentType: Headers.jsonContentType,
      );
      _dio.options = options;

      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          _createHttpClient;
    }
    _dio.options.baseUrl = baseUrl;
    if (proxyInterceptor != null) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          proxyInterceptor;
    }
    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }
    _dio.transformer = BackgroundTransformer();
    _didConfig = true;
  }

  /// GET 请求
  Future<ResBaseModel?> get(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? pathParams,
    Options? options,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    url = _buildFinalUrl(url, pathParams);
    print('GET request to: $url');
    try {
      response = params == null
          ? await _dio.get(url, options: options)
          : await _dio.get(url, queryParameters: params, options: options);

      return ResBaseModel.fromJson(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// 构建最终的URL（处理RESTful参数）
  String _buildFinalUrl(String path, Map<String, dynamic>? pathParams) {
    // 如果路径包含占位符，自动进行RESTful替换
    if (pathParams != null && _hasRestfulPlaceholders(path)) {
      final pathParamsCopy = Map<String, dynamic>.from(pathParams);
      path = _restfulUrl(path, pathParamsCopy);
    }

    return path;
  }

  /// restful处理 - Retrofit style
  String _restfulUrl(String url, Map<String, dynamic> params) {
    String resultUrl = url;
    List<String> keysToRemove = [];

    params.forEach((key, value) {
      String placeholder = "{$key}";
      if (resultUrl.contains(placeholder)) {
        resultUrl = resultUrl.replaceAll(
          placeholder,
          Uri.encodeComponent(value.toString()),
        );
        keysToRemove.add(key);
      }
    });

    /// 从 params Map 中移除已用于路径替换的键
    for (String key in keysToRemove) {
      params.remove(key);
    }
    ///在替换后规范化斜杠，避免将http://转换为http:/
    int schemeEndIndex = resultUrl.indexOf("://");
    String scheme = "";
    String rest = resultUrl;

    if (schemeEndIndex != -1) {
      scheme = resultUrl.substring(0, schemeEndIndex + 3);
      rest = resultUrl.substring(schemeEndIndex + 3);
    }

    rest = rest.replaceAll(RegExp(r'/+'), '/');
    return scheme + rest;
  }

  /// 检测路径是否包含RESTful占位符
  bool _hasRestfulPlaceholders(String path) {
    return path.contains(RegExp(r'\{[^}]+\}')) ?? false;
  }

  /// GET 请求
  Future<Uint8List?> getImageUint8ListFrom(String url) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    try {
      final response = await _dio.get<Uint8List?>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  /// POST 请求
  Future<ResBaseModel?> post(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? pathParams,
    Options? options,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    url = _buildFinalUrl(url, pathParams);
    try {
      response = await _dio.post(url, data: params, options: options);

      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ResBaseModel.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST 请求
  Future<Map<String, dynamic>?> postGame(
    String url, {
    Map<String, dynamic>? params,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    try {
      response = await _dio.post(url, data: params);

      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return res;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// POST 请求
  Future<ResBaseModel?> postObj(String url, {dynamic params}) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    try {
      response = await _dio.post(url, data: params);

      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ResBaseModel.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST Form
  Future<ResBaseModel?> postForm(
    String url, {
    Map<String, dynamic>? params,
    Options? options,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    try {
      response = await _dio.post(
        url,
        queryParameters: params,
        options: (options ?? Options()).copyWith(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ResBaseModel.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST 请求
  Future<ResBaseModel?> uploadFile(
    String url, {
    required String filePath,
    String? fileName,
    String? contentType,
    void Function(int count, int total)? onSendProgress,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: (contentType == null || contentType.isEmpty)
            ? null
            : DioMediaType.parse(contentType),
      ),
    });
    try {
      response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ResBaseModel.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST 请求
  Future<ResBaseModel?> uploadBytes(
    String url, {
    required Uint8List bytes,
    required String fileName,
    required String moduleName,
    void Function(int count, int total)? onSendProgress,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');
    Response response;
    final formData = FormData.fromMap({
      'module': moduleName,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    try {
      response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
      );
      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ResBaseModel.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// 下载资源
  Future<String> downLoadFile(
    String downloadURL,
    String downloadPath,
    ValueChanged<double> onProgress,
    Function() onError, {
    CancelToken? cancelToken,
  }) async {
    assert(_didConfig, 'Please call Dioclient.config(...) first.');

    final Completer<String> downLoadFileFuture = Completer<String>();
    final File filePr = File(downloadPath);
    final isPrExist = await filePr.exists();
    if (isPrExist) {
      await filePr.delete(); // 删除之前没有下载完成的文件
    }
    // 必须加上 否则 download 报 can not open file
    final File file = File(downloadPath);
    file.create(recursive: true);

    try {
      await _dio.download(
        downloadURL,
        downloadPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = received / total;
            onProgress(percent);
            if (percent >= 1) {
              downLoadFileFuture.complete(downloadPath);
            }
          }
        },
      );
      return downLoadFileFuture.future;
    } on DioException catch (e) {
      _handleError(e);
      onError.call();
      return '';
    }
  }

  ResBaseModel? _handleError(DioException e) {
    logger.e('e: $e ${e.requestOptions.uri}');
    String msg = 'Unknown error';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        msg = 'Connect timeout';
      case DioExceptionType.connectionError:
        msg = 'Connect error';
      case DioExceptionType.badCertificate:
        msg = 'Bad certificate';
      case DioExceptionType.sendTimeout:
        msg = 'Send timeout';
      case DioExceptionType.receiveTimeout:
        msg = 'Receive timeout';
      case DioExceptionType.badResponse:
        msg = 'Bad response';
      case DioExceptionType.cancel:
        msg = 'Request cancel';
      case DioExceptionType.unknown:
        msg = e.message ?? 'Unknown error';
    }
    logger.e('e.response: ${e.response}');
    // DialogUtil.dismiss();
    // DialogUtil.showToast(msg);
    return ResBaseModel(msg: msg, exception: e);
  }

  static HttpClient _createHttpClient() {
    return HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              Env.useBadCertificate;
  }
}

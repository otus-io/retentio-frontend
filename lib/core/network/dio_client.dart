import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:retentio/core/network/api_error_mapper.dart';
import 'package:retentio/core/network/dio_error_log.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/services/index.dart';

final NetworkDioClient networkDioClient = NetworkDioClient.instance;

class NetworkDioClient {
  NetworkDioClient._();

  static final NetworkDioClient instance = NetworkDioClient._();

  final Dio _dio = Dio();
  bool _didConfig = false;

  final Duration _connectTimeout = const Duration(minutes: 1);
  final Duration _receiveTimeout = const Duration(minutes: 1);
  final Duration _sendTimeout = const Duration(minutes: 1);

  Dio get dio => _dio;
  bool get isConfigured => _didConfig;

  void configure({
    required String baseUrl,
    List<Interceptor>? interceptors,
    BaseOptions? options,
    HttpClient Function()? proxyClientFactory,
  }) {
    _dio.interceptors.clear();

    if (options != null) {
      _dio.options = options;
    } else {
      _dio.options = BaseOptions(
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        contentType: Headers.jsonContentType,
      );

      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          _createHttpClient;
    }

    _dio.options.baseUrl = baseUrl;

    if (proxyClientFactory != null) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          proxyClientFactory;
    }

    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }

    _dio.transformer = BackgroundTransformer();
    _didConfig = true;
  }

  Future<ApiResponse?> get(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? pathParams,
    Options? options,
  }) async {
    _assertConfigured();
    url = _buildFinalUrl(url, pathParams);

    try {
      final response = params == null
          ? await _dio.get(url, options: options)
          : await _dio.get(url, queryParameters: params, options: options);
      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse?> post(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? pathParams,
    Options? options,
  }) async {
    _assertConfigured();
    url = _buildFinalUrl(url, pathParams);

    try {
      final response = await _dio.post(url, data: params, options: options);
      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ApiResponse.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse?> delete(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? pathParams,
  }) async {
    _assertConfigured();
    url = _buildFinalUrl(url, pathParams);

    try {
      final response = await _dio.delete(url, queryParameters: params);
      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ApiResponse.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse?> put(
    String url, {
    Map<String, dynamic>? pathParams,
  }) async {
    _assertConfigured();
    url = _buildFinalUrl(url, pathParams);
    try {
      final response = await _dio.put(url);
      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ApiResponse.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse?> patch(
    String url, {
    dynamic params,
    Map<String, dynamic>? pathParams,
  }) async {
    _assertConfigured();
    url = _buildFinalUrl(url, pathParams);

    try {
      final response = await _dio.patch(url, data: params);
      final res = response.data as Map<String, dynamic>?;
      if (res == null) return null;
      return ApiResponse.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse?> uploadFile(
    String url, {
    required String filePath,
    String? fileName,
    String? contentType,
    String? clientId,
    void Function(int count, int total)? onSendProgress,
  }) async {
    _assertConfigured();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: (contentType == null || contentType.isEmpty)
            ? null
            : DioMediaType.parse(contentType),
      ),
      if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
    });

    try {
      final response = await _dio.post(
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
      return ApiResponse.fromJson(res);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<String> downloadFile(
    String downloadUrl,
    String downloadPath,
    ValueChanged<double> onProgress,
    Function() onError, {
    CancelToken? cancelToken,
  }) async {
    _assertConfigured();

    final partialFile = File(downloadPath);
    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final outputFile = File(downloadPath);
    await outputFile.create(recursive: true);

    try {
      await _dio.download(
        downloadUrl,
        downloadPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );
      return downloadPath;
    } on DioException catch (e) {
      _handleError(e);
      onError.call();
      try {
        final failed = File(downloadPath);
        if (await failed.exists()) {
          await failed.delete();
        }
      } catch (_) {}
      return '';
    }
  }

  Future<Uint8List?> getImageUint8ListFrom(String url) async {
    _assertConfigured();
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

  void _assertConfigured() {
    assert(_didConfig, 'Please call NetworkDioClient.configure(...) first.');
  }

  String _buildFinalUrl(String path, Map<String, dynamic>? pathParams) {
    if (pathParams != null && _hasRestfulPlaceholders(path)) {
      final params = Map<String, dynamic>.from(pathParams);
      path = _restfulUrl(path, params);
    }
    return path;
  }

  bool _hasRestfulPlaceholders(String path) {
    return path.contains(RegExp(r'\{[^}]+\}'));
  }

  String _restfulUrl(String url, Map<String, dynamic> params) {
    var resultUrl = url;
    final keysToRemove = <String>[];

    params.forEach((key, value) {
      final placeholder = '{$key}';
      if (resultUrl.contains(placeholder)) {
        resultUrl = resultUrl.replaceAll(
          placeholder,
          Uri.encodeComponent(value.toString()),
        );
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      params.remove(key);
    }

    final schemeEndIndex = resultUrl.indexOf('://');
    var scheme = '';
    var rest = resultUrl;

    if (schemeEndIndex != -1) {
      scheme = resultUrl.substring(0, schemeEndIndex + 3);
      rest = resultUrl.substring(schemeEndIndex + 3);
    }

    rest = rest.replaceAll(RegExp(r'/+'), '/');
    return scheme + rest;
  }

  ApiResponse _handleError(DioException e) {
    logDioError('NetworkDioClient._handleError', e);
    return mapDioExceptionToApiResponse(e);
  }

  static HttpClient _createHttpClient() {
    return HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              Env.useBadCertificate;
  }
}

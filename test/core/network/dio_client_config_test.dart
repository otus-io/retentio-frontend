import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/dio_client.dart';

class _UnreachableAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => throw DioException.connectionError(
    requestOptions: options,
    reason: 'lookup',
    error: const SocketException('Failed host lookup: nope.invalid'),
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('default config gives up connecting after 8 seconds', () {
    networkDioClient.configure(baseUrl: 'https://nope.invalid');

    expect(
      networkDioClient.dio.options.connectTimeout,
      const Duration(seconds: 8),
    );
  });

  test('a connection error maps to a failed ApiResponse', () async {
    networkDioClient.configure(
      baseUrl: 'https://nope.invalid',
      options: BaseOptions(),
    );
    networkDioClient.dio.httpClientAdapter = _UnreachableAdapter();

    final res = await networkDioClient.get('/api/profile');

    expect(res?.code, -1);
    expect(res?.msg, 'Connect error');
    expect(res?.exception, isA<DioException>());
  });
}

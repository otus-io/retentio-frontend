import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/dio_error_log.dart';

void main() {
  final options = RequestOptions(path: 'https://api.example.com/api/profile');

  test('cause carries the underlying socket error', () {
    final err = DioException.connectionError(
      requestOptions: options,
      reason: 'lookup',
      error: const SocketException('Failed host lookup: api.example.com'),
    );

    final log = buildDioErrorLog(err);

    expect(log['dio_type'], 'connectionError');
    expect(log['cause'], contains('Failed host lookup'));
  });

  test('cause falls back to the Dio message when there is no error', () {
    final err = DioException.connectionTimeout(
      timeout: const Duration(seconds: 8),
      requestOptions: options,
    );

    final log = buildDioErrorLog(err);

    expect(log['dio_type'], 'connectionTimeout');
    expect(log['cause'], contains('0:00:08'));
  });

  test('cause is null when neither error nor message is set', () {
    final err = DioException(requestOptions: options);

    expect(buildDioErrorLog(err)['cause'], isNull);
  });
}

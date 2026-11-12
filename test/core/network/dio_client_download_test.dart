import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/dio_client.dart';

/// Serves [bytes] with [headers], whatever their Content-Length says.
class _BodyAdapter implements HttpClientAdapter {
  _BodyAdapter(this.bytes, this.headers);

  final List<int> bytes;
  final Map<String, List<String>> headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes(bytes, 200, headers: headers);

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tmp;
  late String path;
  late int errors;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dio_download_test');
    path = '${tmp.path}/media.part';
    errors = 0;
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<String> download(
    List<int> bytes, [
    Map<String, List<String>> headers = const {},
  ]) {
    networkDioClient.dio.httpClientAdapter = _BodyAdapter(bytes, headers);
    return networkDioClient.downloadFile(
      '/api/media/m1',
      path,
      (_) {},
      () => errors++,
    );
  }

  test('keeps a file of the announced size', () async {
    final result = await download(
      [1, 2, 3],
      {
        Headers.contentLengthHeader: ['3'],
      },
    );

    expect(result, path);
    expect(File(path).readAsBytesSync(), [1, 2, 3]);
    expect(errors, 0);
  });

  test('drops a file shorter than announced', () async {
    final result = await download(
      [1, 2, 3],
      {
        Headers.contentLengthHeader: ['10'],
      },
    );

    expect(result, isEmpty);
    expect(File(path).existsSync(), isFalse);
    expect(errors, 1);
  });

  test('keeps a file when no size is announced', () async {
    expect(await download([1, 2, 3]), path);
    expect(errors, 0);
  });

  test('keeps a compressed file, whose size header is not its own', () async {
    final result = await download(
      [1, 2, 3],
      {
        Headers.contentLengthHeader: ['10'],
        Headers.contentEncodingHeader: ['gzip'],
      },
    );

    expect(result, path);
    expect(errors, 0);
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/dio_client.dart';
import 'package:retentio/core/network/download_http2_adapter.dart';
import 'package:retentio/services/index.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> fetched = [];
  final List<bool> closed = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetched.add(options);
    return ResponseBody.fromBytes([1, 2, 3], 200);
  }

  @override
  void close({bool force = false}) => closed.add(force);
}

void main() {
  late _RecordingAdapter http1;
  late _RecordingAdapter http2;
  late DownloadHttp2Adapter adapter;

  setUp(() {
    http1 = _RecordingAdapter();
    http2 = _RecordingAdapter();
    adapter = DownloadHttp2Adapter(http1, http2: http2);
  });

  Future<void> fetch(Map<String, dynamic> extra) => adapter.fetch(
    RequestOptions(path: '/api/media/m1', extra: extra),
    null,
    null,
  );

  test('sends flagged requests over http2', () async {
    await fetch({DownloadHttp2Adapter.extraKey: true});

    expect(http2.fetched, hasLength(1));
    expect(http1.fetched, isEmpty);
  });

  test('sends flagged https requests over http2', () async {
    await adapter.fetch(
      RequestOptions(
        path: 'https://localhost/api/media/m1',
        extra: {DownloadHttp2Adapter.extraKey: true},
      ),
      null,
      null,
    );

    expect(http2.fetched, hasLength(1));
    expect(http1.fetched, isEmpty);
  });

  test('keeps flagged plain http requests on http1', () async {
    await adapter.fetch(
      RequestOptions(
        path: 'http://localhost:8080/api/media/m1',
        extra: {DownloadHttp2Adapter.extraKey: true},
      ),
      null,
      null,
    );

    expect(http1.fetched, hasLength(1));
    expect(http2.fetched, isEmpty);
  });

  test('keeps unflagged requests on http1', () async {
    await fetch({});
    await fetch({DownloadHttp2Adapter.extraKey: false});

    expect(http1.fetched, hasLength(2));
    expect(http2.fetched, isEmpty);
  });

  test('closes both adapters', () {
    adapter.close(force: true);

    expect(http1.closed, [true]);
    expect(http2.closed, [true]);
  });

  test('builds an http2 adapter falling back to http1', () {
    final built = DownloadHttp2Adapter(http1);

    expect(built.http2, isA<Http2Adapter>());
    expect((built.http2 as Http2Adapter).fallbackAdapter, same(http1));
  });

  test('accepts bad certificates as the http1 client does', () {
    final setting = ClientSetting();

    DownloadHttp2Adapter.applyClientSetting(Uri.parse('https://x'), setting);

    expect(
      setting.onBadCertificate!(_FakeCertificate()),
      Env.useBadCertificate,
    );
  });

  group('NetworkDioClient', () {
    tearDown(() => Env.isProxy = false);

    test('downloads through the http2 adapter by default', () {
      networkDioClient.configure(baseUrl: 'https://localhost');

      final configured = networkDioClient.dio.httpClientAdapter;
      expect(configured, isA<DownloadHttp2Adapter>());
      expect(
        (configured as DownloadHttp2Adapter).http1,
        isA<IOHttpClientAdapter>(),
      );
    });

    test('builds http1 clients with the given factory', () {
      HttpClient Function() factory = HttpClient.new;

      networkDioClient.configure(
        baseUrl: 'https://localhost',
        proxyClientFactory: factory,
      );

      final configured =
          networkDioClient.dio.httpClientAdapter as DownloadHttp2Adapter;
      expect(
        (configured.http1 as IOHttpClientAdapter).createHttpClient,
        same(factory),
      );
    });

    test('keeps http1 only behind a debugging proxy', () {
      Env.isProxy = true;

      networkDioClient.configure(baseUrl: 'https://localhost');

      expect(
        networkDioClient.dio.httpClientAdapter,
        isA<IOHttpClientAdapter>(),
      );
    });

    test('flags file downloads for http2', () async {
      final tmp = Directory.systemTemp.createTempSync('http2_flag_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      networkDioClient.configure(baseUrl: 'https://localhost');
      networkDioClient.dio.httpClientAdapter = adapter;

      await networkDioClient.downloadFile(
        '/api/media/m1',
        '${tmp.path}/m1.part',
        (_) {},
        () {},
      );

      expect(http2.fetched.single.path, '/api/media/m1');
      expect(http1.fetched, isEmpty);
    });
  });
}

class _FakeCertificate implements X509Certificate {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

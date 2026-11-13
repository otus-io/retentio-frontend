import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:retentio/services/index.dart';

/// Sends requests flagged with [extraKey] (file downloads) over HTTP/2, so
/// many run at once on one connection; all others keep [http1]. A server
/// without HTTP/2 (or plain `http://`) falls back to [http1].
class DownloadHttp2Adapter implements HttpClientAdapter {
  DownloadHttp2Adapter(this.http1, {HttpClientAdapter? http2})
    : http2 =
          http2 ??
          Http2Adapter(
            ConnectionManager(onClientCreate: applyClientSetting),
            fallbackAdapter: http1,
          );

  static const String extraKey = 'http2';

  final HttpClientAdapter http1;
  final HttpClientAdapter http2;

  /// Accepts the dev server's self-signed certificate like [http1] does.
  static void applyClientSetting(Uri uri, ClientSetting setting) =>
      setting.onBadCertificate = (_) => Env.useBadCertificate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => (options.extra[extraKey] == true ? http2 : http1).fetch(
    options,
    requestStream,
    cancelFuture,
  );

  @override
  void close({bool force = false}) {
    http2.close(force: force);
    http1.close(force: force);
  }
}

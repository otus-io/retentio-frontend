import 'dart:io';

import 'package:retentio/services/index.dart';

class ProxyClientFactory {
  static HttpClient create() {
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
        return 'DIRECT';
      }
      return 'PROXY ${Env.httpProxyHost}:${Env.httpProxyPort}';
    };

    return client;
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:retentio/services/index.dart';

void main() {
  group('Env', () {
    test('host returns a non-empty base URL string', () {
      expect(Env.host, isNotEmpty);
      expect(Env.host, matches(RegExp(r'^https?://')));
    });

    test('default proxy settings are readable', () {
      expect(Env.isProxy, isFalse);
      expect(Env.httpProxyHost, '192.168.0.228');
      expect(Env.httpProxyPort, '9090');
    });
  });
}

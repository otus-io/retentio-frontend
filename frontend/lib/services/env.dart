part of 'index.dart';


/// Created on 2026/2/5
/// Description:

ApiEnv _kApiEnv = ApiEnv.dev;

ApiEnv get kAPiEnv => _kApiEnv;
enum ApiEnv {
  debug,
  dev,
  release,
}

class Env {
  static bool get isDistribute => kReleaseMode && _kApiEnv == ApiEnv.release;

  static bool isProxy = false;
  static String httpProxyHost = '192.168.0.228';
  static String httpProxyPort = '9090';

  static bool get useBadCertificate => kDebugMode;

  static String get host {
    switch (_kApiEnv) {
      case ApiEnv.debug:
        return 'https://api.wordupx.com';
      case ApiEnv.dev:

        return 'https://api.wordupx.com';
      case ApiEnv.release:
        return 'https://api.wordupx.com';
      }
  }
}
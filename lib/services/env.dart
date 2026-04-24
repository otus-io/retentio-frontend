part of 'index.dart';

/// Created on 2026/2/5
/// Description:

/// Picked at compile time via `--dart-define=API_ENV=debug|dev|release`.
/// When omitted: [ApiEnv.release] in release/product builds (Xcode Archive,
/// `flutter build ios --release`), otherwise [ApiEnv.dev].
ApiEnv _resolveApiEnv() {
  const raw = String.fromEnvironment('API_ENV', defaultValue: '');
  if (raw.isEmpty) {
    return kReleaseMode ? ApiEnv.release : ApiEnv.dev;
  }
  switch (raw.toLowerCase()) {
    case 'debug':
      return ApiEnv.debug;
    case 'dev':
      return ApiEnv.dev;
    case 'release':
      return ApiEnv.release;
    default:
      return ApiEnv.dev;
  }
}

final ApiEnv _kApiEnv = _resolveApiEnv();

ApiEnv get kAPiEnv => _kApiEnv;

enum ApiEnv { debug, dev, release }

class Env {
  static bool get isDistribute => kReleaseMode && _kApiEnv == ApiEnv.release;

  static bool isProxy = false;
  static String httpProxyHost = '192.168.0.228';
  static String httpProxyPort = '9090';

  static bool get useBadCertificate => kDebugMode;

  /// Optional full base URL override, e.g. `--dart-define=API_HOST=http://192.168.1.10:8080`
  /// for a physical device. When non-empty, overrides [ApiEnv] host mapping.
  static String get host {
    const override = String.fromEnvironment('API_HOST', defaultValue: '');
    final trimmed = override.trim();
    if (trimmed.isNotEmpty) return trimmed;
    switch (_kApiEnv) {
      case ApiEnv.debug:
        return 'http://localhost:8080';
      case ApiEnv.dev:
        return 'https://10.0.0.145:8443';
      case ApiEnv.release:
        return 'https://api.retentio.app:8443';
    }
  }
}

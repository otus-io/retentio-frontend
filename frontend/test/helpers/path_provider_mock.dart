import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock implementation for path_provider plugin in tests
class PathProviderMock {
  static const MethodChannel _channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  /// Setup path_provider mock for tests
  static void setup() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return '/tmp/mock_documents';
            case 'getTemporaryDirectory':
              return '/tmp/mock_temp';
            case 'getApplicationSupportDirectory':
              return '/tmp/mock_support';
            case 'getLibraryDirectory':
              return '/tmp/mock_library';
            case 'getExternalStorageDirectory':
              return '/tmp/mock_external';
            case 'getExternalStorageDirectories':
              return ['/tmp/mock_external1', '/tmp/mock_external2'];
            case 'getExternalCacheDirectories':
              return ['/tmp/mock_external_cache1', '/tmp/mock_external_cache2'];
            default:
              throw MissingPluginException(
                'Method ${methodCall.method} not implemented',
              );
          }
        });
  }

  /// Clear the mock handler
  static void teardown() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}

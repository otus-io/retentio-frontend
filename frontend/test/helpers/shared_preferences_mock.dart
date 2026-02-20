import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock implementation for shared_preferences plugin in tests
class SharedPreferencesMock {
  static const MethodChannel _channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  /// Setup shared_preferences mock for tests
  static void setup() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getAll':
              // Return empty map to simulate fresh installation
              return <String, Object>{};
            case 'setBool':
            case 'setInt':
            case 'setDouble':
            case 'setString':
            case 'setStringList':
              // These methods don't need to return anything in mock
              return null;
            case 'remove':
              // Remove doesn't need to return anything in mock
              return null;
            case 'clear':
              // Clear doesn't need to return anything in mock
              return null;
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

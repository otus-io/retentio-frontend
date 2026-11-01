import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mocks the connectivity_plus plugin so widget tests report a network
/// interface as up by default (matching the online assumption of most tests).
class ConnectivityMock {
  static const MethodChannel _channel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity',
  );

  /// Current interfaces reported by `checkConnectivity`. Defaults to online.
  static List<String> interfaces = const ['wifi'];

  static void setup() {
    interfaces = const ['wifi'];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall methodCall) async {
          if (methodCall.method == 'check') {
            return interfaces;
          }
          return null;
        });
  }

  static void teardown() {
    interfaces = const ['wifi'];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:retentio/services/apis/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();
    });

    test('authorization is empty when no token', () {
      expect(ApiService.authorization, '');
    });

    test(
      'buildHeaders includes Content-Type and omits Authorization without token',
      () {
        final h = ApiService.buildHeaders(null);
        expect(h['Content-Type'], 'application/json');
        expect(h.containsKey('Authorization'), false);
      },
    );

    test('buildHeaders merges custom headers', () {
      final h = ApiService.buildHeaders({'X-Test': '1'});
      expect(h['Content-Type'], 'application/json');
      expect(h['X-Test'], '1');
    });

    test(
      'setToken updates authorization and buildHeaders adds Bearer',
      () async {
        await ApiService.setToken('my-token');
        expect(ApiService.authorization, 'my-token');
        final h = ApiService.buildHeaders(null);
        expect(h['Authorization'], 'Bearer my-token');
      },
    );

    test(
      'clearToken removes Authorization from subsequent buildHeaders',
      () async {
        await ApiService.setToken('t');
        await ApiService.clearToken();
        expect(ApiService.authorization, '');
        final h = ApiService.buildHeaders(null);
        expect(h.containsKey('Authorization'), false);
      },
    );

    test('init loads token from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'from-prefs');
      await ApiService.init();
      expect(ApiService.authorization, 'from-prefs');
      final h = ApiService.buildHeaders(null);
      expect(h['Authorization'], 'Bearer from-prefs');
    });
  });
}

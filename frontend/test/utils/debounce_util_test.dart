import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/utils/index.dart';

void main() {
  group('DebounceUtil', () {
    test('run executes callback after delay', () async {
      var called = false;
      final debounce = DebounceUtil(milliseconds: 50);

      debounce.run(() {
        called = true;
      });

      expect(called, false);
      await Future.delayed(const Duration(milliseconds: 60));
      expect(called, true);
    });

    test(
      'run cancels previous callback when called again before delay',
      () async {
        var callCount = 0;
        final debounce = DebounceUtil(milliseconds: 100);

        debounce.run(() => callCount++);
        await Future.delayed(const Duration(milliseconds: 20));
        debounce.run(() => callCount++);
        await Future.delayed(const Duration(milliseconds: 120));

        expect(callCount, 1);
      },
    );

    test('run with different millisecond values', () async {
      var called = false;
      final debounce = DebounceUtil(milliseconds: 10);

      debounce.run(() => called = true);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(called, true);
    });
  });
}

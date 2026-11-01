import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/bloc/fact_submit_guard_cubit.dart';

void main() {
  group('FactSubmitGuardCubit', () {
    test('returns the injected online status', () async {
      final online = FactSubmitGuardCubit(isOnline: () async => true);
      final offline = FactSubmitGuardCubit(isOnline: () async => false);
      addTearDown(online.close);
      addTearDown(offline.close);

      expect(await online.canSubmit(), isTrue);
      expect(await offline.canSubmit(), isFalse);
    });

    test('treats a probe failure as online', () async {
      final cubit = FactSubmitGuardCubit(
        isOnline: () async => throw Exception('boom'),
      );
      addTearDown(cubit.close);

      expect(await cubit.canSubmit(), isTrue);
    });
  });
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/connectivity_service.dart';

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity([this.current = const [ConnectivityResult.none]]);

  List<ConnectivityResult> current;
  final changes = StreamController<List<ConnectivityResult>>();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

void main() {
  test('hasNetworkConnection is true only when some interface is up', () async {
    expect(await hasNetworkConnection(_FakeConnectivity()), isFalse);
    expect(
      await hasNetworkConnection(
        _FakeConnectivity([ConnectivityResult.none, ConnectivityResult.wifi]),
      ),
      isTrue,
    );
  });

  test('onNetworkRestored emits only on offline to online', () async {
    final fake = _FakeConnectivity();
    final events = <void>[];
    final sub = onNetworkRestored(fake).listen(events.add);

    fake.changes
      ..add([ConnectivityResult.wifi])
      ..add([ConnectivityResult.none])
      ..add([ConnectivityResult.mobile])
      ..add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    await sub.cancel();
  });
}

import 'package:connectivity_plus/connectivity_plus.dart';

/// True when any network interface is up (not a guarantee the API is reachable).
Future<bool> hasNetworkConnection([Connectivity? connectivity]) async {
  final results = await (connectivity ?? Connectivity()).checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}

/// Emits each time the device goes from no network to some network.
Stream<void> onNetworkRestored([Connectivity? connectivity]) {
  var wasOnline = true;
  return (connectivity ?? Connectivity()).onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none))
      .where((online) {
        final restored = online && !wasOnline;
        wasOnline = online;
        return restored;
      });
}

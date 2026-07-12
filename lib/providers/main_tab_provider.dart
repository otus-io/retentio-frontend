import 'package:flutter_riverpod/flutter_riverpod.dart';

class _TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int i) => state = i;
}

/// Controls the currently selected bottom-nav tab in [MainTabScreen].
final selectedTabIndexProvider = NotifierProvider<_TabIndexNotifier, int>(
  _TabIndexNotifier.new,
);

class _RefreshSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

/// Incrementing this counter tells [DiscoveryScreen] to refresh its list.
final discoveryRefreshSignalProvider =
    NotifierProvider<_RefreshSignalNotifier, int>(_RefreshSignalNotifier.new);

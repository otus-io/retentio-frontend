import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LoadingState { initial, loading, loaded, error }

final loadingStateProvider = NotifierProvider.autoDispose(
  _LoadingStateNotifier.new,
);

class _LoadingStateNotifier extends Notifier<LoadingState> {
  @override
  LoadingState build() {
    return LoadingState.initial;
  }

  void showLoading() {
    state = LoadingState.loading;
  }

  void showInitial() {
    state = LoadingState.initial;
  }

  void showLoaded() {
    state = LoadingState.loaded;
  }

  void showError() {
    state = LoadingState.error;
  }
}

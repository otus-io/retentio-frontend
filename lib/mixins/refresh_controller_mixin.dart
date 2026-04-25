import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

mixin RefreshControllerMixin<R> on Notifier<R> {
  /// Riverpod may call [Notifier.build] again on the same instance after
  /// [Ref.invalidate] (e.g. session refresh on login). Keep one controller per
  /// notifier instance; on rebuild just trigger refresh.
  bool _refreshInitialized = false;
  bool _disposed = false;

  void refreshBuild() {
    if (!_refreshInitialized) {
      refreshController = RefreshController();
      ref.onDispose(() {
        _disposed = true;
        // pull_to_refresh can transiently rebuild header/footer while provider
        // is being invalidated; disposing here may null out RefreshStatus and
        // trigger type errors in MaterialClassicHeader.
      });
      _refreshInitialized = true;
    }
    onRefresh();
  }

  late RefreshController refreshController;

  bool isLoading = true;
  int page = 1;

  int get pageSize => 20;

  bool noMore = false;

  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      // Some pull_to_refresh status channels are null when pull-up is disabled.
    }
  }

  Future<void> onRefresh() async {
    if (refreshController.isLoading) {
      _safe(() => refreshController.refreshCompleted());
      return;
    }
    page = 1;
    try {
      final res = await loadData();
      _safe(() => refreshController.refreshCompleted());
      final recordsSize = res?.length ?? 0;
      if (recordsSize < pageSize) {
        noMore = true;
        _safe(() => refreshController.loadNoData());
      } else {
        noMore = false;
        _safe(() => refreshController.resetNoData());
      }
      isLoading = false;
      if (_disposed) return;
      ref.notifyListeners();
    } catch (e) {
      isLoading = false;
      debugPrint('onLoading: $e');
      // DialogUtil.showToast(e.toString());
      _safe(() => refreshController.refreshFailed());
      if (_disposed) return;
      ref.notifyListeners();
    }
  }

  Future<void> onLoading() async {
    if (refreshController.isRefresh) {
      _safe(() => refreshController.loadComplete());
      return;
    }
    if (noMore) {
      _safe(() => refreshController.loadNoData());
      return;
    }
    page++;
    try {
      final res = await loadData();
      final recordsSize = res?.length ?? 0;

      if (recordsSize < pageSize) {
        noMore = true;
        _safe(() => refreshController.loadNoData());
      } else {
        noMore = false;
        _safe(() => refreshController.loadComplete());
      }
      if (_disposed) return;
      ref.notifyListeners();
    } catch (e) {
      debugPrint('onLoading: $e');
      _safe(() => refreshController.loadFailed());
      if (_disposed) return;
      ref.notifyListeners();
    }
  }

  Future loadData();
}

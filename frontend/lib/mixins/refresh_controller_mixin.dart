import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
mixin RefreshControllerMixin<R> on Notifier<R>{

  void refreshBuild() {
    refreshController = RefreshController();
    ref.onDispose(() {
      refreshController.dispose();
    },);
    onRefresh();
  }
  late final RefreshController refreshController;

  bool isLoading = true;
  int page = 1;

  int get pageSize => 20;

  bool noMore = false;

  Future<void> onRefresh() async {
    if (refreshController.isLoading) {
      refreshController.refreshCompleted();
      return;
    }
    page = 1;
    try {
      final res = await loadData();
      refreshController.refreshCompleted();
      final recordsSize = res?.length ?? 0;
      if (recordsSize < pageSize) {
        noMore = true;
        refreshController.loadNoData();
      } else {
        noMore = false;
        refreshController.resetNoData();
      }
      isLoading = false;
      ref.notifyListeners();
    } catch (e) {
      isLoading = false;
      debugPrint('onLoading: $e');
      // DialogUtil.showToast(e.toString());
      refreshController.refreshFailed();
      ref.notifyListeners();
    }
  }

  Future<void> onLoading() async {
    if (refreshController.isRefresh) {
      refreshController.loadComplete();
      return;
    }
    if (noMore) {
      refreshController.loadNoData();
      return;
    }
    page++;
    try {
      final res = await loadData();
      final recordsSize = res?.length ?? 0;

      if (recordsSize < pageSize) {
        noMore = true;
        refreshController.loadNoData();
      } else {
        noMore = false;
        refreshController.loadComplete();
      }
      ref.notifyListeners();
    } catch (e) {
      debugPrint('onLoading: $e');
      refreshController.loadFailed();
      ref.notifyListeners();
    }
  }

  Future loadData();
}
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/utils/log.dart';

class DeckListState {
  const DeckListState({
    this.decks = const <Deck>[],
    this.isLoading = true,
    this.error,
    this.offlineReadyDeckIds = const <String>{},
    this.downloader,
  });

  final List<Deck> decks;
  final bool isLoading;
  final String? error;
  final Set<String> offlineReadyDeckIds;

  /// Offline downloader of the signed-in account; null when unavailable.
  final OfflinePackageDownloader? downloader;

  DeckListState copyWith({
    List<Deck>? decks,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Set<String>? offlineReadyDeckIds,
    OfflinePackageDownloader? downloader,
  }) {
    return DeckListState(
      decks: decks ?? this.decks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      offlineReadyDeckIds: offlineReadyDeckIds ?? this.offlineReadyDeckIds,
      downloader: downloader ?? this.downloader,
    );
  }
}

class DeckListCubit extends Cubit<DeckListState> {
  DeckListCubit({
    OfflineDeckCatalog? offlineCatalog,
    OfflineLearningSessions? sessions,
  }) : _offlineCatalog = offlineCatalog ?? OfflineDeckCatalog(),
       _sessions = sessions ?? OfflineLearningSessions.instance,
       super(const DeckListState()) {
    unawaited(_loadDownloader());
    onRefresh();
  }

  final OfflineDeckCatalog _offlineCatalog;
  final OfflineLearningSessions _sessions;

  final RefreshController refreshController = RefreshController();

  static const int _pageSize = 20;

  bool _disposed = false;
  bool _noMore = false;

  @override
  Future<void> close() {
    _disposed = true;
    return super.close();
  }

  Future<void> loadDecks() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final decks = await DeckService.of.getDecks();
      emit(state.copyWith(decks: decks, isLoading: false, clearError: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: rawApiErrorMessage(e)));
    }
  }

  Future<void> deleteDeck(Deck deck) async {
    final res = await DeckService.of.deleteDeck(deck.id);
    if (res?.isSuccess ?? false) {
      try {
        await _offlineCatalog.remove(deck.id);
      } catch (e) {
        logger.w('offline deck removal: $e');
      }
    }
    await onRefresh();
  }

  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      // pull_to_refresh may throw when load channel is unavailable.
    }
  }

  Future<void> onRefresh() async {
    if (refreshController.isLoading) {
      _safe(refreshController.refreshCompleted);
      return;
    }
    try {
      final decks = await _offlineCatalog.decks(
        () => DeckService.of.getDecks(throwOnError: true),
      );
      final offlineReadyDeckIds = await _offlineCatalog.readyDeckIds();
      _safe(refreshController.refreshCompleted);
      if (decks.length < _pageSize) {
        _noMore = true;
        _safe(refreshController.loadNoData);
      } else {
        _noMore = false;
        _safe(refreshController.resetNoData);
      }
      if (_disposed) {
        return;
      }
      emit(
        state.copyWith(
          decks: decks,
          isLoading: false,
          clearError: true,
          offlineReadyDeckIds: offlineReadyDeckIds,
        ),
      );
      _resumeDownloads();
    } catch (e) {
      _safe(refreshController.refreshFailed);
      if (_disposed) {
        return;
      }
      emit(state.copyWith(isLoading: false, error: rawApiErrorMessage(e)));
    }
  }

  /// Loaded apart from the list, which must not wait for the session.
  Future<void> _loadDownloader() async {
    final OfflinePackageDownloader? downloader;
    try {
      downloader = (await _sessions.current(
        fetchMissingUsername: false,
      ))?.downloader;
    } catch (_) {
      return;
    }
    if (_disposed || downloader == null) return;
    emit(state.copyWith(downloader: downloader));
    _resumeDownloads();
  }

  /// Picks up decks whose download never finished (for example the app was
  /// closed meanwhile). Needs both the deck ids and the downloader, so it
  /// runs when either arrives last.
  void _resumeDownloads() {
    final downloader = state.downloader;
    if (downloader == null || state.decks.isEmpty) return;
    unawaited(downloader.resumeMissing([for (final d in state.decks) d.id]));
  }

  Future<void> onLoading() async {
    if (refreshController.isRefresh) {
      _safe(refreshController.loadComplete);
      return;
    }
    if (_noMore) {
      _safe(refreshController.loadNoData);
      return;
    }
    // current API is non-paginated, so treat pull-up as completed.
    _safe(refreshController.loadNoData);
    _noMore = true;
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/discovery/data/discovery_favorites_repository.dart';
import 'package:retentio/models/catalog_deck.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';

// ── Filter ────────────────────────────────────────────────────────────────────

enum DiscoveryFilter { latest, favorites }

// ── State ─────────────────────────────────────────────────────────────────────

class DiscoveryListState {
  const DiscoveryListState({
    this.decks = const [],
    this.favoriteIds = const {},
    this.filter = DiscoveryFilter.latest,
    this.query = '',
    this.isLoading = true,
    this.error,
    this.hasMore = true,
    this.offset = 0,
  });

  final List<CatalogDeck> decks;
  final Set<String> favoriteIds;
  final DiscoveryFilter filter;
  final String query;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int offset;

  DiscoveryListState copyWith({
    List<CatalogDeck>? decks,
    Set<String>? favoriteIds,
    DiscoveryFilter? filter,
    String? query,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasMore,
    int? offset,
  }) {
    return DiscoveryListState(
      decks: decks ?? this.decks,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class DiscoveryListCubit extends Cubit<DiscoveryListState> {
  DiscoveryListCubit({DiscoveryFavoritesRepository? favoritesRepository})
    : _favoritesRepository =
          favoritesRepository ?? DiscoveryFavoritesRepository(),
      super(const DiscoveryListState()) {
    _init();
  }

  final DiscoveryFavoritesRepository _favoritesRepository;
  final RefreshController refreshController = RefreshController();

  static const int _pageSize = 20;

  bool _disposed = false;
  Timer? _debounce;

  @override
  Future<void> close() {
    _disposed = true;
    _debounce?.cancel();
    return super.close();
  }

  // ── init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final ids = await _favoritesRepository.loadFavorites();
    if (_disposed) return;
    emit(state.copyWith(favoriteIds: ids));
    await onRefresh();
  }

  // ── public API ─────────────────────────────────────────────────────────────

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_disposed) return;
      emit(state.copyWith(query: query, offset: 0, hasMore: true));
      onRefresh();
    });
  }

  Future<void> setFilter(DiscoveryFilter filter) async {
    if (state.filter == filter) return;
    emit(state.copyWith(filter: filter, offset: 0, hasMore: true));
    await onRefresh();
  }

  Future<void> toggleFavorite(String sourceDeckId) async {
    final ids = await _favoritesRepository.toggle(sourceDeckId);
    if (_disposed) return;
    emit(state.copyWith(favoriteIds: ids));
    if (state.filter == DiscoveryFilter.favorites) {
      await onRefresh();
    }
  }

  // ── refresh / load more ────────────────────────────────────────────────────

  Future<void> onRefresh() async {
    if (refreshController.isLoading) {
      _safe(refreshController.refreshCompleted);
      return;
    }
    try {
      final result = await _fetchPage(offset: 0);
      _safe(refreshController.refreshCompleted);
      if (!result.meta.hasMore) {
        _safe(refreshController.loadNoData);
      } else {
        _safe(refreshController.resetNoData);
      }
      if (_disposed) return;
      emit(
        state.copyWith(
          decks: result.decks,
          isLoading: false,
          clearError: true,
          hasMore: result.meta.hasMore,
          offset: result.decks.length,
        ),
      );
    } catch (e) {
      _safe(refreshController.refreshFailed);
      if (_disposed) return;
      emit(state.copyWith(isLoading: false, error: rawApiErrorMessage(e)));
    }
  }

  Future<void> onLoading() async {
    if (refreshController.isRefresh) {
      _safe(refreshController.loadComplete);
      return;
    }
    if (!state.hasMore) {
      _safe(refreshController.loadNoData);
      return;
    }
    try {
      final result = await _fetchPage(offset: state.offset);
      _safe(
        result.meta.hasMore
            ? refreshController.loadComplete
            : refreshController.loadNoData,
      );
      if (_disposed) return;
      emit(
        state.copyWith(
          decks: [...state.decks, ...result.decks],
          hasMore: result.meta.hasMore,
          offset: state.offset + result.decks.length,
        ),
      );
    } catch (e) {
      _safe(refreshController.loadFailed);
      if (_disposed) return;
      emit(state.copyWith(error: rawApiErrorMessage(e)));
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<CatalogPage> _fetchPage({required int offset}) async {
    if (state.filter == DiscoveryFilter.favorites) {
      return _fetchFavoritesPage(offset: offset);
    }
    return DeckCatalogService.of.getCatalog(
      limit: _pageSize,
      offset: offset,
      query: state.query.isEmpty ? null : state.query,
    );
  }

  Future<CatalogPage> _fetchFavoritesPage({required int offset}) async {
    final ids = state.favoriteIds.toList();
    if (ids.isEmpty) {
      return const CatalogPage(
        decks: [],
        meta: CatalogMeta(total: 0, hasMore: false),
      );
    }
    // Favorites 无分页，一次性从 catalog 拉全量并本地过滤。
    // 若 ID 数量极大可拆批，本期简化处理。
    final results = <CatalogDeck>[];
    for (final id in ids) {
      final deck = await DeckCatalogService.of.getCatalogDeck(id);
      if (deck != null) results.add(deck);
    }
    final query = state.query.toLowerCase();
    final filtered = query.isEmpty
        ? results
        : results
              .where(
                (d) =>
                    d.name.toLowerCase().contains(query) ||
                    d.owner.toLowerCase().contains(query),
              )
              .toList();
    return CatalogPage(
      decks: filtered,
      meta: CatalogMeta(total: filtered.length, hasMore: false),
    );
  }

  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {}
  }
}

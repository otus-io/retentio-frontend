import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/discovery/data/discovery_favorites_repository.dart';
import 'package:retentio/models/catalog_deck.dart';
import 'package:retentio/models/import_deck_result.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';

// ── Import status ─────────────────────────────────────────────────────────────

enum ImportStatus { none, importing, imported, error }

// ── State ─────────────────────────────────────────────────────────────────────

class DiscoveryDetailState {
  const DiscoveryDetailState({
    this.deck,
    this.isFavorite = false,
    this.importStatus = ImportStatus.none,
    this.importResult,
    this.isLoading = true,
    this.error,
    this.importError,
  });

  final CatalogDeck? deck;
  final bool isFavorite;
  final ImportStatus importStatus;
  final ImportDeckResult? importResult;
  final bool isLoading;
  final String? error;
  final String? importError;

  DiscoveryDetailState copyWith({
    CatalogDeck? deck,
    bool? isFavorite,
    ImportStatus? importStatus,
    ImportDeckResult? importResult,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? importError,
    bool clearImportError = false,
  }) {
    return DiscoveryDetailState(
      deck: deck ?? this.deck,
      isFavorite: isFavorite ?? this.isFavorite,
      importStatus: importStatus ?? this.importStatus,
      importResult: importResult ?? this.importResult,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      importError: clearImportError ? null : (importError ?? this.importError),
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class DiscoveryDetailCubit extends Cubit<DiscoveryDetailState> {
  DiscoveryDetailCubit({DiscoveryFavoritesRepository? favoritesRepository})
    : _favoritesRepository =
          favoritesRepository ?? DiscoveryFavoritesRepository(),
      super(const DiscoveryDetailState());

  final DiscoveryFavoritesRepository _favoritesRepository;

  Future<void> load(String sourceDeckId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final ids = await _favoritesRepository.loadFavorites();
      final deck = await DeckCatalogService.of.getCatalogDeck(sourceDeckId);
      if (isClosed) return;
      if (deck == null) {
        emit(state.copyWith(isLoading: false, error: 'deck_not_found'));
        return;
      }
      emit(
        state.copyWith(
          deck: deck,
          isFavorite: ids.contains(sourceDeckId),
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: rawApiErrorMessage(e)));
    }
  }

  Future<void> toggleFavorite() async {
    final deck = state.deck;
    if (deck == null) return;
    final ids = await _favoritesRepository.toggle(deck.id);
    if (isClosed) return;
    emit(state.copyWith(isFavorite: ids.contains(deck.id)));
  }

  Future<void> importDeck() async {
    final deck = state.deck;
    if (deck == null) return;
    if (state.importStatus == ImportStatus.importing) return;

    emit(
      state.copyWith(
        importStatus: ImportStatus.importing,
        clearImportError: true,
      ),
    );
    try {
      final result = await DeckCatalogService.of.importDeck(deck.id);
      if (isClosed) return;
      emit(
        state.copyWith(
          importStatus: ImportStatus.imported,
          importResult: result,
          clearImportError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          importStatus: ImportStatus.error,
          importError: rawApiErrorMessage(e),
        ),
      );
    }
  }

  /// 已知该卡组已被导入（如从列表跳来时携带状态）。
  void markImported(ImportDeckResult result) {
    emit(
      state.copyWith(importStatus: ImportStatus.imported, importResult: result),
    );
  }
}

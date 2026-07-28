import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/services/apis/deck_publish_service.dart';

/// Which list-card affordances should flash for unpublished / unsynced changes.
class DeckSharingStatusState {
  const DeckSharingStatusState({this.flashingDeckIds = const {}});

  final Set<String> flashingDeckIds;

  bool shouldFlash(String deckId) => flashingDeckIds.contains(deckId);

  DeckSharingStatusState copyWith({Set<String>? flashingDeckIds}) {
    return DeckSharingStatusState(
      flashingDeckIds: flashingDeckIds ?? this.flashingDeckIds,
    );
  }
}

/// Polls publish-preview (sources) and updates summary (imports) every 60s.
class DeckSharingStatusCubit extends Cubit<DeckSharingStatusState> {
  DeckSharingStatusCubit() : super(const DeckSharingStatusState());

  static const _pollInterval = Duration(seconds: 60);

  Timer? _timer;
  List<Deck> _decks = const [];
  bool _disposed = false;
  bool _refreshing = false;

  void setDecks(List<Deck> decks) {
    _decks = List<Deck>.from(decks);
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
    unawaited(refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void markDirty(String deckId) {
    if (_disposed || deckId.isEmpty) return;
    emit(state.copyWith(flashingDeckIds: {...state.flashingDeckIds, deckId}));
  }

  void clear(String deckId) {
    if (_disposed || deckId.isEmpty) return;
    final next = {...state.flashingDeckIds}..remove(deckId);
    emit(state.copyWith(flashingDeckIds: next));
  }

  Future<void> refresh() async {
    if (_disposed || _refreshing) return;
    _refreshing = true;
    final previous = state.flashingDeckIds;
    try {
      final next = <String>{};
      await Future.wait(
        _decks.map((deck) async {
          try {
            if (deck.isImported) {
              final summary = await DeckCatalogService.of.getDeckUpdatesSummary(
                deck.id,
              );
              if (summary.hasUpdates) next.add(deck.id);
            } else if (deck.isPublishedSource) {
              final preview = await DeckPublishService.of.getPublishPreview(
                deck.id,
              );
              if (preview.hasUnpublishedChanges) next.add(deck.id);
            }
          } catch (_) {
            if (previous.contains(deck.id)) {
              next.add(deck.id);
            }
          }
        }),
      );
      if (_disposed) return;
      emit(state.copyWith(flashingDeckIds: next));
    } finally {
      _refreshing = false;
    }
  }

  @override
  Future<void> close() {
    _disposed = true;
    stopPolling();
    return super.close();
  }
}

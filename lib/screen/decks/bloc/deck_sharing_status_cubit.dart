import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/services/apis/deck_publish_service.dart';

/// Which list-card affordances should flash for unpublished / unsynced changes
/// and which source decks have open importer contributions.
class DeckSharingStatusState {
  const DeckSharingStatusState({
    this.flashingDeckIds = const {},
    this.openContributionDeckIds = const {},
  });

  final Set<String> flashingDeckIds;
  final Set<String> openContributionDeckIds;

  bool shouldFlash(String deckId) => flashingDeckIds.contains(deckId);

  bool hasOpenContributions(String deckId) =>
      openContributionDeckIds.contains(deckId);

  DeckSharingStatusState copyWith({
    Set<String>? flashingDeckIds,
    Set<String>? openContributionDeckIds,
  }) {
    return DeckSharingStatusState(
      flashingDeckIds: flashingDeckIds ?? this.flashingDeckIds,
      openContributionDeckIds:
          openContributionDeckIds ?? this.openContributionDeckIds,
    );
  }
}

/// Polls publish-preview and open contribution inbox (published sources),
/// and updates summary (imports), every 60s.
/// Offline it neither polls nor shows badges.
class DeckSharingStatusCubit extends Cubit<DeckSharingStatusState> {
  DeckSharingStatusCubit({Future<bool> Function()? isOnline})
    : _isOnline = isOnline ?? hasNetworkConnection,
      super(const DeckSharingStatusState());

  final Future<bool> Function() _isOnline;

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

  void markOpenContributions(String deckId) {
    if (_disposed || deckId.isEmpty) return;
    emit(
      state.copyWith(
        openContributionDeckIds: {...state.openContributionDeckIds, deckId},
      ),
    );
  }

  void clearOpenContributions(String deckId) {
    if (_disposed || deckId.isEmpty) return;
    final next = {...state.openContributionDeckIds}..remove(deckId);
    emit(state.copyWith(openContributionDeckIds: next));
  }

  Future<void> refresh() async {
    if (_disposed || _refreshing) return;
    _refreshing = true;
    final previousFlash = state.flashingDeckIds;
    final previousContrib = state.openContributionDeckIds;
    try {
      final nextFlash = <String>{};
      final nextContrib = <String>{};
      if (_decks.isNotEmpty &&
          !await _isOnline().catchError((Object _) => true)) {
        if (!_disposed) {
          emit(
            state.copyWith(
              flashingDeckIds: nextFlash,
              openContributionDeckIds: nextContrib,
            ),
          );
        }
        return;
      }
      await Future.wait(
        _decks.map((deck) async {
          if (deck.isImported) {
            try {
              final summary = await DeckCatalogService.of.getDeckUpdatesSummary(
                deck.id,
              );
              if (summary.hasUpdates) nextFlash.add(deck.id);
            } catch (_) {
              if (previousFlash.contains(deck.id)) {
                nextFlash.add(deck.id);
              }
            }
            return;
          }

          if (!deck.isPublishedSource) return;

          try {
            final preview = await DeckPublishService.of.getPublishPreview(
              deck.id,
            );
            if (preview.hasUnpublishedChanges) nextFlash.add(deck.id);
          } catch (_) {
            if (previousFlash.contains(deck.id)) {
              nextFlash.add(deck.id);
            }
          }

          try {
            final page = await DeckCatalogService.of.listContributions(
              deck.id,
              status: 'open',
              limit: 1,
            );
            if (page.contributions.isNotEmpty) {
              nextContrib.add(deck.id);
            }
          } catch (_) {
            if (previousContrib.contains(deck.id)) {
              nextContrib.add(deck.id);
            }
          }
        }),
      );
      if (_disposed) return;
      emit(
        state.copyWith(
          flashingDeckIds: nextFlash,
          openContributionDeckIds: nextContrib,
        ),
      );
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

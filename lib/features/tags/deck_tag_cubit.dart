import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/tag_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum DeckTagStatus { initial, loading, loaded, error }

class DeckTagState {
  const DeckTagState({
    this.status = DeckTagStatus.initial,
    this.tags = const [],
    this.errorMessage,
  });

  final DeckTagStatus status;

  /// Current tags attached to this deck (sorted by name for display).
  final List<Tag> tags;
  final String? errorMessage;

  bool get isLoading => status == DeckTagStatus.loading;

  DeckTagState copyWith({
    DeckTagStatus? status,
    List<Tag>? tags,
    String? errorMessage,
  }) {
    return DeckTagState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the tags attached to a single deck.
/// Scope: deck — provide in the deck-detail / deck-create context.
class DeckTagCubit extends Cubit<DeckTagState> {
  DeckTagCubit({required this.deckId}) : super(const DeckTagState());

  final String deckId;

  // ── read ──────────────────────────────────────────────────

  Future<void> loadTags() async {
    emit(state.copyWith(status: DeckTagStatus.loading));
    try {
      final tags = await TagService.of.getDeckTags(deckId);
      emit(state.copyWith(
        status: DeckTagStatus.loaded,
        tags: _sorted(tags),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DeckTagStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── associate ─────────────────────────────────────────────

  /// Associates [tagId] with this deck. Returns error string or null.
  Future<String?> addTag(String tagId) async {
    try {
      final tags = await TagService.of.addTagToDeck(deckId, tagId);
      emit(state.copyWith(
        status: DeckTagStatus.loaded,
        tags: _sorted(tags),
      ));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Removes [tagId] from this deck optimistically. Returns error string or null.
  Future<String?> removeTag(String tagId) async {
    final previous = state.tags;
    emit(state.copyWith(
      tags: previous.where((t) => t.id != tagId).toList(),
    ));

    try {
      final tags = await TagService.of.removeTagFromDeck(deckId, tagId);
      emit(state.copyWith(
        status: DeckTagStatus.loaded,
        tags: _sorted(tags),
      ));
      return null;
    } catch (e) {
      emit(state.copyWith(tags: previous));
      return e.toString();
    }
  }

  // ── helpers ───────────────────────────────────────────────

  bool hasTag(String tagId) => state.tags.any((t) => t.id == tagId);

  /// Max 20 tags per deck (API limit).
  bool get isAtLimit => state.tags.length >= 20;

  List<Tag> _sorted(List<Tag> tags) =>
      [...tags]..sort((a, b) => a.name.compareTo(b.name));
}

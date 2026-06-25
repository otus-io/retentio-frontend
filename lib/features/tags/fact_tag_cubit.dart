import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/tag_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum FactTagStatus { initial, loading, loaded, error }

class FactTagState {
  const FactTagState({
    this.status = FactTagStatus.initial,
    this.tags = const [],
    this.errorMessage,
  });

  final FactTagStatus status;

  /// Current tags attached to this fact (sorted by name for display).
  final List<Tag> tags;
  final String? errorMessage;

  bool get isLoading => status == FactTagStatus.loading;

  FactTagState copyWith({
    FactTagStatus? status,
    List<Tag>? tags,
    String? errorMessage,
  }) {
    return FactTagState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the tags attached to a single fact.
/// Scope: fact — provide in the fact-detail / fact-edit context.
class FactTagCubit extends Cubit<FactTagState> {
  FactTagCubit({required this.deckId, required this.factId})
    : super(const FactTagState());

  final String deckId;
  final String factId;

  // ── read ──────────────────────────────────────────────────

  Future<void> loadTags() async {
    emit(state.copyWith(status: FactTagStatus.loading));
    try {
      final tags = await TagService.of.getFactTags(deckId, factId);
      emit(state.copyWith(status: FactTagStatus.loaded, tags: _sorted(tags)));
    } catch (e) {
      emit(
        state.copyWith(status: FactTagStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // ── associate ─────────────────────────────────────────────

  /// Associates [tagId] with this fact. Returns error string or null.
  Future<String?> addTag(String tagId) async {
    try {
      final tags = await TagService.of.addTagToFact(deckId, factId, tagId);
      emit(state.copyWith(status: FactTagStatus.loaded, tags: _sorted(tags)));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Removes [tagId] from this fact optimistically. Returns error string or null.
  Future<String?> removeTag(String tagId) async {
    final previous = state.tags;
    emit(state.copyWith(tags: previous.where((t) => t.id != tagId).toList()));

    try {
      final tags = await TagService.of.removeTagFromFact(deckId, factId, tagId);
      emit(state.copyWith(status: FactTagStatus.loaded, tags: _sorted(tags)));
      return null;
    } catch (e) {
      emit(state.copyWith(tags: previous));
      return e.toString();
    }
  }

  // ── helpers ───────────────────────────────────────────────

  bool hasTag(String tagId) => state.tags.any((t) => t.id == tagId);

  List<Tag> _sorted(List<Tag> tags) =>
      [...tags]..sort((a, b) => a.name.compareTo(b.name));
}

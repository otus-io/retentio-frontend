import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/tag_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum TagManagerStatus { initial, loading, loaded, error }

class TagManagerState {
  const TagManagerState({
    this.status = TagManagerStatus.initial,
    this.tags = const [],
    this.errorMessage,
  });

  final TagManagerStatus status;
  final List<Tag> tags;
  final String? errorMessage;

  bool get isLoading => status == TagManagerStatus.loading;

  TagManagerState copyWith({
    TagManagerStatus? status,
    List<Tag>? tags,
    String? errorMessage,
  }) {
    return TagManagerState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the full list of tags owned by the current user.
/// Scope: global — typically provided above the main navigation shell so
/// both the deck-create sheet and fact-composer can share the same list.
class TagManagerCubit extends Cubit<TagManagerState> {
  TagManagerCubit() : super(const TagManagerState());

  // ── read ──────────────────────────────────────────────────

  Future<void> loadTags() async {
    emit(state.copyWith(status: TagManagerStatus.loading));
    try {
      final tags = await TagService.of.getTags();
      emit(state.copyWith(status: TagManagerStatus.loaded, tags: tags));
    } catch (e) {
      emit(
        state.copyWith(
          status: TagManagerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ── create ────────────────────────────────────────────────

  /// Creates a new tag and refreshes the list.
  /// Returns the error message string on failure, null on success.
  Future<String?> createTag({
    required String name,
    String description = '',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Tag name cannot be empty';

    try {
      final res = await TagService.of.createTag(
        name: trimmed,
        description: description.trim(),
      );
      if (res?.isSuccess == true) {
        await loadTags();
        return null;
      }
      return res?.msg ?? 'Could not create tag';
    } catch (e) {
      return e.toString();
    }
  }

  // ── update ────────────────────────────────────────────────

  /// Updates name and/or description; refreshes the list on success.
  Future<String?> updateTag(
    String tagId, {
    String? name,
    String? description,
  }) async {
    try {
      final res = await TagService.of.updateTag(
        tagId,
        name: name?.trim(),
        description: description?.trim(),
      );
      if (res?.isSuccess == true) {
        await loadTags();
        return null;
      }
      return res?.msg ?? 'Could not update tag';
    } catch (e) {
      return e.toString();
    }
  }

  // ── delete ────────────────────────────────────────────────

  /// Deletes a tag and removes it from the local list optimistically.
  Future<String?> deleteTag(String tagId) async {
    // Optimistic removal for instant feedback.
    final previous = state.tags;
    emit(state.copyWith(tags: previous.where((t) => t.id != tagId).toList()));

    try {
      final res = await TagService.of.deleteTag(tagId);
      if (res?.isSuccess == true) return null;

      // Rollback on failure.
      emit(state.copyWith(tags: previous));
      return res?.msg ?? 'Could not delete tag';
    } catch (e) {
      emit(state.copyWith(tags: previous));
      return e.toString();
    }
  }

  // ── helpers ───────────────────────────────────────────────

  /// Whether the user has already reached the 100-tag limit.
  bool get isAtLimit => state.tags.length >= 100;
}

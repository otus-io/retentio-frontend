import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
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
  TagManagerCubit({this.usedOn, this.deckId}) : super(const TagManagerState());

  /// 'fact' | 'deck' | null (全量，管理页使用)
  final String? usedOn;
  final String? deckId;

  // ── read ──────────────────────────────────────────────────

  Future<void> loadTags() async {
    emit(state.copyWith(status: TagManagerStatus.loading));
    try {
      final tags = await TagService.of.getTags(usedOn: usedOn, deckId: deckId);
      emit(state.copyWith(status: TagManagerStatus.loaded, tags: tags));
    } catch (e) {
      emit(
        state.copyWith(
          status: TagManagerStatus.error,
          errorMessage: rawApiErrorMessage(e),
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
      return rawApiErrorMessage(e);
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
      return rawApiErrorMessage(e);
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
      return rawApiErrorMessage(e);
    }
  }

  // ── helpers ───────────────────────────────────────────────

  /// Whether the user has already reached the 1000-tag limit.
  bool get isAtLimit => state.tags.length >= 1000;
}

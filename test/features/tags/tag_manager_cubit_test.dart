import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/models/tag.dart';

// Helpers ─────────────────────────────────────────────────────────────────────

/// Build a [TagManagerState] pre-populated with [count] dummy tags so we can
/// test computed properties without hitting the network.
TagManagerState _stateWithTags(int count) {
  final tags = List.generate(
    count,
    (i) => Tag(id: 'tag-$i', name: 'Tag $i', description: ''),
  );
  return TagManagerState(status: TagManagerStatus.loaded, tags: tags);
}

// Tests ───────────────────────────────────────────────────────────────────────

void main() {
  group('TagManagerState', () {
    test('initial state has status initial, empty tags, no error', () {
      const state = TagManagerState();
      expect(state.status, TagManagerStatus.initial);
      expect(state.tags, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });

    test('isLoading is true only when status is loading', () {
      expect(
        const TagManagerState(status: TagManagerStatus.loading).isLoading,
        isTrue,
      );
      expect(
        const TagManagerState(status: TagManagerStatus.loaded).isLoading,
        isFalse,
      );
      expect(
        const TagManagerState(status: TagManagerStatus.error).isLoading,
        isFalse,
      );
    });

    test('copyWith replaces only the specified fields', () {
      const original = TagManagerState(
        status: TagManagerStatus.loaded,
        tags: [],
        errorMessage: null,
      );
      final updated = original.copyWith(
        status: TagManagerStatus.error,
        errorMessage: 'oops',
      );
      expect(updated.status, TagManagerStatus.error);
      expect(updated.errorMessage, 'oops');
      expect(updated.tags, same(original.tags));
    });

    test('copyWith with no arguments produces identical values', () {
      final state = TagManagerState(
        status: TagManagerStatus.loaded,
        tags: [const Tag(id: 'x', name: 'X', description: '')],
        errorMessage: null,
      );
      final copy = state.copyWith();
      expect(copy.status, state.status);
      expect(copy.tags, state.tags);
      expect(copy.errorMessage, state.errorMessage);
    });
  });

  group('TagManagerCubit — pure logic', () {
    late TagManagerCubit cubit;

    setUp(() {
      cubit = TagManagerCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    // ── initial state ─────────────────────────────────────────

    test('starts with TagManagerStatus.initial', () {
      expect(cubit.state.status, TagManagerStatus.initial);
      expect(cubit.state.tags, isEmpty);
    });

    // ── isAtLimit ─────────────────────────────────────────────

    test('isAtLimit is false when fewer than 1000 tags are loaded', () {
      // Emit a state with 999 tags via the stream (bypasses service call).
      cubit.emit(_stateWithTags(999));
      expect(cubit.isAtLimit, isFalse);
    });

    test('isAtLimit is true when exactly 1000 tags are loaded', () {
      cubit.emit(_stateWithTags(1000));
      expect(cubit.isAtLimit, isTrue);
    });

    test('isAtLimit is true when more than 1000 tags are present', () {
      cubit.emit(_stateWithTags(1001));
      expect(cubit.isAtLimit, isTrue);
    });

    test('isAtLimit is false when tag list is empty', () {
      expect(cubit.isAtLimit, isFalse);
    });

    // ── createTag empty-name guard ────────────────────────────

    test('createTag returns error and emits nothing for blank name', () async {
      final emitted = <TagManagerState>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      final result = await cubit.createTag(name: '   ');

      expect(result, 'Tag name cannot be empty');
      // No state change — guard returns before any emit.
      expect(emitted, isEmpty);
    });

    test('createTag returns error for empty string name', () async {
      final emitted = <TagManagerState>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      final result = await cubit.createTag(name: '');

      expect(result, 'Tag name cannot be empty');
      expect(emitted, isEmpty);
    });

    // ── optimistic delete rollback ────────────────────────────

    test(
      'deleteTag removes tag optimistically then rolls back on error',
      () async {
        // Start with two tags pre-loaded.
        const tagA = Tag(id: 'a', name: 'A', description: '');
        const tagB = Tag(id: 'b', name: 'B', description: '');
        cubit.emit(
          TagManagerState(status: TagManagerStatus.loaded, tags: [tagA, tagB]),
        );

        final emitted = <TagManagerState>[];
        final sub = cubit.stream.listen(emitted.add);
        addTearDown(sub.cancel);

        // deleteTag calls TagService.of.deleteTag which will fail (no network).
        // The cubit should: (1) optimistically remove the tag, (2) roll back.
        await cubit.deleteTag('a');

        // At least one optimistic removal must have been emitted.
        expect(
          emitted.any((s) => s.tags.every((t) => t.id != 'a')),
          isTrue,
          reason: 'expected optimistic removal of tag "a"',
        );

        // Final state after rollback must contain both tags again.
        expect(cubit.state.tags, containsAll([tagA, tagB]));
      },
    );
  });
}

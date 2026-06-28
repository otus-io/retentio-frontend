import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/tags/deck_tag_cubit.dart';
import 'package:retentio/models/tag.dart';

// Helpers ─────────────────────────────────────────────────────────────────────

DeckTagState _stateWithTags(int count) {
  final tags = List.generate(
    count,
    (i) => Tag(id: 'tag-$i', name: 'Tag $i', description: ''),
  );
  return DeckTagState(status: DeckTagStatus.loaded, tags: tags);
}

// Tests ───────────────────────────────────────────────────────────────────────

void main() {
  group('DeckTagState', () {
    test('initial state has status initial, empty tags, no error', () {
      const state = DeckTagState();
      expect(state.status, DeckTagStatus.initial);
      expect(state.tags, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });

    test('isLoading is true only when status is loading', () {
      expect(
        const DeckTagState(status: DeckTagStatus.loading).isLoading,
        isTrue,
      );
      expect(
        const DeckTagState(status: DeckTagStatus.loaded).isLoading,
        isFalse,
      );
      expect(
        const DeckTagState(status: DeckTagStatus.error).isLoading,
        isFalse,
      );
    });

    test('copyWith replaces only the specified fields', () {
      const original = DeckTagState(status: DeckTagStatus.loaded, tags: []);
      final updated = original.copyWith(
        status: DeckTagStatus.error,
        errorMessage: 'oops',
      );
      expect(updated.status, DeckTagStatus.error);
      expect(updated.errorMessage, 'oops');
      expect(updated.tags, same(original.tags));
    });

    test('copyWith with no arguments produces identical values', () {
      final state = DeckTagState(
        status: DeckTagStatus.loaded,
        tags: [const Tag(id: 'x', name: 'X', description: '')],
        errorMessage: null,
      );
      final copy = state.copyWith();
      expect(copy.status, state.status);
      expect(copy.tags, state.tags);
      expect(copy.errorMessage, state.errorMessage);
    });
  });

  group('DeckTagCubit — pure logic', () {
    late DeckTagCubit cubit;

    setUp(() {
      cubit = DeckTagCubit(deckId: 'deck-1');
    });

    tearDown(() async {
      await cubit.close();
    });

    // ── initial state ─────────────────────────────────────────

    test('starts with DeckTagStatus.initial', () {
      expect(cubit.state.status, DeckTagStatus.initial);
      expect(cubit.state.tags, isEmpty);
    });

    // ── hasTag ────────────────────────────────────────────────

    test('hasTag returns false when no tags are loaded', () {
      expect(cubit.hasTag('any-id'), isFalse);
    });

    test('hasTag returns false when tag is not present', () {
      cubit.emit(_stateWithTags(3));
      expect(cubit.hasTag('non-existent'), isFalse);
    });

    test('hasTag returns true when tag is present', () {
      cubit.emit(_stateWithTags(3));
      expect(cubit.hasTag('tag-0'), isTrue);
      expect(cubit.hasTag('tag-2'), isTrue);
    });

    // ── isAtLimit ─────────────────────────────────────────────

    test('isAtLimit is false when tag list is empty', () {
      expect(cubit.isAtLimit, isFalse);
    });

    test('isAtLimit is false when fewer than 20 tags are loaded', () {
      cubit.emit(_stateWithTags(19));
      expect(cubit.isAtLimit, isFalse);
    });

    test('isAtLimit is true when exactly 20 tags are loaded', () {
      cubit.emit(_stateWithTags(20));
      expect(cubit.isAtLimit, isTrue);
    });

    test('isAtLimit is true when more than 20 tags are loaded', () {
      cubit.emit(_stateWithTags(21));
      expect(cubit.isAtLimit, isTrue);
    });

    // ── removeTag optimistic rollback ─────────────────────────

    test(
      'removeTag removes tag optimistically then rolls back on network error',
      () async {
        const tagA = Tag(id: 'a', name: 'A', description: '');
        const tagB = Tag(id: 'b', name: 'B', description: '');
        cubit.emit(
          DeckTagState(status: DeckTagStatus.loaded, tags: [tagA, tagB]),
        );

        final emitted = <DeckTagState>[];
        final sub = cubit.stream.listen(emitted.add);
        addTearDown(sub.cancel);

        await cubit.removeTag('a');

        // At least one optimistic removal must have been emitted.
        expect(
          emitted.any((s) => s.tags.every((t) => t.id != 'a')),
          isTrue,
          reason: 'expected optimistic removal of tag "a"',
        );

        // Final state after network failure must restore both tags.
        expect(cubit.state.tags, containsAll([tagA, tagB]));
      },
    );
  });
}

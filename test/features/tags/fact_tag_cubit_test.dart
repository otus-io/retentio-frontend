import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/tags/fact_tag_cubit.dart';
import 'package:retentio/models/tag.dart';

// Helpers ─────────────────────────────────────────────────────────────────────

FactTagState _stateWithTags(int count) {
  final tags = List.generate(
    count,
    (i) => Tag(id: 'tag-$i', name: 'Tag $i', description: ''),
  );
  return FactTagState(status: FactTagStatus.loaded, tags: tags);
}

// Tests ───────────────────────────────────────────────────────────────────────

void main() {
  group('FactTagState', () {
    test('initial state has status initial, empty tags, no error', () {
      const state = FactTagState();
      expect(state.status, FactTagStatus.initial);
      expect(state.tags, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });

    test('isLoading is true only when status is loading', () {
      expect(
        const FactTagState(status: FactTagStatus.loading).isLoading,
        isTrue,
      );
      expect(
        const FactTagState(status: FactTagStatus.loaded).isLoading,
        isFalse,
      );
      expect(
        const FactTagState(status: FactTagStatus.error).isLoading,
        isFalse,
      );
    });

    test('copyWith replaces only the specified fields', () {
      const original = FactTagState(status: FactTagStatus.loaded, tags: []);
      final updated = original.copyWith(
        status: FactTagStatus.error,
        errorMessage: 'oops',
      );
      expect(updated.status, FactTagStatus.error);
      expect(updated.errorMessage, 'oops');
      expect(updated.tags, same(original.tags));
    });

    test('copyWith with no arguments produces identical values', () {
      final state = FactTagState(
        status: FactTagStatus.loaded,
        tags: [const Tag(id: 'x', name: 'X', description: '')],
        errorMessage: null,
      );
      final copy = state.copyWith();
      expect(copy.status, state.status);
      expect(copy.tags, state.tags);
      expect(copy.errorMessage, state.errorMessage);
    });
  });

  group('FactTagCubit — pure logic', () {
    late FactTagCubit cubit;

    setUp(() {
      cubit = FactTagCubit(deckId: 'deck-1', factId: 'fact-1');
    });

    tearDown(() async {
      await cubit.close();
    });

    // ── initial state ─────────────────────────────────────────

    test('starts with FactTagStatus.initial', () {
      expect(cubit.state.status, FactTagStatus.initial);
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

    // ── removeTag optimistic rollback ─────────────────────────

    test(
      'removeTag removes tag optimistically then rolls back on network error',
      () async {
        await cubit.close();
        cubit = FactTagCubit(
          deckId: 'deck-1',
          factId: 'fact-1',
          removeTagFromFact: (deckIdArg, factIdArg, tagIdArg) async {
            throw Exception('network failed');
          },
        );

        const tagA = Tag(id: 'a', name: 'A', description: '');
        const tagB = Tag(id: 'b', name: 'B', description: '');
        cubit.emit(
          FactTagState(status: FactTagStatus.loaded, tags: [tagA, tagB]),
        );

        final emitted = <FactTagState>[];
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

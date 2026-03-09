import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/learn/providers/deck_provider.dart';

void main() {
  group('DeckListState', () {
    test('default constructor uses empty decks and false isLoading', () {
      final state = DeckListState();
      expect(state.decks, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('constructor with values', () {
      final state = DeckListState(
        decks: [],
        isLoading: true,
        error: 'Something went wrong',
      );
      expect(state.decks, isEmpty);
      expect(state.isLoading, true);
      expect(state.error, 'Something went wrong');
    });

    test('copyWith updates specified fields', () {
      final original = DeckListState(decks: [], isLoading: true, error: 'old');
      final copy = original.copyWith(isLoading: false, error: null);
      expect(copy.isLoading, false);
      expect(copy.error, isNull);
      expect(copy.decks, same(original.decks));
    });

    test('copyWith preserves decks when only isLoading is updated', () {
      final original = DeckListState(
        decks: const [],
        isLoading: true,
        error: 'err',
      );
      final copy = original.copyWith(isLoading: false);
      expect(copy.decks, same(original.decks));
      expect(copy.isLoading, false);
    });
  });
}

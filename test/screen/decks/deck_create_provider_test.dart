import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/screen/decks/providers/deck_create.dart';

void main() {
  group('CreateDeckParams', () {
    test('copyWith replaces only provided fields', () {
      final base = CreateDeckParams(
        name: 'A',
        rate: 10,
        type: DeckCardType.add,
        id: '',
        fields: ['x', 'y'],
      );
      final next = base.copyWith(name: 'B', rate: 20);
      expect(next.name, 'B');
      expect(next.rate, 20);
      expect(next.type, DeckCardType.add);
      expect(next.fields, ['x', 'y']);
    });
  });

  group('CreateDeckState', () {
    test('copyWith keeps unspecified fields', () {
      final s = CreateDeckState(fields: ['a', 'b'], name: 'n', rate: 30);
      final c = s.copyWith(rate: 40);
      expect(c.fields, ['a', 'b']);
      expect(c.name, 'n');
      expect(c.rate, 40);
    });
  });

  group('DeckParamsNotifier', () {
    test('build returns empty add-mode params with default rate 30', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final params = container.read(createDeckParamsProvider);
      expect(params.name, '');
      expect(params.rate, 30);
      expect(params.type, DeckCardType.add);
      expect(params.fields, isEmpty);
    });
  });

  group('CreateDeckNotifier', () {
    test('changeRate updates provider state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(createDeckProvider).rate, 30);
      container.read(createDeckProvider.notifier).changeRate(60);
      expect(container.read(createDeckProvider).rate, 60);
    });

    test('changeRate clamps to 1–1000 (create/edit deck field)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(createDeckProvider.notifier).changeRate(0);
      expect(container.read(createDeckProvider).rate, 1);
      container.read(createDeckProvider.notifier).changeRate(-50);
      expect(container.read(createDeckProvider).rate, 1);
      container.read(createDeckProvider.notifier).changeRate(1000);
      expect(container.read(createDeckProvider).rate, 1000);
      container.read(createDeckProvider.notifier).changeRate(2000);
      expect(container.read(createDeckProvider).rate, 1000);
    });

    test(
      'rate from createDeckParamsProvider is clamped to 1–1000 on build',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container
            .read(createDeckParamsProvider.notifier)
            .update((s) => s.copyWith(rate: 0));
        expect(container.read(createDeckProvider).rate, 1);
        container
            .read(createDeckParamsProvider.notifier)
            .update((s) => s.copyWith(rate: 9999));
        expect(container.read(createDeckProvider).rate, 1000);
      },
    );
  });

  group('clampDeckEditorRate', () {
    test('enforces inclusive 1–1000', () {
      expect(clampDeckEditorRate(0), 1);
      expect(clampDeckEditorRate(1), 1);
      expect(clampDeckEditorRate(500), 500);
      expect(clampDeckEditorRate(1000), 1000);
      expect(clampDeckEditorRate(1001), 1000);
    });
  });
}

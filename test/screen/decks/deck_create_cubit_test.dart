import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';

void main() {
  group('deck field helpers', () {
    test('normalizeDeckFieldNames trims whitespace', () {
      expect(normalizeDeckFieldNames([' Front ', 'Back  ']), ['Front', 'Back']);
    });

    test('hasBlankDeckFieldNames detects empty or whitespace-only fields', () {
      expect(hasBlankDeckFieldNames(['Front', '   ']), isTrue);
      expect(hasBlankDeckFieldNames(['Front', 'Back']), isFalse);
    });
  });

  group('DeckCreateCubit.submit validation', () {
    DeckCreateCubit buildCubit(String name) => DeckCreateCubit(
      name: name,
      rate: kDeckEditorRateDefault,
      deckId: '',
      cardType: DeckCardType.add,
    );

    test('empty name reports a typed error, not an English message', () async {
      final cubit = buildCubit('   ');
      addTearDown(cubit.close);

      final result = await cubit.submit(fieldNames: ['Front']);

      expect(result.success, isFalse);
      expect(result.error, DeckCreateError.nameEmpty);
      // A raw message here would bypass localization at the call-site.
      expect(result.message, isNull);
    });

    test('blank column header reports a typed error', () async {
      final cubit = buildCubit('Japanese');
      addTearDown(cubit.close);

      final result = await cubit.submit(fieldNames: ['Front', '   ']);

      expect(result.success, isFalse);
      expect(result.error, DeckCreateError.blankFieldName);
      expect(result.message, isNull);
    });
  });

  group('buildDeckEditorSubmitParams', () {
    test('imported edit deck sends rate only', () {
      final params = buildDeckEditorSubmitParams(
        cardType: DeckCardType.edit,
        isImported: true,
        rate: 45,
        name: 'Ignored name',
        fields: ['field-a', 'field-b'],
      );

      expect(params, {'rate': 45});
    });

    test('non-imported edit deck sends name, fields, and rate', () {
      final params = buildDeckEditorSubmitParams(
        cardType: DeckCardType.edit,
        isImported: false,
        rate: 45,
        name: 'My deck',
        fields: ['field-a', 'field-b'],
      );

      expect(params, {
        'name': 'My deck',
        'fields': ['field-a', 'field-b'],
        'rate': 45,
      });
    });

    test('create deck sends name, fields, and rate', () {
      final params = buildDeckEditorSubmitParams(
        cardType: DeckCardType.add,
        isImported: false,
        rate: 2000,
        name: 'New deck',
        fields: ['front'],
      );

      expect(params, {
        'name': 'New deck',
        'fields': ['front'],
        'rate': 1000,
      });
    });
  });
}

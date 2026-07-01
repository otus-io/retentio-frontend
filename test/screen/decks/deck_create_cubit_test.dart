import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';

void main() {
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

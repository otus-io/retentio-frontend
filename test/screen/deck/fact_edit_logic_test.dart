import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/fact_add_composer/fact_edit_logic.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/services/apis/media_service.dart';

Deck _makeDeck({List<String> fields = const []}) {
  return Deck(
    id: 'deck-1',
    name: 'Deck',
    stats: DeckStats(
      cardsCount: 0,
      factsCount: 0,
      unseenCards: 0,
      reviewedCards: 0,
      dueCards: 0,
      hiddenCards: 0,
      newCardsToday: 0,
      lastReviewedAt: 0,
    ),
    rate: 10,
    owner: DeckOwner(username: 'user', email: 'user@test.com'),
    fields: fields,
    minInterval: 0,
    defInterval: 0,
    maxInterval: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FactEditRowModel', () {
    test(
      'seedRowAttachmentPathsFromExisting mirrors existing ids into row paths',
      () {
        final row = AddFactRowModel();
        final model = FactEditRowModel(
          row: row,
          existingImageId: 'img-1',
          existingVideoId: 'vid-1',
          existingAudioId: 'aud-1',
          existingJsonId: 'json-1',
        );

        model.seedRowAttachmentPathsFromExisting();

        expect(row.imagePath, 'img-1');
        expect(row.videoPath, 'vid-1');
        expect(row.audioPath, 'aud-1');
        expect(row.jsonPath, 'json-1');
        row.dispose();
      },
    );

    test('existingFor and clearExistingFor isolate each media kind', () {
      final row = AddFactRowModel();
      final model = FactEditRowModel(
        row: row,
        existingImageId: 'img-1',
        existingVideoId: 'vid-1',
        existingAudioId: 'aud-1',
        existingJsonId: 'json-1',
      );

      expect(model.existingFor(MediaSlotKind.image), 'img-1');
      expect(model.existingFor(MediaSlotKind.video), 'vid-1');
      expect(model.existingFor(MediaSlotKind.audio), 'aud-1');
      expect(model.existingFor(MediaSlotKind.json), 'json-1');

      model.clearExistingFor(MediaSlotKind.video);
      expect(model.existingVideoId, isNull);
      expect(model.existingImageId, 'img-1');
      expect(model.existingAudioId, 'aud-1');
      expect(model.existingJsonId, 'json-1');
      row.dispose();
    });

    test('clearAllAttachments clears row paths and existing ids', () {
      final row = AddFactRowModel();
      row.imagePath = '/tmp/new.jpg';
      row.videoPath = '/tmp/new.mp4';
      row.audioPath = '/tmp/new.m4a';
      row.jsonPath = '/tmp/new.json';
      final model = FactEditRowModel(
        row: row,
        existingImageId: 'img-1',
        existingVideoId: 'vid-1',
        existingAudioId: 'aud-1',
        existingJsonId: 'json-1',
      );

      model.clearAllAttachments();

      expect(row.imagePath, isNull);
      expect(row.videoPath, isNull);
      expect(row.audioPath, isNull);
      expect(row.jsonPath, isNull);
      expect(model.existingImageId, isNull);
      expect(model.existingVideoId, isNull);
      expect(model.existingAudioId, isNull);
      expect(model.existingJsonId, isNull);
      row.dispose();
    });
  });

  group('factEditRowHasAttachment', () {
    test('true when row has newly picked attachment', () {
      final row = AddFactRowModel()..imagePath = '/tmp/image.jpg';
      final model = FactEditRowModel(row: row);
      expect(factEditRowHasAttachment(model), isTrue);
      row.dispose();
    });

    test('true when only existing attachment id is present', () {
      final row = AddFactRowModel();
      final model = FactEditRowModel(row: row, existingAudioId: 'aud-1');
      expect(factEditRowHasAttachment(model), isTrue);
      row.dispose();
    });

    test('true when only existing json id is present', () {
      final row = AddFactRowModel();
      final model = FactEditRowModel(row: row, existingJsonId: 'j-1');
      expect(factEditRowHasAttachment(model), isTrue);
      row.dispose();
    });

    test('false when no attachment in row or existing ids', () {
      final row = AddFactRowModel();
      final model = FactEditRowModel(row: row);
      expect(factEditRowHasAttachment(model), isFalse);
      row.dispose();
    });
  });

  group('factEditRowHasAnyContent', () {
    test('true when text exists (trimmed)', () {
      final row = AddFactRowModel()..content.text = '  hello  ';
      final model = FactEditRowModel(row: row);
      expect(factEditRowHasAnyContent(model), isTrue);
      row.dispose();
    });

    test('true when only attachment exists', () {
      final row = AddFactRowModel();
      final model = FactEditRowModel(row: row, existingImageId: 'img-1');
      expect(factEditRowHasAnyContent(model), isTrue);
      row.dispose();
    });

    test('false when both text and attachments are empty', () {
      final row = AddFactRowModel()..content.text = '   ';
      final model = FactEditRowModel(row: row);
      expect(factEditRowHasAnyContent(model), isFalse);
      row.dispose();
    });
  });

  group('factEditResolveFields', () {
    test('uses user field, then deck field, then fallback', () {
      final rows = [
        FactEditRowModel(row: AddFactRowModel()),
        FactEditRowModel(row: AddFactRowModel()),
        FactEditRowModel(row: AddFactRowModel()),
      ];
      rows[0].row.fieldName.text = 'Custom Front';
      rows[1].row.fieldName.text = '   ';
      rows[2].row.fieldName.text = '';

      final fields = factEditResolveFields(
        rows: rows,
        deck: _makeDeck(fields: ['Front', 'Back']),
        fallbackForIndex: (i) => 'Field $i',
      );

      expect(fields, ['Custom Front', 'Back', 'Field 3']);
      for (final r in rows) {
        r.row.dispose();
      }
    });
  });
}

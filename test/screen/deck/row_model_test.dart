import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/services/apis/media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddFactRowModel', () {
    test('hasTextContent is false when empty', () {
      final row = AddFactRowModel();
      expect(row.hasTextContent, isFalse);
      row.dispose();
    });

    test('hasTextContent ignores surrounding whitespace', () {
      final row = AddFactRowModel();
      row.content.text = '  hello  ';
      expect(row.hasTextContent, isTrue);
      row.dispose();
    });

    test('hasAttachment is true when any slot has a path', () {
      final row = AddFactRowModel();
      expect(row.hasAttachment, isFalse);
      row.imagePath = '/tmp/x.jpg';
      expect(row.hasAttachment, isTrue);
      row.dispose();
    });

    test('pathFor and clearSlot isolate kinds', () {
      final row = AddFactRowModel();
      row.setPathFor(MediaSlotKind.image, '/a.jpg');
      row.setPathFor(MediaSlotKind.audio, '/a.m4a');
      expect(row.imagePath, '/a.jpg');
      expect(row.audioPath, '/a.m4a');
      expect(row.videoPath, isNull);
      row.clearSlot(MediaSlotKind.image);
      expect(row.imagePath, isNull);
      expect(row.audioPath, '/a.m4a');
      row.dispose();
    });

    test('initialFieldName prefills fieldName controller', () {
      final row = AddFactRowModel(initialFieldName: 'Front');
      expect(row.fieldName.text, 'Front');
      row.dispose();
    });

    test('listForDeckFields yields two blank rows when deck has no fields', () {
      final rows = AddFactRowModel.listForDeckFields([]);
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.fieldName.text.isEmpty), isTrue);
      for (final r in rows) {
        r.dispose();
      }
    });

    test('listForDeckFields mirrors deck field names', () {
      final rows = AddFactRowModel.listForDeckFields(['Term', 'Definition']);
      expect(rows, hasLength(2));
      expect(rows[0].fieldName.text, 'Term');
      expect(rows[1].fieldName.text, 'Definition');
      for (final r in rows) {
        r.dispose();
      }
    });
  });

  group('addFactRowIsSatisfied', () {
    test('true when text present', () {
      final row = AddFactRowModel();
      row.content.text = 'a';
      expect(addFactRowIsSatisfied(row), isTrue);
      row.dispose();
    });

    test('true when attachment present', () {
      final row = AddFactRowModel();
      row.imagePath = '/x';
      expect(addFactRowIsSatisfied(row), isTrue);
      row.dispose();
    });

    test('false when empty', () {
      final row = AddFactRowModel();
      expect(addFactRowIsSatisfied(row), isFalse);
      row.dispose();
    });
  });
}

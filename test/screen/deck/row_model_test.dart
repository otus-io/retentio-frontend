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

    test('hasAttachment requires path and kind', () {
      final row = AddFactRowModel();
      expect(row.hasAttachment, isFalse);
      row.attachmentPath = '/tmp/x.jpg';
      expect(row.hasAttachment, isFalse);
      row.attachmentKind = MediaSlotKind.image;
      expect(row.hasAttachment, isTrue);
      row.dispose();
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
      row.attachmentPath = '/x';
      row.attachmentKind = MediaSlotKind.image;
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

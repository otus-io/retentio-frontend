import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/deck/fact_add_composer/add_fact_attachment_chip.dart';
import 'package:retentio/services/apis/media_service.dart';

void main() {
  group('addFactAttachmentChipIcon', () {
    test('maps each slot kind to a Lucide icon', () {
      expect(addFactAttachmentChipIcon(MediaSlotKind.image), LucideIcons.image);
      expect(addFactAttachmentChipIcon(MediaSlotKind.video), LucideIcons.video);
      expect(
        addFactAttachmentChipIcon(MediaSlotKind.audio),
        LucideIcons.audioLines,
      );
    });
  });
}

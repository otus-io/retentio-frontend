import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:retentio/services/apis/media_service.dart';

IconData addFactAttachmentChipIcon(MediaSlotKind kind) {
  switch (kind) {
    case MediaSlotKind.image:
      return LucideIcons.image;
    case MediaSlotKind.video:
      return LucideIcons.video;
    case MediaSlotKind.audio:
      return LucideIcons.audioLines;
    case MediaSlotKind.json:
      return LucideIcons.braces;
  }
}

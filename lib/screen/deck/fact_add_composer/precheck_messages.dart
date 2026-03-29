import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/media_service.dart';

class AddFactPrecheckMessages {
  AddFactPrecheckMessages._();

  static String message(
    AppLocalizations loc,
    MediaPrecheck pre,
    MediaSlotKind slot,
  ) {
    switch (pre) {
      case MediaPrecheck.ok:
        return '';
      case MediaPrecheck.fileTooLarge:
        final mb = switch (slot) {
          MediaSlotKind.image => 5,
          MediaSlotKind.json => 2,
          MediaSlotKind.audio || MediaSlotKind.video => 200,
        };
        return loc.addFactFileTooLarge(mb);
      case MediaPrecheck.unknownType:
        return loc.addFactFileTypeNotSupported;
      case MediaPrecheck.wrongType:
        return loc.addFactFileWrongSlot;
      case MediaPrecheck.fileNotFound:
        return loc.addFactUploadFailed;
    }
  }
}

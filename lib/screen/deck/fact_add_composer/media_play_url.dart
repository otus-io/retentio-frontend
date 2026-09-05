import 'dart:io';

import 'package:retentio/models/deck_contribution.dart';

/// Playable URL or local path for an attachment slot value (media id, URL, or file).
String? attachmentAudioPlayUrl(String? pathOrId) {
  if (pathOrId == null) return null;
  final value = pathOrId.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('/api/')) {
    return value;
  }
  final file = File(value);
  if (file.existsSync()) return file.absolute.path;
  return DeckContribution.ownedMediaUrl(value);
}

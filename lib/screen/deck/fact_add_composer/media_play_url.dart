import 'dart:io';

import 'package:retentio/models/deck_contribution.dart';

/// Playable URL or local path for an attachment slot value (media id, URL, or file).
///
/// [mediaVersions] maps a bare media id to its import snapshot pin; pinned ids
/// play `/api/media/{id}?v={pin}` because the working copy is owner-only.
String? attachmentAudioPlayUrl(
  String? pathOrId, {
  Map<String, int> mediaVersions = const {},
}) {
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
  final pinned = mediaVersions[value];
  if (pinned != null && pinned > 0) {
    return '/api/media/$value?v=$pinned';
  }
  return DeckContribution.ownedMediaUrl(value);
}

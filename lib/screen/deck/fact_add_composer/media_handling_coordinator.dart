import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/focus.dart';
import 'package:retentio/screen/deck/fact_add_composer/pick_extensions.dart';
import 'package:retentio/screen/deck/fact_add_composer/precheck_messages.dart';
import 'package:retentio/services/apis/media_service.dart';

mixin MediaHandlingCoordinator<T extends StatefulWidget> on State<T> {
  AudioRecorder get voiceRecorder;
  bool get isRecordingVoice;
  set isRecordingVoice(bool value);
  List<GlobalKey> get mediaTargetHostKeys;

  void showComposerSnack(String message);
  void attachPathOnTargetRow(MediaSlotKind kind, String path);
  bool get targetRowHasAttachment;
  void clearTargetRowAttachment();

  /// Last row that had focus inside its host — used when the mic/toolbar is
  /// focused so a recording still attaches to the field the user was editing.
  int _stickyMediaTargetRow = 0;

  /// Explicit pin (e.g. after clearing that row's audio). Wins over live focus
  /// until focus moves to a different host row.
  int? _pinnedMediaTargetRow;

  /// Row locked in when recording starts, so tapping another field mid-record
  /// neither moves the recording hint nor redirects the finished clip.
  int? _recordingTargetRow;

  bool get voiceRecordingAvailable =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Pause underlying card/deck audio so the microphone can own the session.
  Future<void> prepareForExternalMicRecording() async {}

  /// Pins media attach/record to [index] (e.g. after clearing that row's audio).
  void pinMediaTargetRow(int index) {
    final last = mediaTargetHostKeys.length - 1;
    if (last < 0) {
      _stickyMediaTargetRow = 0;
      _pinnedMediaTargetRow = null;
      return;
    }
    final clamped = index < 0 ? 0 : (index > last ? last : index);
    _stickyMediaTargetRow = clamped;
    _pinnedMediaTargetRow = clamped;
  }

  /// Updates the sticky media target from the focused row. Call on focus
  /// changes (not during build) so [targetRowIndexForMedia] stays a pure read.
  void refreshMediaTargetFromFocus() {
    final focused = addFactFocusedHostRowIndex(
      focusContext: FocusManager.instance.primaryFocus?.context,
      hostKeys: mediaTargetHostKeys,
    );
    if (focused == null) return;
    final pinned = _pinnedMediaTargetRow;
    if (pinned != null && focused != pinned) {
      // User moved focus to another row — follow them and drop the pin.
      _pinnedMediaTargetRow = null;
    }
    _stickyMediaTargetRow = focused;
  }

  int targetRowIndexForMedia() {
    final locked = _recordingTargetRow;
    if (locked != null) return locked;
    final last = mediaTargetHostKeys.length - 1;
    if (last < 0) return 0;

    final pinned = _pinnedMediaTargetRow;
    if (pinned != null) {
      if (pinned < 0) return 0;
      if (pinned > last) return last;
      return pinned;
    }

    final focused = addFactFocusedHostRowIndex(
      focusContext: FocusManager.instance.primaryFocus?.context,
      hostKeys: mediaTargetHostKeys,
    );
    if (focused != null) return focused;
    if (_stickyMediaTargetRow < 0) return 0;
    if (_stickyMediaTargetRow > last) return last;
    return _stickyMediaTargetRow;
  }

  Future<void> tryAttachPickedPath(String path) async {
    final loc = AppLocalizations.of(context)!;
    final kind = MediaService.classifyFile(path);
    if (kind == null) {
      showComposerSnack(loc.addFactFileTypeNotSupported);
      return;
    }
    final pre = await MediaService.precheckSlot(kind, path);
    if (pre != MediaPrecheck.ok) {
      showComposerSnack(AddFactPrecheckMessages.message(loc, pre, kind));
      return;
    }
    if (!mounted) return;
    attachPathOnTargetRow(kind, path);
  }

  Future<void> pickMediaForTargetRow() async {
    final loc = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AddFactPickExtensions.all,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) {
      showComposerSnack(loc.addFactUploadFailed);
      return;
    }
    await tryAttachPickedPath(path);
  }

  Future<void> pickGalleryMediaForTargetRow() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickMedia(requestFullMetadata: false);
      if (picked == null || !mounted) return;
      final path = picked.path;
      if (path.isEmpty) {
        showComposerSnack(loc.addFactUploadFailed);
        return;
      }
      await tryAttachPickedPath(path);
    } on PlatformException catch (_) {
      if (mounted) showComposerSnack(loc.addFactUploadFailed);
    }
  }

  Future<void> toggleVoiceRecording() async {
    final loc = AppLocalizations.of(context)!;
    if (isRecordingVoice) {
      await finishVoiceRecording();
      return;
    }
    await prepareForExternalMicRecording();
    final permitted = await voiceRecorder.hasPermission();
    if (!permitted) {
      if (mounted) showComposerSnack(loc.addFactMicPermissionDenied);
      return;
    }
    final dir = await getTemporaryDirectory();
    final ext = Platform.isAndroid ? 'aac' : 'm4a';
    final filePath = p.join(
      dir.path,
      'fact_voice_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    try {
      await voiceRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );
      _recordingTargetRow = targetRowIndexForMedia();
      if (mounted) setState(() => isRecordingVoice = true);
    } catch (_) {
      if (mounted) showComposerSnack(loc.addFactRecordingFailed);
    }
  }

  Future<void> finishVoiceRecording() async {
    try {
      await _stopAndAttachRecording();
    } finally {
      // Keep the lock if a new recording already started during the attach.
      if (!isRecordingVoice) _recordingTargetRow = null;
    }
  }

  Future<void> _stopAndAttachRecording() async {
    final loc = AppLocalizations.of(context)!;
    String? outPath;
    try {
      outPath = await voiceRecorder.stop();
    } catch (_) {
      if (mounted) showComposerSnack(loc.addFactRecordingFailed);
    }
    if (!mounted) return;
    setState(() => isRecordingVoice = false);
    if (outPath != null && outPath.isNotEmpty) {
      try {
        if ((await File(outPath).length()) == 0) {
          if (mounted) showComposerSnack(loc.addFactRecordingFailed);
          return;
        }
      } catch (_) {
        if (mounted) showComposerSnack(loc.addFactRecordingFailed);
        return;
      }
      await tryAttachPickedPath(outPath);
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (!isRecordingVoice) return;
    _recordingTargetRow = null;
    try {
      await voiceRecorder.cancel();
    } catch (_) {}
    if (!mounted) return;
    setState(() => isRecordingVoice = false);
  }

  void onVoiceRecordLongPress() {
    if (isRecordingVoice) {
      cancelVoiceRecording();
      return;
    }
    if (targetRowHasAttachment) {
      clearTargetRowAttachment();
    }
  }
}

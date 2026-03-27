import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/focus.dart';
import 'package:retentio/screen/deck/fact_add_composer/pick_extensions.dart';
import 'package:retentio/screen/deck/fact_add_composer/precheck_messages.dart';
import 'package:retentio/services/apis/media_service.dart';

mixin MediaHandlingCoordinator<T extends StatefulWidget> on State<T> {
  RecorderController get voiceRecorder;
  bool get isRecordingVoice;
  set isRecordingVoice(bool value);
  List<GlobalKey> get mediaTargetHostKeys;

  void showComposerSnack(String message);
  void attachPathOnTargetRow(MediaSlotKind kind, String path);
  bool get targetRowHasAttachment;
  void clearTargetRowAttachment();

  bool get voiceRecordingAvailable =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  int targetRowIndexForMedia() {
    return addFactTargetRowIndexForMedia(
      focusContext: FocusManager.instance.primaryFocus?.context,
      hostKeys: mediaTargetHostKeys,
    );
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
    final result = await FilePicker.platform.pickFiles(
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
    final permitted = await voiceRecorder.checkPermission();
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
      await voiceRecorder.record(
        path: filePath,
        recorderSettings: const RecorderSettings(),
      );
      if (mounted) setState(() => isRecordingVoice = true);
    } catch (_) {
      if (mounted) showComposerSnack(loc.addFactRecordingFailed);
    }
  }

  Future<void> finishVoiceRecording() async {
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
      await tryAttachPickedPath(outPath);
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (!isRecordingVoice) return;
    String? outPath;
    try {
      outPath = await voiceRecorder.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => isRecordingVoice = false);
    voiceRecorder.reset();
    if (outPath != null && outPath.isNotEmpty) {
      try {
        await File(outPath).delete();
      } catch (_) {}
    }
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

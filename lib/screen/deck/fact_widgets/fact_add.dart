import 'dart:async' show unawaited;
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/focus.dart';
import 'package:retentio/screen/deck/fact_add_composer/payload.dart';
import 'package:retentio/screen/deck/fact_add_composer/pick_extensions.dart';
import 'package:retentio/screen/deck/fact_add_composer/precheck_messages.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/screen/deck/fact_add_composer/toolbars.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/media_service.dart';

class FactAdd extends ConsumerStatefulWidget {
  const FactAdd({super.key, required this.deck, this.onStudyQueueRefresh});

  final Deck deck;

  /// Refresh the current study card queue (e.g. [cardProvider]). Must be supplied
  /// from a [WidgetRef] scoped under [deckProvider] — the modal sheet is not, so
  /// this widget cannot call [cardProvider] safely by itself.
  final Future<void> Function()? onStudyQueueRefresh;

  @override
  ConsumerState<FactAdd> createState() => _FactAddState();
}

class _FactAddState extends ConsumerState<FactAdd> {
  final List<AddFactRowModel> _rows = [AddFactRowModel(), AddFactRowModel()];

  bool _submitting = false;
  bool _recordingVoice = false;
  late final RecorderController _voiceRecorder;

  bool get _voiceRecordingAvailable =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  List<GlobalKey> get _hostKeys => [for (final r in _rows) r.hostKey];

  @override
  void initState() {
    super.initState();
    _voiceRecorder = RecorderController();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    _voiceRecorder.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  int _targetRowIndexForMedia() {
    return addFactTargetRowIndexForMedia(
      focusContext: FocusManager.instance.primaryFocus?.context,
      hostKeys: _hostKeys,
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _tryAttachPickedPath(String path) async {
    final loc = AppLocalizations.of(context)!;
    final kind = MediaService.classifyFile(path);
    if (kind == null) {
      _snack(loc.addFactFileTypeNotSupported);
      return;
    }
    final pre = await MediaService.precheckSlot(kind, path);
    if (pre != MediaPrecheck.ok) {
      _snack(AddFactPrecheckMessages.message(loc, pre, kind));
      return;
    }
    if (!mounted) return;
    final idx = _targetRowIndexForMedia();
    setState(() {
      final row = _rows[idx];
      row.attachmentPath = path;
      row.attachmentKind = kind;
    });
  }

  Future<void> _pickMediaForTargetRow() async {
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
      _snack(loc.addFactUploadFailed);
      return;
    }
    await _tryAttachPickedPath(path);
  }

  Future<void> _pickGalleryMediaForTargetRow() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickMedia(requestFullMetadata: false);
      if (picked == null || !mounted) return;
      final path = picked.path;
      if (path.isEmpty) {
        _snack(loc.addFactUploadFailed);
        return;
      }
      await _tryAttachPickedPath(path);
    } on PlatformException catch (_) {
      if (mounted) _snack(loc.addFactUploadFailed);
    }
  }

  Future<void> _toggleVoiceRecording() async {
    final loc = AppLocalizations.of(context)!;
    if (_recordingVoice) {
      await _finishVoiceRecording();
      return;
    }
    final permitted = await _voiceRecorder.checkPermission();
    if (!permitted) {
      if (mounted) _snack(loc.addFactMicPermissionDenied);
      return;
    }
    final dir = await getTemporaryDirectory();
    final ext = Platform.isAndroid ? 'aac' : 'm4a';
    final filePath = p.join(
      dir.path,
      'fact_voice_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    try {
      await _voiceRecorder.record(
        path: filePath,
        recorderSettings: const RecorderSettings(),
      );
      if (mounted) setState(() => _recordingVoice = true);
    } catch (_) {
      if (mounted) _snack(loc.addFactRecordingFailed);
    }
  }

  Future<void> _finishVoiceRecording() async {
    final loc = AppLocalizations.of(context)!;
    String? outPath;
    try {
      outPath = await _voiceRecorder.stop();
    } catch (_) {
      if (mounted) _snack(loc.addFactRecordingFailed);
    }
    if (!mounted) return;
    setState(() => _recordingVoice = false);
    if (outPath != null && outPath.isNotEmpty) {
      await _tryAttachPickedPath(outPath);
    }
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_recordingVoice) return;
    String? outPath;
    try {
      outPath = await _voiceRecorder.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _recordingVoice = false);
    _voiceRecorder.reset();
    if (outPath != null && outPath.isNotEmpty) {
      try {
        await File(outPath).delete();
      } catch (_) {}
    }
  }

  void _onVoiceRecordLongPress() {
    if (_recordingVoice) {
      _cancelVoiceRecording();
      return;
    }
    if (_rows[_targetRowIndexForMedia()].hasAttachment) {
      _clearAttachmentOnTargetRow();
    }
  }

  void _clearAttachmentOnTargetRow() {
    final idx = _targetRowIndexForMedia();
    setState(() {
      final row = _rows[idx];
      row.attachmentPath = null;
      row.attachmentKind = null;
    });
  }

  void _addRow() {
    setState(() => _rows.add(AddFactRowModel()));
  }

  void _removeRowAt(int index) {
    if (_rows.length <= 1) return;
    if (index < 0 || index >= _rows.length) return;
    final removed = _rows[index];
    setState(() {
      _rows.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  void _removeRowOnMinusPressed() {
    final idx = addFactIndexToRemoveOnMinus(
      rowCount: _rows.length,
      focusContext: FocusManager.instance.primaryFocus?.context,
      hostKeys: _hostKeys,
    );
    if (idx != null) {
      _removeRowAt(idx);
    }
  }

  void _resetForm() {
    if (!mounted) return;
    final oldRows = List<AddFactRowModel>.from(_rows);
    setState(() {
      _rows
        ..clear()
        ..addAll([AddFactRowModel(), AddFactRowModel()]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final r in oldRows) {
        r.dispose();
      }
    });
  }

  void _onTapOutsideForm(PointerDownEvent event) {
    if (_submitting || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_recordingVoice) {
      unawaited(_discardRecordingAndResetForm());
      return;
    }
    _resetForm();
  }

  Future<void> _discardRecordingAndResetForm() async {
    await _cancelVoiceRecording();
    if (mounted) _resetForm();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (_submitting || _recordingVoice) return;

    for (var i = 0; i < _rows.length; i++) {
      if (!addFactRowIsSatisfied(_rows[i])) {
        _snack(loc.addFactEntryNeedsContent);
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final entries = <Map<String, dynamic>>[];

      for (var i = 0; i < _rows.length; i++) {
        final row = _rows[i];
        final cidBase = '${DateTime.now().microsecondsSinceEpoch}-$i';
        String? imgId;
        String? vidId;
        String? audId;
        final path = row.attachmentPath;
        final kind = row.attachmentKind;
        if (path != null && kind != null) {
          final id = await MediaService.upload(
            filePath: path,
            slotKind: kind,
            clientId: '$cidBase-att',
          );
          if (id == null) {
            if (mounted) _snack(loc.addFactUploadFailed);
            return;
          }
          switch (kind) {
            case MediaSlotKind.image:
              imgId = id;
            case MediaSlotKind.video:
              vidId = id;
            case MediaSlotKind.audio:
              audId = id;
          }
        }
        entries.add(
          AddFactPayload.buildEntryJson(
            text: row.content.text,
            imageId: imgId,
            videoId: vidId,
            audioId: audId,
          ),
        );
      }

      final userNamesByRow = _rows.map((r) {
        final t = r.fieldName.text.trim();
        return t.isEmpty ? null : t;
      }).toList();

      final fields = AddFactPayload.resolveFieldLabels(
        entryCount: _rows.length,
        userNamesByRow: userNamesByRow,
        deckFields: widget.deck.fields,
        fallbackForIndex: loc.addFactFieldFallback,
      );

      final body = AddFactPayload.buildFactBody(
        entries: entries,
        fields: fields,
      );
      final res = await CardService.addFacts(widget.deck.id, 'append', body);
      if (!mounted) return;
      if (res?.isSuccess == true) {
        await ref.read(deckListProvider.notifier).onRefresh();
        final refreshStudy = widget.onStudyQueueRefresh;
        if (refreshStudy != null) {
          await refreshStudy();
        }
        if (!mounted) return;
        _resetForm();
        _snack(loc.addFactSuccess);
      } else {
        _snack(res?.msg ?? loc.addFactFailed);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Iterable<Widget> _buildEntryRows(
    AppLocalizations loc,
    ThemeData theme,
    Color outline,
  ) sync* {
    for (final row in _rows) {
      yield Padding(
        key: row.hostKey,
        padding: const EdgeInsets.only(bottom: 10),
        child: AddFactEntryRow(
          key: ObjectKey(row),
          row: row,
          loc: loc,
          theme: theme,
          outlineColor: outline,
          onClearRowAttachment: () {
            setState(() {
              row.attachmentPath = null;
              row.attachmentKind = null;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMediaOnTargetRow = _rows[_targetRowIndexForMedia()].hasAttachment;
    final outline = theme.colorScheme.outline.withValues(alpha: 0.5);

    return TapRegion(
      onTapOutside: _onTapOutsideForm,
      child: ColoredBox(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddFactMediaToolbar(
              loc: loc,
              theme: theme,
              hasMediaOnTargetRow: hasMediaOnTargetRow,
              onPickFiles: _pickMediaForTargetRow,
              onPickGallery: _pickGalleryMediaForTargetRow,
              onClearTargetAttachment: _clearAttachmentOnTargetRow,
              voiceRecorder: _voiceRecorder,
              mediaPicksLocked: _recordingVoice,
              showVoiceRecord: _voiceRecordingAvailable,
              isRecordingVoice: _recordingVoice,
              onVoiceRecordTap: _voiceRecordingAvailable
                  ? _toggleVoiceRecording
                  : null,
              onVoiceRecordLongPress: _voiceRecordingAvailable
                  ? _onVoiceRecordLongPress
                  : null,
            ),
            ..._buildEntryRows(loc, theme, outline),
            AddFactRowControls(
              loc: loc,
              theme: theme,
              rowCount: _rows.length,
              onAddRow: _addRow,
              onRemoveRow: _removeRowOnMinusPressed,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (_submitting || _recordingVoice) ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.addFactSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async' show unawaited;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/focus.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/screen/deck/fact_add_composer/payload.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/screen/deck/fact_add_composer/toolbars.dart';
import 'package:retentio/screen/deck/providers/card_audio_mic_handoff.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:record/record.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/utils/media_client_id.dart';

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

class _FactAddState extends ConsumerState<FactAdd>
    with MediaHandlingCoordinator<FactAdd> {
  late List<AddFactRowModel> _rows;

  bool _submitting = false;
  bool _recordingVoice = false;
  late final RecorderController _voiceRecorder;
  late final AudioRecorder _iosPackageVoiceRecorder;

  List<GlobalKey> get _hostKeys => [for (final r in _rows) r.hostKey];

  @override
  RecorderController get voiceRecorder => _voiceRecorder;

  @override
  AudioRecorder? get iosPackageVoiceRecorder => _iosPackageVoiceRecorder;

  @override
  bool get isRecordingVoice => _recordingVoice;

  @override
  set isRecordingVoice(bool value) => _recordingVoice = value;

  @override
  List<GlobalKey> get mediaTargetHostKeys => _hostKeys;

  @override
  Future<void> prepareForExternalMicRecording() async {
    await ref.read(cardAudioMicHandoffProvider.notifier).pauseAllForMic();
  }

  @override
  void initState() {
    super.initState();
    _rows = AddFactRowModel.listForDeckFields(widget.deck.fields);
    _voiceRecorder = RecorderController();
    _iosPackageVoiceRecorder = AudioRecorder();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    unawaited(_iosPackageVoiceRecorder.dispose());
    _voiceRecorder.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void showComposerSnack(String message) => _snack(message);

  @override
  void attachPathOnTargetRow(MediaSlotKind kind, String path) {
    final idx = targetRowIndexForMedia();
    setState(() {
      _rows[idx].setPathFor(kind, path);
    });
  }

  @override
  bool get targetRowHasAttachment =>
      _rows[targetRowIndexForMedia()].hasAttachment;

  @override
  void clearTargetRowAttachment() {
    final idx = targetRowIndexForMedia();
    setState(() {
      _rows[idx].clearAllAttachments();
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
        ..addAll(AddFactRowModel.listForDeckFields(widget.deck.fields));
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
    await cancelVoiceRecording();
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
        String? imgId;
        String? vidId;
        String? audId;
        String? jsonId;

        Future<bool> uploadIfPresent(
          String? path,
          MediaSlotKind kind,
          void Function(String id) assign,
        ) async {
          if (path == null) return true;
          final id = await MediaService.upload(
            filePath: path,
            slotKind: kind,
            clientId: newMediaClientId(),
          );
          if (id == null) return false;
          assign(id);
          return true;
        }

        if (!await uploadIfPresent(
              row.imagePath,
              MediaSlotKind.image,
              (id) => imgId = id,
            ) ||
            !await uploadIfPresent(
              row.videoPath,
              MediaSlotKind.video,
              (id) => vidId = id,
            ) ||
            !await uploadIfPresent(
              row.audioPath,
              MediaSlotKind.audio,
              (id) => audId = id,
            ) ||
            !await uploadIfPresent(
              row.jsonPath,
              MediaSlotKind.json,
              (id) => jsonId = id,
            )) {
          if (mounted) _snack(loc.addFactUploadFailed);
          return;
        }

        entries.add(
          AddFactPayload.buildEntryJson(
            text: row.content.text,
            imageId: imgId,
            videoId: vidId,
            audioId: audId,
            jsonId: jsonId,
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
          onClearSlot: (kind) {
            setState(() => row.clearSlot(kind));
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMediaOnTargetRow = _rows[targetRowIndexForMedia()].hasAttachment;
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
              onPickFiles: pickMediaForTargetRow,
              onPickGallery: pickGalleryMediaForTargetRow,
              onClearTargetAttachment: clearTargetRowAttachment,
              voiceRecorder: _voiceRecorder,
              mediaPicksLocked: _recordingVoice,
              showVoiceRecord: voiceRecordingAvailable,
              isRecordingVoice: _recordingVoice,
              onVoiceRecordTap: voiceRecordingAvailable
                  ? toggleVoiceRecording
                  : null,
              onVoiceRecordLongPress: voiceRecordingAvailable
                  ? onVoiceRecordLongPress
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

import 'dart:async' show unawaited;
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/fact_edit_logic.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/screen/deck/providers/card_audio_mic_handoff.dart';
import 'package:retentio/screen/deck/fact_add_composer/toolbars.dart';
import 'package:record/record.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../../models/deck.dart';
import '../../../models/fact.dart';
import '../../../services/apis/card_service.dart';
import '../../../services/apis/deck_service.dart';
import '../../../utils/media_client_id.dart';

const _kEditOutlineAlpha = 0.62;
const _kEditCardPadding = EdgeInsets.fromLTRB(14, 12, 14, 8);
const _kEditCardSurfaceAlpha = 0.35;
const _kEditCardBorderAlpha = 0.3;
const _kEditCardRadius = 16.0;
const _kEditEntryRowBottomPadding = EdgeInsets.only(bottom: 10);
const _kEditRowsTopSpacing = 4.0;
const _kEditSubmitTopSpacing = 2.0;
const _kEditLoadingPadding = EdgeInsets.all(24);

class FactEdit extends StatefulHookConsumerWidget {
  const FactEdit({
    super.key,
    required this.deck,
    required this.factId,
    required this.onSaved,
  });

  final Deck deck;
  final String factId;
  final Future<void> Function() onSaved;

  @override
  ConsumerState<FactEdit> createState() => _FactEditState();
}

class _FactEditState extends ConsumerState<FactEdit>
    with MediaHandlingCoordinator<FactEdit> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Fact? _loaded;
  Deck? _deckForFields;
  List<FactEditRowModel>? _rows;

  bool _recordingVoice = false;
  late final RecorderController _voiceRecorder;
  late final AudioRecorder _iosPackageVoiceRecorder;

  List<GlobalKey> get _hostKeys => [for (final r in _rows ?? []) r.row.hostKey];

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
    _voiceRecorder = RecorderController();
    _iosPackageVoiceRecorder = AudioRecorder();
    FocusManager.instance.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFact());
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFact() async {
    final factFuture = CardService.getFact(widget.deck.id, widget.factId);
    final deckFuture = DeckService.of.getDeckDetail(widget.deck.id);

    final fact = await factFuture;
    Deck deckForFields = widget.deck;
    try {
      deckForFields = await deckFuture;
    } catch (_) {
      // Fall back to the deck snapshot passed into the sheet.
    }

    if (!mounted) return;
    if (fact == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load fact';
      });
      return;
    }
    if (fact.entries.isEmpty && deckForFields.fields.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Fact has no entries';
      });
      return;
    }

    final rows = buildFactEditRowsFromFact(
      fact: fact,
      deckFields: deckForFields.fields,
    );

    setState(() {
      _loaded = fact;
      _deckForFields = deckForFields;
      _rows = rows;
      _loading = false;
      _error = null;
    });
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
    final rows = _rows;
    if (rows == null) return;
    final idx = targetRowIndexForMedia();
    final row = rows[idx];
    setState(() {
      row.row.setPathFor(kind, path);
      row.clearExistingFor(kind);
    });
  }

  @override
  bool get targetRowHasAttachment {
    final rows = _rows;
    if (rows == null) return false;
    return factEditRowHasAttachment(rows[targetRowIndexForMedia()]);
  }

  @override
  void clearTargetRowAttachment() {
    final rows = _rows;
    if (rows == null) return;
    final idx = targetRowIndexForMedia();
    setState(() {
      rows[idx].clearAllAttachments();
    });
  }

  Future<String?> _resolveMediaIdForSubmit(
    FactEditRowModel row,
    MediaSlotKind kind,
  ) async {
    final path = row.row.pathFor(kind);
    final existingId = row.existingFor(kind);
    if (path == null || path.trim().isEmpty) return existingId;

    final file = File(path);
    if (await file.exists()) {
      return MediaService.upload(
        filePath: path,
        slotKind: kind,
        clientId: newMediaClientId(),
      );
    }
    // Not a local file path (existing id/url seeded in row path) -> keep as-is.
    return path;
  }

  String _fieldFallbackLabel(int index) {
    final loc = AppLocalizations.of(context)!;
    return loc.addFactFieldFallback(index);
  }

  Future<void> _onSave() async {
    final loaded = _loaded;
    final rows = _rows;
    final loc = AppLocalizations.of(context)!;
    if (loaded == null || rows == null) return;
    if (_submitting || _recordingVoice) return;

    for (var i = 0; i < rows.length; i++) {
      if (!factEditRowHasAnyContent(rows[i])) {
        _snack(loc.addFactEntryNeedsContent);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final entries = <FactEntry>[];
      for (final row in rows) {
        final imageId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.image,
        );
        if (!mounted) return;
        if (row.row.imagePath != null && imageId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        final videoId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.video,
        );
        if (!mounted) return;
        if (row.row.videoPath != null && videoId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        final audioId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.audio,
        );
        if (!mounted) return;
        if (row.row.audioPath != null && audioId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        entries.add(
          FactEntry(
            text: row.row.content.text.trim(),
            image: imageId ?? '',
            video: videoId ?? '',
            audio: audioId ?? '',
          ),
        );
      }

      final fields = factEditResolveFields(
        rows: rows,
        deck: _deckForFields ?? widget.deck,
        fallbackForIndex: _fieldFallbackLabel,
      );

      final merged = Fact(id: loaded.id, entries: entries, fields: fields);
      final res = await CardService.updateFact(
        widget.deck.id,
        merged.id,
        merged.toUpdateBody(),
      );
      if (!mounted) return;
      if (res?.isSuccess != true) {
        _snack(res?.msg ?? loc.addFactFailed);
        return;
      }
      await widget.onSaved();
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Iterable<Widget> _buildEntryRows(
    AppLocalizations loc,
    ThemeData theme,
    Color outline,
  ) sync* {
    final rows = _rows!;
    for (final model in rows) {
      yield Padding(
        key: model.row.hostKey,
        padding: _kEditEntryRowBottomPadding,
        child: AddFactEntryRow(
          key: ObjectKey(model.row),
          row: model.row,
          loc: loc,
          theme: theme,
          outlineColor: outline,
          onClearSlot: (kind) {
            setState(() {
              model.row.clearSlot(kind);
              model.clearExistingFor(kind);
            });
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    unawaited(_iosPackageVoiceRecorder.dispose());
    _voiceRecorder.dispose();
    for (final model in _rows ?? <FactEditRowModel>[]) {
      model.row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Padding(
          padding: _kEditLoadingPadding,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return SafeArea(
        child: Padding(
          padding: _kEditLoadingPadding,
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = _rows!;
    final hasMediaOnTargetRow = factEditRowHasAttachment(
      rows[targetRowIndexForMedia()],
    );
    final outline = scheme.outline.withValues(alpha: _kEditOutlineAlpha);
    return SafeArea(
      child: FocusTraversalGroup(
        child: Container(
          padding: _kEditCardPadding,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: _kEditCardSurfaceAlpha),
            border: Border.all(
              color: scheme.outline.withValues(alpha: _kEditCardBorderAlpha),
            ),
            borderRadius: BorderRadius.circular(_kEditCardRadius),
          ),
          child: Column(
            spacing: 12,
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
              const SizedBox(height: _kEditRowsTopSpacing),
              ..._buildEntryRows(loc, theme, outline),
              const SizedBox(height: _kEditSubmitTopSpacing),
              AppButton(
                label: loc.addFactSubmit,
                onPressed: _recordingVoice || _submitting ? null : _onSave,
                variant: AppButtonVariant.primary,
                fullWidth: true,
                isLoading: _submitting,
                leading: const Icon(LucideIcons.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

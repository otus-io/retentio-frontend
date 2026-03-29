import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/fact_edit_logic.dart';
import 'package:retentio/screen/deck/fact_add_composer/focus.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/screen/deck/fact_add_composer/toolbars.dart';
import 'package:retentio/services/apis/media_service.dart';

import '../../../models/deck.dart';
import '../../../models/fact.dart';
import '../../../providers/loading_state_provider.dart';
import '../../../services/apis/card_service.dart';
import '../../decks/widgets/deck_loading_state.dart';

class FactEdit extends ConsumerStatefulWidget {
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
  String? _error;
  Fact? _loaded;
  List<FactEditRowModel>? _rows;

  bool _recordingVoice = false;
  late final RecorderController _voiceRecorder;

  List<GlobalKey> get _hostKeys => [for (final r in _rows ?? []) r.row.hostKey];

  @override
  RecorderController get voiceRecorder => _voiceRecorder;

  @override
  bool get isRecordingVoice => _recordingVoice;

  @override
  set isRecordingVoice(bool value) => _recordingVoice = value;

  @override
  List<GlobalKey> get mediaTargetHostKeys => _hostKeys;

  @override
  void initState() {
    super.initState();
    _voiceRecorder = RecorderController();
    FocusManager.instance.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFact());
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFact() async {
    final fact = await CardService.getFact(widget.deck.id, widget.factId);
    if (!mounted) return;
    if (fact == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load fact';
      });
      return;
    }
    if (fact.entries.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Fact has no entries';
      });
      return;
    }

    final rows = List<FactEditRowModel>.generate(fact.entries.length, (i) {
      final entry = fact.entries[i];
      final initialFieldName = i < fact.fields.length ? fact.fields[i] : null;
      final row = AddFactRowModel(initialFieldName: initialFieldName);
      row.content.text = entry.text;
      return FactEditRowModel(
        row: row,
        existingImageId: entry.image.trim().isEmpty ? null : entry.image.trim(),
        existingVideoId: entry.video.trim().isEmpty ? null : entry.video.trim(),
        existingAudioId: entry.audio.trim().isEmpty ? null : entry.audio.trim(),
        existingJsonId: entry.json.trim().isEmpty ? null : entry.json.trim(),
      )..seedRowAttachmentPathsFromExisting();
    });

    setState(() {
      _loaded = fact;
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

  void _addRow() {
    final rows = _rows;
    if (rows == null) return;
    setState(() {
      rows.add(FactEditRowModel(row: AddFactRowModel()));
    });
  }

  void _removeRowAt(int index) {
    final rows = _rows;
    if (rows == null || rows.length <= 1) return;
    if (index < 0 || index >= rows.length) return;
    final removed = rows[index];
    setState(() {
      rows.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.row.dispose();
    });
  }

  void _removeRowOnMinusPressed() {
    final rows = _rows;
    if (rows == null) return;
    final idx = addFactIndexToRemoveOnMinus(
      rowCount: rows.length,
      focusContext: FocusManager.instance.primaryFocus?.context,
      hostKeys: _hostKeys,
    );
    if (idx != null) {
      _removeRowAt(idx);
    }
  }

  Future<String?> _resolveMediaIdForSubmit(
    FactEditRowModel row,
    MediaSlotKind kind,
    String cidBase,
    String cidTag,
  ) async {
    final path = row.row.pathFor(kind);
    final existingId = row.existingFor(kind);
    if (path == null || path.trim().isEmpty) return existingId;

    final file = File(path);
    if (await file.exists()) {
      return MediaService.upload(
        filePath: path,
        slotKind: kind,
        clientId: '$cidBase-$cidTag',
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

    for (var i = 0; i < rows.length; i++) {
      if (!factEditRowHasAnyContent(rows[i])) {
        _snack(loc.addFactEntryNeedsContent);
        return;
      }
    }

    ref.read(loadingStateProvider.notifier).showLoading();
    try {
      final entries = <FactEntry>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final cidBase = '${DateTime.now().microsecondsSinceEpoch}-$i';

        final imageId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.image,
          cidBase,
          'img',
        );
        if (!mounted) return;
        if (row.row.imagePath != null && imageId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        final videoId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.video,
          cidBase,
          'vid',
        );
        if (!mounted) return;
        if (row.row.videoPath != null && videoId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        final audioId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.audio,
          cidBase,
          'aud',
        );
        if (!mounted) return;
        if (row.row.audioPath != null && audioId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        final jsonId = await _resolveMediaIdForSubmit(
          row,
          MediaSlotKind.json,
          cidBase,
          'json',
        );
        if (!mounted) return;
        if (row.row.jsonPath != null && jsonId == null) {
          _snack(loc.addFactUploadFailed);
          return;
        }

        entries.add(
          FactEntry(
            text: row.row.content.text.trim(),
            image: imageId ?? '',
            video: videoId ?? '',
            audio: audioId ?? '',
            json: jsonId ?? '',
          ),
        );
      }

      final fields = factEditResolveFields(
        rows: rows,
        deck: widget.deck,
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
      ref.read(loadingStateProvider.notifier).showLoaded();
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
        padding: const EdgeInsets.only(bottom: 10),
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
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = _rows!;
    final hasMediaOnTargetRow = factEditRowHasAttachment(
      rows[targetRowIndexForMedia()],
    );
    final outline = theme.colorScheme.outline.withValues(alpha: 0.5);
    return SafeArea(
      child: FocusTraversalGroup(
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
            ..._buildEntryRows(loc, theme, outline),
            AddFactRowControls(
              loc: loc,
              theme: theme,
              rowCount: rows.length,
              onAddRow: _addRow,
              onRemoveRow: _removeRowOnMinusPressed,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _recordingVoice ? null : _onSave,
                child: Row(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DeckLoadingState(child: Icon(LucideIcons.save)),
                    Text(loc.addFactSubmit),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/features/tags/widgets/tag_chip.dart';
import 'package:retentio/features/tags/widgets/tag_picker_sheet.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/fact_edit_logic.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/screen/deck/providers/card_audio_mic_handoff.dart';
import 'package:retentio/screen/deck/fact_add_composer/toolbars.dart';
import 'package:record/record.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/services/apis/tag_service.dart';
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

  // ── tag state ────────────────────────────────────────────
  Set<String> _originalTagIds = {};
  Set<String> _selectedTagIds = {};
  List<Tag> _selectedTags = [];

  bool _recordingVoice = false;
  late final AudioRecorder _voiceRecorder;

  List<GlobalKey> get _hostKeys => [for (final r in _rows ?? []) r.row.hostKey];

  @override
  AudioRecorder get voiceRecorder => _voiceRecorder;

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
    _voiceRecorder = AudioRecorder();
    FocusManager.instance.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFact());
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFact() async {
    final deckFuture = DeckService.of
        .getDeckDetail(widget.deck.id)
        .catchError((_) => widget.deck);

    final tagsFuture = TagService.of
        .getFactTags(widget.deck.id, widget.factId)
        .catchError((_) => <Tag>[]);

    Fact? fact;
    try {
      fact = await CardService.getFact(widget.deck.id, widget.factId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load fact';
      });
      return;
    }

    final deckForFields = await deckFuture;
    final existingTags = await tagsFuture;
    final existingIds = existingTags.map((t) => t.id).toSet();

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
      _selectedTags = existingTags;
      _selectedTagIds = existingIds;
      _originalTagIds = Set.of(existingIds);
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

  Future<void> _openTagPicker() async {
    final result = await showTagPickerSheet(
      context,
      selectedIds: _selectedTagIds,
    );
    if (result == null || !mounted) return;
    final allTags = context.read<TagManagerCubit>().state.tags;
    final resolved = result
        .map(
          (id) => allTags.firstWhere(
            (t) => t.id == id,
            orElse: () => Tag(id: id, name: id, description: ''),
          ),
        )
        .toList();
    setState(() {
      _selectedTagIds = result;
      _selectedTags = resolved;
    });
  }

  Future<void> _syncTags() async {
    final toAdd = _selectedTagIds.difference(_originalTagIds);
    final toRemove = _originalTagIds.difference(_selectedTagIds);
    await Future.wait([
      ...toAdd.map(
        (id) => TagService.of.addTagToFact(widget.deck.id, widget.factId, id),
      ),
      ...toRemove.map(
        (id) =>
            TagService.of.removeTagFromFact(widget.deck.id, widget.factId, id),
      ),
    ]);
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
      // Sync tags (fire-and-forget, non-blocking on UI).
      unawaited(_syncTags());
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
    unawaited(_voiceRecorder.dispose());
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
              _FactEditTagRow(
                selectedTags: _selectedTags,
                onRemove: (tagId) {
                  setState(() {
                    _selectedTagIds.remove(tagId);
                    _selectedTags.removeWhere((t) => t.id == tagId);
                  });
                },
                onPickTags: _openTagPicker,
              ),
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

// ── Tag row widget ────────────────────────────────────────────────────────────

class _FactEditTagRow extends StatelessWidget {
  const _FactEditTagRow({
    required this.selectedTags,
    required this.onRemove,
    required this.onPickTags,
  });

  final List<Tag> selectedTags;
  final void Function(String tagId) onRemove;
  final VoidCallback onPickTags;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(LucideIcons.tag, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        if (selectedTags.isEmpty)
          Expanded(
            child: Text(
              loc.tagLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Expanded(
            child: TagChipRow(tags: selectedTags, onRemove: onRemove),
          ),
        TextButton.icon(
          onPressed: onPickTags,
          icon: const Icon(LucideIcons.plus, size: 14),
          label: Text(loc.addTag),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

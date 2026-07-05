import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/features/tags/widgets/tag_chip.dart';
import 'package:retentio/features/tags/widgets/tag_picker_sheet.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
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
import 'package:retentio/widgets/app_button.dart';

const _kComposerOutlineAlpha = 0.62;
const _kComposerCardPadding = EdgeInsets.fromLTRB(14, 12, 14, 8);
const _kComposerCardSurfaceAlpha = 0.35;
const _kComposerCardBorderAlpha = 0.3;
const _kComposerCardRadius = 16.0;
const _kEntryRowBottomPadding = EdgeInsets.only(bottom: 10);
const _kToolbarRowsSpacing = 6.0;
const _kSubmitTopSpacing = 16.0;

class FactAdd extends StatefulHookConsumerWidget {
  const FactAdd({super.key, required this.deck, this.onStudyQueueRefresh});

  final Deck deck;

  /// Refresh the current study card queue (via DeckStudy BLoC). Must be supplied
  /// from a [WidgetRef] scoped under [currentDeckProvider] — the modal sheet is
  /// not, so this widget cannot trigger the refresh by itself.
  final Future<void> Function()? onStudyQueueRefresh;

  @override
  ConsumerState<FactAdd> createState() => _FactAddState();
}

class _FactAddState extends ConsumerState<FactAdd>
    with MediaHandlingCoordinator<FactAdd> {
  late List<AddFactRowModel> _rows;

  bool _submitting = false;
  bool _recordingVoice = false;
  late final AudioRecorder _voiceRecorder;

  // ── tag state ────────────────────────────────────────────
  Set<String> _selectedTagIds = {};
  List<Tag> _selectedTags = [];

  List<GlobalKey> get _hostKeys => [for (final r in _rows) r.hostKey];

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
    _rows = AddFactRowModel.listForDeckFields(widget.deck.fields);
    _voiceRecorder = AudioRecorder();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    unawaited(_voiceRecorder.dispose());
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

  void _resetForm() {
    if (!mounted) return;
    final oldRows = List<AddFactRowModel>.from(_rows);
    setState(() {
      _rows
        ..clear()
        ..addAll(AddFactRowModel.listForDeckFields(widget.deck.fields));
      _selectedTagIds = {};
      _selectedTags = [];
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

        Future<bool> uploadIfPresent(
          String? path,
          MediaSlotKind kind,
          void Function(String id) assign,
        ) async {
          if (path == null) return true;
          final id = await MediaService.upload(
            deckId: widget.deck.id,
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
          ),
        );
      }
      final tagNames = _selectedTags.map((t) => t.name).toList();
      final body = AddFactPayload.buildFactBody(
        entries: entries,
        tagNames: tagNames.isNotEmpty ? tagNames : null,
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
        padding: _kEntryRowBottomPadding,
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
    final scheme = theme.colorScheme;
    final hasMediaOnTargetRow = _rows[targetRowIndexForMedia()].hasAttachment;
    final outline = scheme.outline.withValues(alpha: _kComposerOutlineAlpha);

    return TapRegion(
      onTapOutside: _onTapOutsideForm,
      child: ColoredBox(
        color: Colors.transparent,
        child: Container(
          padding: _kComposerCardPadding,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: _kComposerCardSurfaceAlpha),
            border: Border.all(
              color: scheme.outline.withValues(
                alpha: _kComposerCardBorderAlpha,
              ),
            ),
            borderRadius: BorderRadius.circular(_kComposerCardRadius),
          ),
          child: Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: _kToolbarRowsSpacing),
              ..._buildEntryRows(loc, theme, outline),
              const SizedBox(height: _kToolbarRowsSpacing),
              _FactTagRow(
                selectedTags: _selectedTags,
                onRemove: (tagId) {
                  setState(() {
                    _selectedTagIds.remove(tagId);
                    _selectedTags.removeWhere((t) => t.id == tagId);
                  });
                },
                onPickTags: _openTagPicker,
              ),
              const SizedBox(height: _kSubmitTopSpacing),
              AppButton(
                label: loc.addFactSubmit,
                onPressed: _recordingVoice ? null : _submit,
                variant: AppButtonVariant.primary,
                fullWidth: true,
                isLoading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag row widget ────────────────────────────────────────────────────────────

class _FactTagRow extends StatelessWidget {
  const _FactTagRow({
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

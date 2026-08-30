import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/fact_quality.dart';
import 'package:retentio/screen/deck/fact_add_composer/fact_edit_logic.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_edit.dart';
import 'package:retentio/screen/qa/qa_mode_cubit.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/app_toast.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

const _kQaPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
const _kQaMessagePadding = EdgeInsets.all(24);

/// Playable URL for a pinned snapshot audio id.
///
/// Prefer [mediaVersions] (snapshot `media_versions` for this id). Falling back
/// to [sourceVersion] is wrong when the blob was copy-on-write at an older
/// publish (curl evidence: `?v=1` 200, `?v=19` 404).
String? qaAudioUrl({
  required String audioId,
  required int sourceVersion,
  Map<String, int> mediaVersions = const {},
}) {
  final id = audioId.trim();
  if (id.isEmpty) return null;
  if (id.startsWith('http://') ||
      id.startsWith('https://') ||
      id.startsWith('/')) {
    return id;
  }
  final pinned = mediaVersions[id];
  final resolved = (pinned != null && pinned > 0) ? pinned : sourceVersion;
  return resolved > 0 ? '/api/media/$id?v=$resolved' : '/api/media/$id';
}

/// Human QA walk over an imported deck: sign off columns, edit the bad ones.
class QaModeScreen extends StatelessWidget {
  const QaModeScreen({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QaModeCubit>(
      create: (_) => QaModeCubit(
        deckId: deck.id,
        deckFieldCount: deck.fields.isNotEmpty ? deck.fields.length : 1,
      ),
      child: _QaModeView(deck: deck),
    );
  }
}

class _QaModeView extends StatelessWidget {
  const _QaModeView({required this.deck});

  final Deck deck;

  String _fieldLabel(BuildContext context, int index) {
    final loc = AppLocalizations.of(context)!;
    if (index >= 0 && index < deck.fields.length) {
      final name = deck.fields[index].trim();
      if (name.isNotEmpty) return name;
    }
    return loc.addFactFieldFallback(index + 1);
  }

  String _label(BuildContext context, QaModeState state, int index) {
    return factEditInitialFieldName(
          index: index,
          deckFields: deck.fields,
          factFields: state.fact?.fields ?? const [],
        ) ??
        _fieldLabel(context, index);
  }

  Future<void> _next(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final cubit = context.read<QaModeCubit>();
    final error = await cubit.next();
    if (!context.mounted || error == null) return;
    AppToast.error(context, ApiErrorMessages.resolve(error, loc));
  }

  Future<void> _edit(BuildContext context, int entryIndex) async {
    final loc = AppLocalizations.of(context)!;
    final cubit = context.read<QaModeCubit>();
    final factId = cubit.state.factId;
    if (factId == null) return;
    await showCommonBottomSheet<void>(
      context: context,
      fullScreen: true,
      title: loc.editFact,
      child: BlocProvider<TagManagerCubit>(
        create: (_) =>
            TagManagerCubit(usedOn: 'fact', deckId: deck.id)..loadTags(),
        child: FactEdit(
          deck: deck,
          factId: factId,
          onSaved: () async {
            final error = await cubit.submitEdit(entryIndex: entryIndex);
            if (!context.mounted) return;
            if (error == null) {
              AppToast.success(context, loc.qaEditSubmitted);
            } else {
              AppToast.error(context, ApiErrorMessages.resolve(error, loc));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.qaMode),
        actions: [
          BlocBuilder<QaModeCubit, QaModeState>(
            buildWhen: (prev, next) =>
                prev.pickingColumns != next.pickingColumns ||
                prev.activeColumnIndexes != next.activeColumnIndexes,
            builder: (context, state) {
              if (state.pickingColumns) return const SizedBox.shrink();
              return AppIconButton(
                icon: LucideIcons.columns3,
                tooltip: loc.qaModeChooseColumns,
                variant: AppIconButtonVariant.subtle,
                onPressed: () =>
                    context.read<QaModeCubit>().reopenColumnPicker(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<QaModeCubit, QaModeState>(
          builder: (context, state) {
            if (state.pickingColumns) {
              return _QaColumnPicker(
                deck: deck,
                fieldLabel: (index) => _fieldLabel(context, index),
              );
            }
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.factIds.isEmpty) {
              return _QaMessage(text: loc.qaModeEmpty);
            }
            if (state.factLoadFailed) {
              return _QaMessage(text: loc.qaModeFactLoadFailed);
            }
            final visibleIndexes = [
              for (var i = 0; i < state.entries.length; i++)
                if (state.activeColumnIndexes.contains(i)) i,
            ];
            return Column(
              children: [
                _QaHeader(
                  state: state,
                  deck: deck,
                  fieldLabel: (index) => _fieldLabel(context, index),
                ),
                Expanded(
                  child: ListView(
                    padding: _kQaPadding,
                    children: [
                      for (final i in visibleIndexes)
                        _QaColumnRow(
                          entry: state.entries[i],
                          label: _label(context, state, i),
                          audioUrl: qaAudioUrl(
                            audioId: state.entries[i].audio,
                            sourceVersion: deck.sourceVersion,
                            mediaVersions: state.mediaVersions,
                          ),
                          checked: state.checkedIndexes.contains(i),
                          scoreable: qaScoreableAspects(
                            state.entries[i],
                          ).isNotEmpty,
                          onToggle: () =>
                              context.read<QaModeCubit>().toggleColumn(i),
                          onEdit: () => _edit(context, i),
                        ),
                    ],
                  ),
                ),
                _QaFooter(state: state, onNext: () => _next(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QaColumnPicker extends StatefulWidget {
  const _QaColumnPicker({required this.deck, required this.fieldLabel});

  final Deck deck;
  final String Function(int index) fieldLabel;

  @override
  State<_QaColumnPicker> createState() => _QaColumnPickerState();
}

class _QaColumnPickerState extends State<_QaColumnPicker> {
  Set<int> _selected = const {};
  bool _loading = true;

  int get _columnCount =>
      widget.deck.fields.isNotEmpty ? widget.deck.fields.length : 1;

  @override
  void initState() {
    super.initState();
    _loadPickerData();
  }

  Future<void> _loadPickerData() async {
    final cubit = context.read<QaModeCubit>();
    final fromWalk = cubit.state.activeColumnIndexes;
    final selection = fromWalk.isNotEmpty
        ? fromWalk
        : await cubit.initialColumnSelection();
    await cubit.refreshStats();
    if (!mounted) return;
    setState(() {
      _selected = Set<int>.of(selection);
      _loading = false;
    });
  }

  void _toggle(int index) {
    setState(() {
      final next = Set<int>.of(_selected);
      if (!next.remove(index)) {
        next.add(index);
      }
      _selected = next;
    });
  }

  Future<void> _start() async {
    if (_selected.isEmpty) return;
    await context.read<QaModeCubit>().startWalk(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: _kQaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(loc.qaModeChooseColumns, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            loc.qaModeChooseColumnsHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<QaModeCubit, QaModeState>(
              buildWhen: (prev, next) => prev.stats != next.stats,
              builder: (context, state) {
                return ListView(
                  children: [
                    for (var i = 0; i < _columnCount; i++)
                      CheckboxListTile(
                        value: _selected.contains(i),
                        onChanged: (_) => _toggle(i),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(widget.fieldLabel(i)),
                        secondary: Text(
                          loc.qaModeColumnPercent(
                            state.stats?.columnAt(i)?.completionPercent ?? 0,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          AppButton(
            label: loc.qaModeStartWalk,
            fullWidth: true,
            leading: const Icon(LucideIcons.play),
            onPressed: _selected.isEmpty ? null : _start,
          ),
        ],
      ),
    );
  }
}

class _QaMessage extends StatelessWidget {
  const _QaMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _kQaMessagePadding,
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );
  }
}

class _QaHeader extends StatelessWidget {
  const _QaHeader({
    required this.state,
    required this.deck,
    required this.fieldLabel,
  });

  final QaModeState state;
  final Deck deck;
  final String Function(int index) fieldLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = state.stats;
    final activeColumns = state.activeColumnIndexes.toList()..sort();
    return Padding(
      padding: _kQaPadding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              loc.qaModeProgress(state.index + 1, state.factIds.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final index in activeColumns)
              Text(
                loc.qaModeColumnComplete(
                  fieldLabel(index),
                  stats?.columnAt(index)?.completionPercent ?? 0,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              loc.qaModeEdited(state.editedCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QaColumnRow extends StatelessWidget {
  const _QaColumnRow({
    required this.entry,
    required this.label,
    required this.audioUrl,
    required this.checked,
    required this.scoreable,
    required this.onToggle,
    required this.onEdit,
  });

  final FactEntry entry;
  final String label;
  final String? audioUrl;
  final bool checked;
  final bool scoreable;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = <Item>[
      if (entry.text.trim().isNotEmpty) Item(type: 'text', value: entry.text),
      if (audioUrl != null) Item(type: 'audio', value: audioUrl!),
    ];
    return CheckboxListTile(
      value: checked,
      onChanged: scoreable ? (_) => onToggle() : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: items.isEmpty
          ? Text(
              loc.qaModeColumnEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : FactContent(
              items: items,
              color: theme.colorScheme.onSurface,
              inline: true,
            ),
      secondary: AppIconButton(
        icon: LucideIcons.pencil,
        onPressed: onEdit,
        variant: AppIconButtonVariant.subtle,
        tooltip: loc.editFact,
      ),
    );
  }
}

class _QaFooter extends StatelessWidget {
  const _QaFooter({required this.state, required this.onNext});

  final QaModeState state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cubit = context.read<QaModeCubit>();
    final ready = state.canAdvance;
    return Padding(
      padding: _kQaPadding,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: loc.qaModePrevious,
                  size: AppButtonSize.sm,
                  variant: !ready && state.hasPrev
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  onPressed: state.hasPrev && !state.busy ? cubit.prev : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: loc.next,
                  size: AppButtonSize.sm,
                  variant: ready
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  onPressed: state.hasNext && ready && !state.busy
                      ? onNext
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AbsorbPointer(
            child: AppButton(
              label: loc.qaModeVerify,
              fullWidth: true,
              isLoading: state.busy,
              leading: const Icon(LucideIcons.badgeCheck),
              onPressed: ready && !state.busy ? () {} : null,
              variant: ready
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

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
      create: (_) => QaModeCubit(deckId: deck.id)..load(),
      child: _QaModeView(deck: deck),
    );
  }
}

class _QaModeView extends StatelessWidget {
  const _QaModeView({required this.deck});

  final Deck deck;

  String _label(BuildContext context, QaModeState state, int index) {
    final loc = AppLocalizations.of(context)!;
    return factEditInitialFieldName(
          index: index,
          deckFields: deck.fields,
          factFields: state.fact?.fields ?? const [],
        ) ??
        loc.addFactFieldFallback(index + 1);
  }

  Future<void> _verify(BuildContext context, QaModeState state) async {
    final loc = AppLocalizations.of(context)!;
    final cubit = context.read<QaModeCubit>();
    final checked = state.checkedIndexes.toList()..sort();
    final confirmed = await showCommonBottomSheet<bool>(
      context: context,
      title: loc.qaVerifyConfirmTitle,
      child: _QaVerifyConfirmSheet(
        fields: checked.map((i) => _label(context, state, i)).toList(),
        payload: const JsonEncoder.withIndent(
          '  ',
        ).convert({'entries': cubit.pendingPutEntries()}),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await cubit.verify();
    if (!context.mounted) return;
    if (error == null) {
      AppToast.success(context, loc.qaVerifySuccess);
    } else {
      AppToast.error(context, ApiErrorMessages.resolve(error, loc));
    }
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
      appBar: AppBar(title: Text(loc.qaMode)),
      body: SafeArea(
        child: BlocBuilder<QaModeCubit, QaModeState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.factIds.isEmpty) {
              return _QaMessage(text: loc.qaModeEmpty);
            }
            if (state.factLoadFailed) {
              return _QaMessage(text: loc.qaModeFactLoadFailed);
            }
            return Column(
              children: [
                _QaHeader(state: state),
                Expanded(
                  child: ListView(
                    padding: _kQaPadding,
                    children: [
                      for (var i = 0; i < state.entries.length; i++)
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
                _QaFooter(
                  state: state,
                  onVerify: () => _verify(context, state),
                ),
              ],
            );
          },
        ),
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
  const _QaHeader({required this.state});

  final QaModeState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = state.stats;
    final parts = <String>[
      loc.qaModeProgress(state.index + 1, state.factIds.length),
      if (stats != null)
        loc.qaModeVerifiedAspects(stats.verifiedAspects, stats.totalAspects),
      loc.qaModeEdited(state.editedCount),
    ];
    return Padding(
      padding: _kQaPadding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          parts.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
  const _QaFooter({required this.state, required this.onVerify});

  final QaModeState state;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cubit = context.read<QaModeCubit>();
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
                  variant: AppButtonVariant.secondary,
                  onPressed: state.hasPrev && !state.busy ? cubit.prev : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: loc.next,
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  onPressed: state.hasNext && !state.busy ? cubit.next : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppButton(
            label: loc.qaModeVerify,
            fullWidth: true,
            isLoading: state.busy,
            leading: const Icon(LucideIcons.badgeCheck),
            onPressed: state.canVerify ? onVerify : null,
          ),
        ],
      ),
    );
  }
}

class _QaVerifyConfirmSheet extends StatelessWidget {
  const _QaVerifyConfirmSheet({required this.fields, required this.payload});

  final List<String> fields;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(loc.qaVerifyConfirmFields(fields.join(', '))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(payload, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: loc.cancel,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: loc.qaModeVerify,
                size: AppButtonSize.sm,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/app_toast.dart';

/// Importer outbox: stage local overlay changes, then send selected to author.
class PendingContributionsOutboxSheet extends StatefulWidget {
  const PendingContributionsOutboxSheet({
    super.key,
    required this.importDeckId,
  });

  final String importDeckId;

  @override
  State<PendingContributionsOutboxSheet> createState() =>
      _PendingContributionsOutboxSheetState();
}

enum _OutboxTab { pending, sent }

class _PendingContributionsOutboxSheetState
    extends State<PendingContributionsOutboxSheet> {
  _OutboxTab _tab = _OutboxTab.pending;
  List<PendingContributionItem> _pending = const [];
  List<SentContributionItem> _sent = const [];
  final Set<String> _selected = {};
  final _messageController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final pending = await PendingContributionsStore.of.listPending(
      widget.importDeckId,
    );
    final sent = await PendingContributionsStore.of.listSent(
      widget.importDeckId,
    );
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _sent = sent;
      _selected.removeWhere((id) => pending.every((p) => p.id != id));
      _loading = false;
      if (_tab == _OutboxTab.pending && pending.isEmpty && sent.isNotEmpty) {
        _tab = _OutboxTab.sent;
      }
    });
  }

  String _kindLabel(AppLocalizations loc, PendingContributionKind kind) {
    return switch (kind) {
      PendingContributionKind.edit => loc.pendingKindEdit,
      PendingContributionKind.add => loc.pendingKindAdd,
      PendingContributionKind.deckTags => loc.pendingKindDeckTags,
      PendingContributionKind.factTags => loc.pendingKindFactTags,
      PendingContributionKind.template => loc.pendingKindTemplate,
      PendingContributionKind.fieldRename => loc.pendingKindFieldRename,
      PendingContributionKind.report => loc.pendingKindReport,
    };
  }

  String _rowPreview(PendingContributionItem item) {
    final parts = <String>[];
    if (item.addTags != null && item.addTags!.isNotEmpty) {
      parts.add('+${item.addTags!.join(', ')}');
    }
    if (item.removeTags != null && item.removeTags!.isNotEmpty) {
      parts.add('−${item.removeTags!.join(', ')}');
    }
    if (parts.isNotEmpty) return parts.join(' · ');
    if (item.proposedFields != null && item.proposedFields!.isNotEmpty) {
      return item.proposedFields!.join(' · ');
    }
    final preview = item.preview?.trim();
    if (preview != null && preview.isNotEmpty) return preview;
    return item.factId ?? '—';
  }

  Future<void> _sendSelected() async {
    final loc = AppLocalizations.of(context)!;
    final items = _pending.where((p) => _selected.contains(p.id)).toList();
    if (items.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });
    final message = _messageController.text.trim();
    var sentCount = 0;
    final failures = <String>[];

    for (final item in items) {
      try {
        await _submitOne(item, message.isEmpty ? null : message);
        await PendingContributionsStore.of.markAsSent(
          widget.importDeckId,
          item.id,
          message: message.isEmpty ? null : message,
        );
        sentCount += 1;
      } catch (e) {
        failures.add('${_kindLabel(loc, item.kind)}: ${rawApiErrorMessage(e)}');
      }
    }

    await _refresh();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (sentCount > 0) {
        _notice = failures.isEmpty
            ? loc.pendingSendSuccess(sentCount)
            : loc.pendingSendPartial(sentCount, failures.length);
        if (failures.isEmpty) _tab = _OutboxTab.sent;
      }
      if (failures.isNotEmpty) {
        _error = failures.take(3).join(' · ');
      }
    });
  }

  Future<void> _submitOne(PendingContributionItem item, String? message) async {
    final deckId = widget.importDeckId;
    switch (item.kind) {
      case PendingContributionKind.edit:
        final factId = item.factId;
        if (factId == null || factId.isEmpty) {
          throw Exception('missing fact id');
        }
        await DeckCatalogService.of.submitFactEditContribution(
          importDeckId: deckId,
          factId: factId,
          message: message,
        );
      case PendingContributionKind.add:
        final factId = item.factId;
        if (factId == null || factId.isEmpty) {
          throw Exception('missing fact id');
        }
        await DeckCatalogService.of.submitFactAddContribution(
          importDeckId: deckId,
          factId: factId,
          message: message,
        );
      case PendingContributionKind.factTags:
        final factId = item.factId;
        if (factId == null || factId.isEmpty) {
          throw Exception('missing fact id');
        }
        await DeckCatalogService.of.submitFactTagsContribution(
          importDeckId: deckId,
          factId: factId,
          addTags: item.addTags,
          removeTags: item.removeTags,
          message: message,
        );
      case PendingContributionKind.deckTags:
        await DeckCatalogService.of.submitDeckTagsContribution(
          importDeckId: deckId,
          addTags: item.addTags,
          removeTags: item.removeTags,
          message: message,
        );
      case PendingContributionKind.report:
        throw Exception('reports are sent from fact edit');
      case PendingContributionKind.template:
      case PendingContributionKind.fieldRename:
        throw Exception('unsupported pending kind');
    }
  }

  Future<void> _dismissSelected() async {
    final loc = AppLocalizations.of(context)!;
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    for (final id in ids) {
      await PendingContributionsStore.of.remove(widget.importDeckId, id);
    }
    await _refresh();
    if (!mounted) return;
    setState(() => _notice = loc.pendingDismissed(ids.length));
  }

  Future<void> _clearAll() async {
    final loc = AppLocalizations.of(context)!;
    final n = _pending.length;
    if (n == 0) return;
    await PendingContributionsStore.of.clearPending(widget.importDeckId);
    await _refresh();
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _notice = loc.pendingCleared(n);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.pendingOutboxHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: loc.pendingTabPending(_pending.length),
                size: AppButtonSize.sm,
                variant: _tab == _OutboxTab.pending
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: _submitting
                    ? null
                    : () => setState(() => _tab = _OutboxTab.pending),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: loc.pendingTabSent(_sent.length),
                size: AppButtonSize.sm,
                variant: _tab == _OutboxTab.sent
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: _submitting
                    ? null
                    : () => setState(() => _tab = _OutboxTab.sent),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            ApiErrorMessages.resolve(_error, loc),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 8),
          Text(
            _notice!,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
          ),
        ],
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: _tab == _OutboxTab.pending
              ? _buildPendingList(loc, theme, scheme)
              : _buildSentList(loc, theme, scheme),
        ),
        if (_tab == _OutboxTab.pending && _pending.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppInput(
            controller: _messageController,
            hint: loc.contributeOptionalMessageHint,
            maxLines: 3,
            minLines: 2,
            maxLength: 2000,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: _selected.isEmpty
                ? loc.pendingSendSelected
                : loc.pendingSendSelectedCount(_selected.length),
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting || _selected.isEmpty ? null : _sendSelected,
            leading: const Icon(LucideIcons.send),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: loc.pendingDismissSelected,
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  onPressed: _submitting || _selected.isEmpty
                      ? null
                      : _dismissSelected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: loc.pendingClearAll,
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  onPressed: _submitting ? null : _clearAll,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPendingList(
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    if (_pending.isEmpty) {
      return Center(
        child: Text(
          loc.pendingEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final allSelected =
        _pending.isNotEmpty && _selected.length == _pending.length;

    return ListView(
      shrinkWrap: true,
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: allSelected,
          title: Text(loc.pendingSelectAll(_pending.length)),
          onChanged: _submitting
              ? null
              : (_) {
                  setState(() {
                    if (allSelected) {
                      _selected.clear();
                    } else {
                      _selected
                        ..clear()
                        ..addAll(_pending.map((e) => e.id));
                    }
                  });
                },
        ),
        ..._pending.map((item) {
          final checked = _selected.contains(item.id);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: checked,
            onChanged: _submitting
                ? null
                : (_) {
                    setState(() {
                      if (checked) {
                        _selected.remove(item.id);
                      } else {
                        _selected.add(item.id);
                      }
                    });
                  },
            title: Text(_kindLabel(loc, item.kind)),
            subtitle: Text(
              [
                if (item.factId != null && item.factId!.isNotEmpty)
                  item.factId!,
                _rowPreview(item),
              ].join('\n'),
              style: theme.textTheme.bodySmall,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSentList(
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    if (_sent.isEmpty) {
      return Center(
        child: Text(
          loc.pendingSentEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _sent.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = _sent[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _kindLabel(loc, item.kind),
                style: theme.textTheme.labelLarge,
              ),
              Text(
                item.sentAt.toLocal().toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (item.preview != null && item.preview!.isNotEmpty)
                Text(item.preview!, style: theme.textTheme.bodySmall),
              if (item.message != null && item.message!.isNotEmpty)
                Text(
                  item.message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Convenience toast after staging a pending item.
void showPendingStagedToast(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  AppToast.success(context, loc.pendingStaged);
}

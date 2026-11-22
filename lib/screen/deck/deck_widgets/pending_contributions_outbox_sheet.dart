import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';

/// Importer outbox: stage local overlay changes, then send selected to author.
class PendingContributionsOutboxSheet extends StatefulWidget {
  const PendingContributionsOutboxSheet({
    super.key,
    required this.importDeckId,
    this.store,
  });

  final String importDeckId;

  /// Defaults to [PendingContributionsStore.of].
  final PendingContributionsStore? store;

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

  PendingContributionsStore get _store =>
      widget.store ?? PendingContributionsStore.of;

  /// True while a dismiss or clear all runs.
  bool _removing = false;

  /// One outbox action at a time: send, dismiss and clear all each change the
  /// pending rows, so overlapping them would garble the rows and notices.
  bool get _busy => _submitting || _removing;
  String? _error;
  String? _notice;

  /// Rows that were already sent or removed, shown apart from [_notice].
  String? _skipped;

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

  /// Reloads both lists. The spinner shows only on the first load, so a
  /// reload after a send or dismiss keeps the sheet and its notices in place.
  Future<void> _refresh() async {
    final pending = await _store.listPending(widget.importDeckId);
    final sent = await _store.listSent(widget.importDeckId);
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
      PendingContributionKind.description => loc.pendingKindDescription,
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

  /// Kinds with a working outbox submit path. Others stay visible but not selectable.
  bool _isSubmittable(PendingContributionKind kind) {
    return switch (kind) {
      PendingContributionKind.edit ||
      PendingContributionKind.add ||
      PendingContributionKind.factTags ||
      PendingContributionKind.deckTags ||
      PendingContributionKind.fieldRename ||
      PendingContributionKind.description => true,
      PendingContributionKind.template ||
      PendingContributionKind.report => false,
    };
  }

  Future<void> _sendSelected() async {
    final loc = AppLocalizations.of(context)!;
    final items = _pending
        .where((p) => _selected.contains(p.id) && _isSubmittable(p.kind))
        .toList();
    if (items.isEmpty || _busy) return;
    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
      _skipped = null;
    });
    final message = _messageController.text.trim();
    var sentCount = 0;
    var skippedCount = 0;
    final failures = <String>[];

    for (final item in items) {
      try {
        // Send the row as stored now, saving a typed note on it first so a
        // failed send keeps it for the retry. A row removed meanwhile is
        // skipped.
        final current = message.isEmpty
            ? (await _store.listPending(
                widget.importDeckId,
              )).where((r) => r.id == item.id).firstOrNull
            : await _store.updateMessage(widget.importDeckId, item.id, message);
        if (current == null) {
          skippedCount += 1;
          continue;
        }
        // A note typed here wins; otherwise keep the one saved with the row.
        final note = message.isEmpty ? current.message : message;
        final contributionId = await _submitOne(current, note);
        await _store.markAsSent(
          widget.importDeckId,
          item.id,
          contributionId: contributionId,
          message: note,
        );
        sentCount += 1;
      } catch (e) {
        failures.add(
          '${_kindLabel(loc, item.kind)}: '
          '${ApiErrorMessages.resolve(rawApiErrorMessage(e), loc)}',
        );
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
      _skipped = skippedCount > 0 ? loc.pendingSkippedGone(skippedCount) : null;
    });
  }

  Future<String?> _submitOne(
    PendingContributionItem item,
    String? message,
  ) async {
    final deckId = widget.importDeckId;
    switch (item.kind) {
      case PendingContributionKind.edit:
        final factId = item.factId;
        if (factId == null || factId.isEmpty) {
          throw Exception('missing fact id');
        }
        return DeckCatalogService.of.submitFactEditContribution(
          importDeckId: deckId,
          factId: factId,
          message: message,
        );
      case PendingContributionKind.add:
        final factId = item.factId;
        if (factId == null || factId.isEmpty) {
          throw Exception('missing fact id');
        }
        return DeckCatalogService.of.submitFactAddContribution(
          importDeckId: deckId,
          factId: factId,
          message: message,
        );
      case PendingContributionKind.factTags:
        final factId = item.factId;
        if (factId == null || factId.isEmpty) {
          throw Exception('missing fact id');
        }
        return DeckCatalogService.of.submitFactTagsContribution(
          importDeckId: deckId,
          factId: factId,
          addTags: item.addTags,
          removeTags: item.removeTags,
          message: message,
        );
      case PendingContributionKind.deckTags:
        return DeckCatalogService.of.submitDeckTagsContribution(
          importDeckId: deckId,
          addTags: item.addTags,
          removeTags: item.removeTags,
          message: message,
        );
      case PendingContributionKind.fieldRename:
        final fields = item.proposedFields;
        if (fields == null || fields.isEmpty) {
          throw Exception('missing fields');
        }
        return DeckCatalogService.of.submitFieldRenameContribution(
          importDeckId: deckId,
          proposedFields: fields,
          message: message,
        );
      case PendingContributionKind.description:
        final description = item.proposedDescription;
        if (description == null || description.isEmpty) {
          throw Exception('missing description');
        }
        return DeckCatalogService.of.submitDescriptionContribution(
          importDeckId: deckId,
          proposedDescription: description,
          message: message,
        );
      case PendingContributionKind.report:
        throw Exception('reports are sent from card menu');
      case PendingContributionKind.template:
        throw Exception('unsupported pending kind');
    }
  }

  Future<void> _dismissSelected() async {
    final loc = AppLocalizations.of(context)!;
    final ids = _selected.toList();
    if (ids.isEmpty || _busy) return;
    await _whileRemoving(() async {
      // Count only selected rows still stored; others were sent or removed
      // meanwhile.
      var stored = _ids(await _store.listPending(widget.importDeckId));
      var dismissed = 0;
      for (final id in ids) {
        if (stored.contains(id)) dismissed += 1;
        stored = _ids(await _store.remove(widget.importDeckId, id));
      }
      await _refresh();
      if (!mounted) return;
      setState(() {
        _error = null;
        _notice = dismissed > 0 ? loc.pendingDismissed(dismissed) : null;
        _skipped = dismissed < ids.length
            ? loc.pendingSkippedGone(ids.length - dismissed)
            : null;
      });
    });
  }

  Future<void> _clearAll() async {
    final loc = AppLocalizations.of(context)!;
    if (_pending.isEmpty || _busy) return;
    await _whileRemoving(() async {
      // Count rows actually stored; rows shown but gone were sent or removed
      // meanwhile.
      final stored = _ids(await _store.listPending(widget.importDeckId));
      final gone = _pending.where((p) => !stored.contains(p.id)).length;
      await _store.clearPending(widget.importDeckId);
      await _refresh();
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _notice = stored.isEmpty ? null : loc.pendingCleared(stored.length);
        _error = null;
        _skipped = gone > 0 ? loc.pendingSkippedGone(gone) : null;
      });
    });
  }

  static Set<String> _ids(List<PendingContributionItem> rows) => {
    for (final r in rows) r.id,
  };

  /// Runs [remove] with the outbox busy. A storage error is shown instead of
  /// thrown, and the outbox is freed either way.
  Future<void> _whileRemoving(Future<void> Function() remove) async {
    setState(() => _removing = true);
    try {
      await remove();
    } catch (e) {
      if (mounted) setState(() => _error = rawApiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _removing = false);
    }
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
                onPressed: _busy
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
                onPressed: _busy
                    ? null
                    : () => setState(() => _tab = _OutboxTab.sent),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            ApiErrorMessages.resolve(_error!, loc),
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
        if (_skipped != null) ...[
          const SizedBox(height: 8),
          Text(
            _skipped!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
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
            onPressed: _busy || _selected.isEmpty ? null : _sendSelected,
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
                  onPressed: _busy || _selected.isEmpty
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
                  onPressed: _busy ? null : _clearAll,
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

    final submittable = _pending.where((p) => _isSubmittable(p.kind)).toList();
    final allSelected =
        submittable.isNotEmpty &&
        submittable.every((p) => _selected.contains(p.id));

    return ListView(
      shrinkWrap: true,
      children: [
        if (submittable.isNotEmpty)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: allSelected,
            title: Text(loc.pendingSelectAll(submittable.length)),
            onChanged: _busy
                ? null
                : (_) {
                    setState(() {
                      if (allSelected) {
                        _selected.clear();
                      } else {
                        _selected
                          ..clear()
                          ..addAll(submittable.map((e) => e.id));
                      }
                    });
                  },
          ),
        ..._pending.map((item) {
          final canSubmit = _isSubmittable(item.kind);
          final checked = canSubmit && _selected.contains(item.id);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: checked,
            onChanged: _busy || !canSubmit
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
            title: Text(
              _kindLabel(loc, item.kind),
              style: canSubmit
                  ? null
                  : theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
            ),
            subtitle: Text(
              [
                if (!canSubmit) loc.pendingNotSubmittable,
                if (item.factId != null && item.factId!.isNotEmpty)
                  item.factId!,
                _rowPreview(item),
              ].join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: canSubmit ? null : scheme.onSurfaceVariant,
              ),
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

import 'package:flutter/material.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck_updates.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

class ImportUpdatesSheet extends StatefulWidget {
  const ImportUpdatesSheet({
    super.key,
    required this.deckId,
    required this.onSynced,
  });

  final String deckId;
  final Future<void> Function() onSynced;

  @override
  State<ImportUpdatesSheet> createState() => _ImportUpdatesSheetState();
}

class _ImportUpdatesSheetState extends State<ImportUpdatesSheet> {
  DeckUpdatesResult? _updates;
  Map<String, SyncFactDecisionAction> _decisions = {};
  String? _error;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updates = await DeckCatalogService.of.getDeckUpdates(widget.deckId);
      if (!mounted) return;
      setState(() {
        _updates = updates;
        _decisions = updates.defaultDecisions();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = rawApiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _syncNow() async {
    final loc = AppLocalizations.of(context)!;
    final updates = _updates;
    if (updates == null) return;
    setState(() => _syncing = true);
    try {
      final decisions = _decisions.entries
          .map((e) => SyncFactDecision(factId: e.key, action: e.value))
          .toList();
      await DeckCatalogService.of.syncDeck(
        widget.deckId,
        targetVersion: updates.latestVersion,
        decisions: decisions,
      );
      await widget.onSynced();
      await _loadUpdates();
      if (!mounted) return;
      AppToast.success(context, loc.deckSyncSuccess);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  String _factPreview(Fact? fact) {
    if (fact == null || fact.entries.isEmpty) return '—';
    return fact.entries
        .map((e) => e.text.trim())
        .where((t) => t.isNotEmpty)
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final updates = _updates;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ApiErrorMessages.resolve(_error!, loc),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(label: loc.discoveryRetry, onPressed: _loadUpdates),
        ],
      );
    }
    if (updates == null) {
      return AppButton(label: loc.discoveryRetry, onPressed: _loadUpdates);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.deckUpdatesVersion(updates.sourceVersion, updates.latestVersion),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          loc.deckUpdatesCounts(
            updates.addedFacts.length,
            updates.editedFacts.length,
            updates.removedFacts.length,
            updates.mediaChanges.length,
          ),
          style: theme.textTheme.bodyMedium,
        ),
        if (updates.hasContentChanges) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: _UpdatesDiffBody(
                updates: updates,
                decisions: _decisions,
                onDecisionChanged: (factId, action) {
                  setState(() => _decisions[factId] = action);
                },
                factPreview: _factPreview,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppButton(
          label: updates.hasUpdates ? loc.deckSyncNow : loc.deckUpToDate,
          onPressed: updates.hasUpdates && !_syncing ? _syncNow : null,
          isLoading: _syncing,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _UpdatesDiffBody extends StatelessWidget {
  const _UpdatesDiffBody({
    required this.updates,
    required this.decisions,
    required this.onDecisionChanged,
    required this.factPreview,
  });

  final DeckUpdatesResult updates;
  final Map<String, SyncFactDecisionAction> decisions;
  final void Function(String factId, SyncFactDecisionAction action)
  onDecisionChanged;
  final String Function(Fact? fact) factPreview;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget sectionTitle(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color ?? scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (updates.addedFacts.isNotEmpty) ...[
          sectionTitle(
            loc.deckUpdatesAddedSection(updates.addedFacts.length),
            color: scheme.primary,
          ),
          ...updates.addedFacts.map(
            (f) => _FactRow(
              title: f.factId,
              subtitle: factPreview(f.fact),
              hint: [
                if (f.aligned) loc.deckUpdatesAligned,
                if (f.hasLocalOverlay) loc.deckUpdatesLocalOverlay,
              ].join(' · '),
            ),
          ),
        ],
        if (updates.removedFacts.isNotEmpty) ...[
          sectionTitle(
            loc.deckUpdatesRemovedSection(updates.removedFacts.length),
            color: scheme.error,
          ),
          ...updates.removedFacts.map(
            (f) => _DecisionFactRow(
              factId: f.factId,
              preview: factPreview(f.fact),
              value: decisions[f.factId] ?? SyncFactDecisionAction.accept,
              onChanged: (a) => onDecisionChanged(f.factId, a),
              hint: (f.hasLocalOverlay || f.local)
                  ? loc.deckUpdatesKeepHint
                  : loc.deckUpdatesAcceptHint,
            ),
          ),
        ],
        if (updates.editedFacts.isNotEmpty) ...[
          sectionTitle(
            loc.deckUpdatesEditedSection(updates.editedFacts.length),
          ),
          ...updates.editedFacts.map(
            (f) => _DecisionFactRow(
              factId: f.factId,
              preview:
                  '${loc.deckUpdatesBefore}: ${factPreview(f.before)}\n'
                  '${loc.deckUpdatesAfter}: ${factPreview(f.after)}',
              value: decisions[f.factId] ?? SyncFactDecisionAction.keep,
              onChanged: (a) => onDecisionChanged(f.factId, a),
              hint: f.aligned
                  ? loc.deckUpdatesAligned
                  : (f.hasLocalOverlay ? loc.deckUpdatesLocalOverlay : null),
            ),
          ),
        ],
        if (updates.mediaChanges.isNotEmpty) ...[
          sectionTitle(
            loc.deckUpdatesMediaSection(updates.mediaChanges.length),
          ),
          ...updates.mediaChanges.map(
            (m) => _FactRow(title: m.mediaId, subtitle: null),
          ),
        ],
        if (updates.cardTemplateChanges.isNotEmpty) ...[
          sectionTitle(
            loc.deckUpdatesTemplatesSection(updates.cardTemplateChanges.length),
          ),
          ...updates.cardTemplateChanges.map(
            (t) => _FactRow(title: t.factId, subtitle: null),
          ),
        ],
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.title, this.subtitle, this.hint});

  final String title;
  final String? subtitle;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelSmall),
            if (hint != null && hint!.isNotEmpty)
              Text(
                hint!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DecisionFactRow extends StatelessWidget {
  const _DecisionFactRow({
    required this.factId,
    required this.preview,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String factId;
  final String preview;
  final SyncFactDecisionAction value;
  final ValueChanged<SyncFactDecisionAction> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(factId, style: theme.textTheme.labelSmall),
            if (hint != null)
              Text(
                hint!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Text(preview, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: loc.deckUpdatesAccept,
                    size: AppButtonSize.sm,
                    variant: value == SyncFactDecisionAction.accept
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    onPressed: () => onChanged(SyncFactDecisionAction.accept),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: loc.deckUpdatesKeepLocal,
                    size: AppButtonSize.sm,
                    variant: value == SyncFactDecisionAction.keep
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    onPressed: () => onChanged(SyncFactDecisionAction.keep),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

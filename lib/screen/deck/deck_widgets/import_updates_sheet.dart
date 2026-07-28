import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck_updates.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
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
  DeckUpdatesSummary? _summary;
  Map<String, SyncFactDecisionAction> _decisions = {};
  final Map<String, DeckUpdateFactDetail> _details = {};
  final Set<String> _loadingFacts = {};
  final Set<String> _expandedFacts = {};
  final Map<String, int> _factLoadTokens = {};
  String? _error;
  bool _loading = true;
  bool _syncing = false;
  bool _reviewOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await DeckCatalogService.of.getDeckUpdatesSummary(
        widget.deckId,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _decisions = {
          for (final id in summary.removedFactIds)
            id: SyncFactDecisionAction.accept,
          for (final id in summary.editedFactIds)
            id: SyncFactDecisionAction.accept,
        };
        _details.clear();
        _expandedFacts.clear();
        _factLoadTokens.clear();
        _reviewOpen = false;
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
    final summary = _summary;
    if (summary == null) return;
    setState(() => _syncing = true);
    try {
      final decisions = _decisions.entries
          .map((e) => SyncFactDecision(factId: e.key, action: e.value))
          .toList();
      await DeckCatalogService.of.syncDeck(
        widget.deckId,
        targetVersion: summary.latestVersion,
        decisions: decisions,
      );
      await widget.onSynced();
      if (!mounted) return;
      setState(() {
        _summary = DeckUpdatesSummary(
          sourceVersion: summary.latestVersion,
          latestVersion: summary.latestVersion,
        );
        _decisions = {};
        _details.clear();
        _expandedFacts.clear();
        _factLoadTokens.clear();
        _reviewOpen = false;
      });
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

  Future<void> _toggleFact(String factId) async {
    if (_expandedFacts.contains(factId)) {
      // Expanded without detail (failed load): retry instead of collapsing.
      if (!_details.containsKey(factId) && !_loadingFacts.contains(factId)) {
        await _loadFactDetail(factId);
        return;
      }
      setState(() => _expandedFacts.remove(factId));
      return;
    }
    setState(() => _expandedFacts.add(factId));
    await _loadFactDetail(factId);
  }

  Future<void> _loadFactDetail(String factId) async {
    if (_details.containsKey(factId) || _loadingFacts.contains(factId)) {
      return;
    }
    final token = (_factLoadTokens[factId] ?? 0) + 1;
    setState(() {
      _factLoadTokens[factId] = token;
      _loadingFacts.add(factId);
    });
    try {
      final detail = await DeckCatalogService.of.getDeckUpdateFact(
        deckId: widget.deckId,
        factId: factId,
      );
      if (!mounted) return;
      if (_factLoadTokens[factId] != token) return;
      setState(() {
        _details[factId] = detail;
        // Only apply API default when the user hasn't overridden the summary
        // seed (accept). Otherwise a late response clobbers their choice.
        if (detail.kind == DeckUpdateFactKind.removed &&
            detail.defaultAction == 'keep' &&
            _decisions[factId] == SyncFactDecisionAction.accept) {
          _decisions[factId] = SyncFactDecisionAction.keep;
        }
      });
    } catch (e) {
      if (!mounted) return;
      // Ignore stale failures so a newer expand/retry is not collapsed.
      if (_factLoadTokens[factId] != token) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(
          rawApiErrorMessage(e),
          AppLocalizations.of(context)!,
        ),
      );
    } finally {
      if (mounted && _factLoadTokens[factId] == token) {
        setState(() => _loadingFacts.remove(factId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = _summary;

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
          AppButton(label: loc.discoveryRetry, onPressed: _loadSummary),
        ],
      );
    }
    if (summary == null) {
      return AppButton(label: loc.discoveryRetry, onPressed: _loadSummary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildHeader(context, summary),
        if (_reviewOpen) ...[
          const SizedBox(height: 12),
          _buildReviewList(context, summary),
        ],
        const SizedBox(height: 18),
        AppButton(
          label: summary.hasUpdates ? loc.deckSyncNow : loc.deckUpToDate,
          onPressed: summary.hasUpdates && !_syncing ? _syncNow : null,
          isLoading: _syncing,
          fullWidth: true,
        ),
      ],
    );
  }

  List<Widget> _buildHeader(BuildContext context, DeckUpdatesSummary summary) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reviewableIds = <String>[
      ...summary.editedFactIds,
      ...summary.removedFactIds,
      ...summary.addedFactIds,
    ];

    return [
      Text(
        loc.deckUpdatesVersion(summary.sourceVersion, summary.latestVersion),
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      Text(
        loc.deckUpdatesCounts(
          summary.addedFactIds.length,
          summary.editedFactIds.length,
          summary.removedFactIds.length,
          summary.mediaChangeCount,
        ),
        style: theme.textTheme.bodyMedium,
      ),
      if (summary.changeSummary.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(summary.changeSummary, style: theme.textTheme.bodySmall),
      ],
      if (summary.hasContentChanges && reviewableIds.isNotEmpty) ...[
        const SizedBox(height: 12),
        AppButton(
          label: _reviewOpen
              ? loc.deckUpdatesHideReview
              : loc.deckUpdatesReviewChanges,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
          onPressed: () => setState(() => _reviewOpen = !_reviewOpen),
        ),
      ],
    ];
  }

  Widget _buildReviewList(BuildContext context, DeckUpdatesSummary summary) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView(
        shrinkWrap: true,
        children: [
          if (summary.editedFactIds.isNotEmpty) ...[
            _sectionTitle(
              context,
              loc.deckUpdatesEditedSection(summary.editedFactIds.length),
            ),
            ...summary.editedFactIds.map(_factTile),
          ],
          if (summary.removedFactIds.isNotEmpty) ...[
            _sectionTitle(
              context,
              loc.deckUpdatesRemovedSection(summary.removedFactIds.length),
              color: theme.colorScheme.error,
            ),
            ...summary.removedFactIds.map(_factTile),
          ],
          if (summary.addedFactIds.isNotEmpty) ...[
            _sectionTitle(
              context,
              loc.deckUpdatesAddedSection(summary.addedFactIds.length),
              color: theme.colorScheme.primary,
            ),
            ...summary.addedFactIds.map(_factTile),
          ],
          if (summary.mediaChangeCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                loc.deckUpdatesMediaSection(summary.mediaChangeCount),
                style: theme.textTheme.labelLarge,
              ),
            ),
          if (summary.cardTemplateChangeCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                loc.deckUpdatesTemplatesSection(
                  summary.cardTemplateChangeCount,
                ),
                style: theme.textTheme.labelLarge,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _factTile(String factId) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expanded = _expandedFacts.contains(factId);
    final loading = _loadingFacts.contains(factId);
    final detail = _details[factId];
    final decision = _decisions[factId] ?? SyncFactDecisionAction.accept;

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
            InkWell(
              onTap: () => _toggleFact(factId),
              child: Row(
                children: [
                  Expanded(
                    child: Text(factId, style: theme.textTheme.labelSmall),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            if (expanded && detail != null) ...[
              const SizedBox(height: 8),
              _FactDetailBody(
                detail: detail,
                decision: decision,
                onDecisionChanged: (action) {
                  setState(() => _decisions[factId] = action);
                },
              ),
            ],
            if (expanded && detail == null && !loading) ...[
              const SizedBox(height: 8),
              AppButton(
                label: loc.discoveryRetry,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: () => _toggleFact(factId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactDetailBody extends StatelessWidget {
  const _FactDetailBody({
    required this.detail,
    required this.decision,
    required this.onDecisionChanged,
  });

  final DeckUpdateFactDetail detail;
  final SyncFactDecisionAction decision;
  final ValueChanged<SyncFactDecisionAction> onDecisionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHints(context),
        _buildFactVersions(context),
        if (detail.kind == DeckUpdateFactKind.edited ||
            detail.kind == DeckUpdateFactKind.removed)
          _buildDecisionRow(context),
      ],
    );
  }

  Widget _buildHints(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hints = <String>[
      if (detail.aligned) loc.deckUpdatesAligned,
      if (detail.hasLocalOverlay) loc.deckUpdatesLocalOverlay,
    ];
    if (hints.isEmpty) return const SizedBox.shrink();
    return Text(
      hints.join(' · '),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFactVersions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (detail.kind == DeckUpdateFactKind.edited) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactEntriesAudioLine(
            label: loc.deckUpdatesBefore,
            fact: detail.before,
            mediaVersions: detail.beforeMediaVersions,
          ),
          const SizedBox(height: 4),
          _FactEntriesAudioLine(
            label: loc.deckUpdatesAfter,
            fact: detail.after,
            mediaVersions: detail.afterMediaVersions,
          ),
        ],
      );
    }
    return _FactEntriesAudioLine(
      label: detail.kind == DeckUpdateFactKind.added
          ? loc.deckUpdatesAfter
          : loc.deckUpdatesBefore,
      fact: detail.fact,
      mediaVersions: detail.kind == DeckUpdateFactKind.added
          ? detail.afterMediaVersions
          : detail.beforeMediaVersions,
    );
  }

  Widget _buildDecisionRow(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: loc.deckUpdatesAccept,
              size: AppButtonSize.sm,
              variant: decision == SyncFactDecisionAction.accept
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              onPressed: () => onDecisionChanged(SyncFactDecisionAction.accept),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              label: loc.deckUpdatesKeepLocal,
              size: AppButtonSize.sm,
              variant: decision == SyncFactDecisionAction.keep
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              onPressed: () => onDecisionChanged(SyncFactDecisionAction.keep),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactEntriesAudioLine extends StatelessWidget {
  const _FactEntriesAudioLine({
    required this.label,
    required this.fact,
    required this.mediaVersions,
  });

  final String label;
  final Fact? fact;
  final Map<String, int> mediaVersions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = fact?.entries ?? const <FactEntry>[];
    final parts = <Widget>[Text('$label: ', style: theme.textTheme.bodySmall)];

    if (entries.isEmpty) {
      parts.add(Text('—', style: theme.textTheme.bodySmall));
    } else {
      for (var i = 0; i < entries.length; i++) {
        if (i > 0) {
          parts.add(Text(' · ', style: theme.textTheme.bodySmall));
        }
        final entry = entries[i];
        final text = entry.text.trim();
        final audioUrl = DeckUpdatesResult.mediaPlayUrl(
          entry.audio,
          mediaVersions,
        );
        parts.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (text.isNotEmpty)
                Text(text, style: theme.textTheme.bodySmall)
              else if (audioUrl == null)
                Text('—', style: theme.textTheme.bodySmall),
              if (audioUrl != null)
                _LazyCardAudio(audioUrl: audioUrl, color: scheme.primary),
            ],
          ),
        );
      }
    }

    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: parts);
  }
}

/// Play control that only mounts [CardAudio] (and starts download) after tap.
class _LazyCardAudio extends StatefulWidget {
  const _LazyCardAudio({required this.audioUrl, required this.color});

  final String audioUrl;
  final Color color;

  @override
  State<_LazyCardAudio> createState() => _LazyCardAudioState();
}

class _LazyCardAudioState extends State<_LazyCardAudio> {
  bool _activated = false;

  @override
  Widget build(BuildContext context) {
    if (_activated) {
      return CardAudio(
        audioUrl: widget.audioUrl,
        color: widget.color,
        compact: true,
      );
    }
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      iconSize: 22,
      color: widget.color,
      onPressed: () => setState(() => _activated = true),
      icon: const Icon(LucideIcons.play),
    );
  }
}

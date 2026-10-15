import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck_contribution.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

/// Author inbox for open contributions on a **source** deck.
class ContributionsInboxSheet extends StatefulWidget {
  const ContributionsInboxSheet({super.key, required this.sourceDeckId});

  final String sourceDeckId;

  @override
  State<ContributionsInboxSheet> createState() =>
      _ContributionsInboxSheetState();
}

bool contributionCanAccept(DeckContribution c) => c.type != 'report';

class _ContributionsInboxSheetState extends State<ContributionsInboxSheet> {
  List<DeckContribution>? _items;
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _acceptingAll = false;
  String? _busyId;

  static const _pageSize = 50;

  List<DeckContribution> get _acceptable =>
      (_items ?? const []).where(contributionCanAccept).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    if (append) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final offset = append ? (_items?.length ?? 0) : 0;
      final page = await DeckCatalogService.of.listContributions(
        widget.sourceDeckId,
        status: 'open',
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted) return;
      setState(() {
        if (append) {
          _items = [...?_items, ...page.contributions];
        } else {
          _items = page.contributions;
        }
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      if (!append) setState(() => _error = rawApiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _accept(DeckContribution c) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _busyId = c.id);
    try {
      await DeckCatalogService.of.acceptContribution(
        sourceDeckId: widget.sourceDeckId,
        contributionId: c.id,
      );
      if (!mounted) return;
      AppToast.success(context, loc.contributionsAccepted);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _acceptAll() async {
    final loc = AppLocalizations.of(context)!;
    final toAccept = _acceptable;
    if (toAccept.isEmpty || _acceptingAll || _busyId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.contributionsAcceptAllConfirmTitle),
        content: Text(
          loc.contributionsAcceptAllConfirmMessage(toAccept.length),
        ),
        actions: [
          AppButton(
            label: loc.cancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: AppButtonVariant.ghost,
          ),
          AppButton(
            label: loc.contributionsAccept,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acceptingAll = true);
    var sent = 0;
    var failed = 0;
    String? lastError;
    try {
      for (final c in toAccept) {
        try {
          await DeckCatalogService.of.acceptContribution(
            sourceDeckId: widget.sourceDeckId,
            contributionId: c.id,
          );
          sent += 1;
        } catch (e) {
          failed += 1;
          lastError = rawApiErrorMessage(e);
        }
      }
      if (!mounted) return;
      if (failed == 0) {
        AppToast.success(context, loc.contributionsAcceptAllSuccess(sent));
      } else if (sent > 0) {
        AppToast.error(
          context,
          loc.contributionsAcceptAllPartial(sent, failed),
        );
      } else {
        AppToast.error(
          context,
          ApiErrorMessages.resolve(
            lastError ?? 'accept_contribution_failed',
            loc,
          ),
        );
      }
      await _load();
    } finally {
      if (mounted) setState(() => _acceptingAll = false);
    }
  }

  Future<void> _setStatus(DeckContribution c, String status) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _busyId = c.id);
    try {
      await DeckCatalogService.of.patchContributionStatus(
        sourceDeckId: widget.sourceDeckId,
        contributionId: c.id,
        status: status,
      );
      if (!mounted) return;
      AppToast.success(context, loc.contributionsUpdated);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
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
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ApiErrorMessages.resolve(_error!, loc),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppButton(label: loc.retry, onPressed: _load),
        ],
      );
    }

    final items = _items ?? const [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.inbox,
              size: 40,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(loc.contributionsEmpty, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    final acceptable = _acceptable;
    final rowBusy = _busyId != null || _acceptingAll;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (acceptable.isNotEmpty) ...[
          AppButton(
            label: loc.contributionsAcceptAll(acceptable.length),
            size: AppButtonSize.sm,
            isLoading: _acceptingAll,
            onPressed: rowBusy ? null : _acceptAll,
          ),
          const SizedBox(height: 12),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length + (_hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            if (i >= items.length) {
              return AppButton(
                label: loc.contributionsLoadMore,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                isLoading: _loadingMore,
                onPressed: _loadingMore || _acceptingAll
                    ? null
                    : () => _load(append: true),
              );
            }
            final c = items[i];
            final busy = _busyId == c.id;
            final canAccept = contributionCanAccept(c);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.type.replaceAll('_', ' '),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [
                      if (c.reporter.isNotEmpty) c.reporter,
                      if (c.factId.isNotEmpty) c.factId,
                      if (c.sourceVersion > 0) 'v${c.sourceVersion}',
                    ].join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (c.message.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(c.message, style: theme.textTheme.bodyMedium),
                  ],
                  if (c.hasEntryDiff || c.hasTagDiff || c.hasFieldRename) ...[
                    const SizedBox(height: 10),
                    _ContributionDiffBlock(contribution: c),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (canAccept)
                        Expanded(
                          child: AppButton(
                            label: loc.contributionsAccept,
                            size: AppButtonSize.sm,
                            isLoading: busy,
                            onPressed: rowBusy ? null : () => _accept(c),
                          ),
                        ),
                      if (canAccept) const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: loc.contributionsDismiss,
                          size: AppButtonSize.sm,
                          variant: AppButtonVariant.secondary,
                          onPressed: rowBusy
                              ? null
                              : () => _setStatus(c, 'dismissed'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: loc.contributionsResolve,
                          size: AppButtonSize.sm,
                          variant: AppButtonVariant.ghost,
                          onPressed: rowBusy
                              ? null
                              : () => _setStatus(c, 'resolved'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ContributionDiffBlock extends StatelessWidget {
  const _ContributionDiffBlock({required this.contribution});

  final DeckContribution contribution;

  static String _entriesPreview(List<FactEntry> entries) {
    if (entries.isEmpty) return '—';
    final parts = entries
        .map((e) => e.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    return parts.join(' · ');
  }

  List<int> _audioIndexes(List<FactEntry> entries) {
    final out = <int>[];
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].audio.trim().isNotEmpty) out.add(i);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = contribution;

    final beforeEntries = c.reportedFact?.entries ?? const <FactEntry>[];
    final afterEntries = c.proposedEntries;
    final showBeforeAfter =
        c.type == 'fact_edit' ||
        (beforeEntries.isNotEmpty && afterEntries.isNotEmpty);
    final showProposedOnly =
        c.type == 'fact_add' &&
        afterEntries.isNotEmpty &&
        beforeEntries.isEmpty;
    final showReportedOnly =
        c.type == 'report' && beforeEntries.isNotEmpty && afterEntries.isEmpty;

    final beforeAudioIndexes = _audioIndexes(beforeEntries);
    final afterAudioIndexes = <int>{
      ..._audioIndexes(afterEntries),
      for (final a in c.mediaAttachments)
        if (a.isAudio) ...a.entryIndexes,
    }.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBeforeAfter) ...[
            Text(
              loc.contributionsBefore,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _entriesPreview(beforeEntries),
              style: theme.textTheme.bodySmall,
            ),
            if (beforeAudioIndexes.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ContributionAudioRow(
                label: loc.contributionsPlayBefore,
                urls: [
                  for (final i in beforeAudioIndexes)
                    if (c.beforeAudioUrl(i) != null) c.beforeAudioUrl(i)!,
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              loc.contributionsAfter,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _entriesPreview(afterEntries),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (afterAudioIndexes.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ContributionAudioRow(
                label: loc.contributionsPlayAfter,
                urls: [
                  for (final i in afterAudioIndexes)
                    if (c.afterAudioUrl(i) != null) c.afterAudioUrl(i)!,
                ],
              ),
            ],
          ] else if (showProposedOnly) ...[
            Text(
              loc.contributionsProposed,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _entriesPreview(afterEntries),
              style: theme.textTheme.bodySmall,
            ),
            if (afterAudioIndexes.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ContributionAudioRow(
                label: loc.contributionsPlayAfter,
                urls: [
                  for (final i in afterAudioIndexes)
                    if (c.afterAudioUrl(i) != null) c.afterAudioUrl(i)!,
                ],
              ),
            ],
          ] else if (showReportedOnly) ...[
            Text(
              loc.contributionsReported,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _entriesPreview(beforeEntries),
              style: theme.textTheme.bodySmall,
            ),
            if (beforeAudioIndexes.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ContributionAudioRow(
                label: loc.contributionsPlayBefore,
                urls: [
                  for (final i in beforeAudioIndexes)
                    if (c.beforeAudioUrl(i) != null) c.beforeAudioUrl(i)!,
                ],
              ),
            ],
          ],
          if (c.hasFieldRename) ...[
            if (c.hasEntryDiff) const SizedBox(height: 8),
            Text(
              loc.contributionsFields,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${c.reportedFields.isEmpty ? '—' : c.reportedFields.join(' · ')}'
              ' → '
              '${c.proposedFields.isEmpty ? '—' : c.proposedFields.join(' · ')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (c.hasTagDiff) ...[
            if (c.hasEntryDiff || c.hasFieldRename) const SizedBox(height: 8),
            Text(
              loc.contributionsTags,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (c.reportedTags.isNotEmpty)
              Text(
                '${loc.contributionsBefore}: ${c.reportedTags.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            if (c.addTags.isNotEmpty)
              Text(
                '+ ${c.addTags.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            if (c.removeTags.isNotEmpty)
              Text(
                '− ${c.removeTags.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

class _ContributionAudioRow extends StatelessWidget {
  const _ContributionAudioRow({required this.label, required this.urls});

  final String label;
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        for (final url in urls)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CardAudio(
              audioUrl: url,
              color: scheme.primary,
              compact: true,
            ),
          ),
      ],
    );
  }
}

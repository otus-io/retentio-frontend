import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/tag_service.dart';

class _TagFactRow {
  const _TagFactRow({required this.ref, this.fact, this.loadError});

  final TagFactRef ref;
  final Fact? fact;
  final String? loadError;
}

class TagFactsScreen extends StatefulWidget {
  const TagFactsScreen({super.key, required this.tag});

  final Tag tag;

  @override
  State<TagFactsScreen> createState() => _TagFactsScreenState();
}

class _TagFactsScreenState extends State<TagFactsScreen> {
  List<_TagFactRow>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final refs = await TagService.of.getTagFacts(widget.tag.id);
      final rows = <_TagFactRow>[];
      for (final ref in refs) {
        try {
          final fact = await CardService.getFact(ref.deckId, ref.factId);
          rows.add(_TagFactRow(ref: ref, fact: fact));
        } catch (e) {
          rows.add(_TagFactRow(ref: ref, loadError: rawApiErrorMessage(e)));
        }
      }
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = rawApiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tag.name),
            if (widget.tag.description.isNotEmpty)
              Text(
                widget.tag.description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
          ],
        ),
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(loc, theme, scheme),
    );
  }

  Widget _buildBody(AppLocalizations loc, ThemeData theme, ColorScheme scheme) {
    if (_rows == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              ApiErrorMessages.resolve(_error, loc),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            TextButton(onPressed: _load, child: Text(loc.retry)),
          ],
        ),
      );
    }

    final rows = _rows!;
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(
              LucideIcons.fileX2,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.25),
            ),
            Text(
              loc.noFactsInTag,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _FactRefCard(row: rows[i]),
      ),
    );
  }
}

class _FactRefCard extends StatelessWidget {
  const _FactRefCard({required this.row});

  final _TagFactRow row;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fact = row.fact;
    final entries = fact?.entries ?? const <FactEntry>[];
    final fields = fact?.fields ?? const <String>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            loc.tagFactRefLabel(row.ref.deckId, row.ref.factId),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (row.loadError != null)
            Text(
              ApiErrorMessages.resolve(row.loadError, loc),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            )
          else if (entries.isEmpty)
            Text('—', style: theme.textTheme.bodySmall)
          else
            ...List.generate(entries.length, (i) {
              final entry = entries[i];
              final label = (i < fields.length && fields[i].isNotEmpty)
                  ? fields[i]
                  : null;
              final text = entry.text;
              if (text.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    text,
                    style: i == 0
                        ? theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : theme.textTheme.bodySmall,
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

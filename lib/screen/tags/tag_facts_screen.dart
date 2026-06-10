import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/tag_service.dart';

class TagFactsScreen extends StatefulWidget {
  const TagFactsScreen({super.key, required this.tag});

  final Tag tag;

  @override
  State<TagFactsScreen> createState() => _TagFactsScreenState();
}

class _TagFactsScreenState extends State<TagFactsScreen> {
  List<Fact>? _facts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _facts = null;
      _error = null;
    });
    try {
      final facts = await TagService.of.getTagFacts(widget.tag.id);
      if (mounted) setState(() => _facts = facts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
    if (_facts == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            TextButton(onPressed: _load, child: Text(loc.retry)),
          ],
        ),
      );
    }

    final facts = _facts!;
    if (facts.isEmpty) {
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
        itemCount: facts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _FactCard(fact: facts[i]),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact});

  final Fact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Show fields as labels if available, otherwise fall back to indices.
    final entries = fact.entries;
    final fields = fact.fields;

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
        children: List.generate(entries.length, (i) {
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
      ),
    );
  }
}

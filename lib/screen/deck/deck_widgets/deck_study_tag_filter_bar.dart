import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/widgets/app_input.dart';

/// Distinguishes an explicit sheet pick from dismiss (which returns null).
class _TagFilterPick {
  const _TagFilterPick(this.tagId);

  final String? tagId;
}

class DeckStudyTagFilterBar extends StatelessWidget {
  const DeckStudyTagFilterBar({
    super.key,
    required this.tags,
    required this.activeTagId,
    required this.onTagSelected,
  });

  final List<Tag> tags;
  final String? activeTagId;
  final void Function(String? tagId) onTagSelected;

  void _selectTag(String? tagId) {
    if (tagId == activeTagId) {
      return;
    }
    onTagSelected(tagId);
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final pick = await showModalBottomSheet<_TagFilterPick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _DeckStudyTagFilterSheet(tags: tags, activeTagId: activeTagId);
      },
    );
    if (pick == null || !context.mounted) {
      return;
    }
    _selectTag(pick.tagId);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildChip(
                      label: loc.filterAll,
                      selected: activeTagId == null,
                      onTap: () => _selectTag(null),
                    );
                  }

                  final tag = tags[index - 1];
                  final selected = activeTagId == tag.id;
                  return _buildChip(
                    label: tag.name,
                    selected: selected,
                    onTap: () => _selectTag(tag.id),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('deck_study_tag_filter'),
              onTap: () => _openSheet(context),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckStudyTagFilterSheet extends StatefulWidget {
  const _DeckStudyTagFilterSheet({
    required this.tags,
    required this.activeTagId,
  });

  final List<Tag> tags;
  final String? activeTagId;

  @override
  State<_DeckStudyTagFilterSheet> createState() =>
      _DeckStudyTagFilterSheetState();
}

class _DeckStudyTagFilterSheetState extends State<_DeckStudyTagFilterSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Tag> get _filteredTags {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.tags;
    return widget.tags
        .where((tag) => tag.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;
    final filtered = _filteredTags;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.studyTagFilterTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: AppInput(
                controller: _searchController,
                hint: loc.tagPickerSearchHint,
                prefix: const Icon(LucideIcons.search, size: 18),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  _DeckStudyTagFilterTile(
                    label: loc.filterAll,
                    selected: widget.activeTagId == null,
                    onTap: () =>
                        Navigator.of(context).pop(_TagFilterPick(null)),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        loc.noTags,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (final tag in filtered)
                      _DeckStudyTagFilterTile(
                        label: tag.name,
                        selected: widget.activeTagId == tag.id,
                        onTap: () =>
                            Navigator.of(context).pop(_TagFilterPick(tag.id)),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckStudyTagFilterTile extends StatelessWidget {
  const _DeckStudyTagFilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        selected ? LucideIcons.circleCheck : LucideIcons.circle,
        size: 20,
        color: selected ? scheme.primary : scheme.outline,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }
}

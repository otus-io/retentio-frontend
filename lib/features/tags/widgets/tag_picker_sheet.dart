import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/features/tags/widgets/tag_edit_dialog.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/widgets/app_input.dart';

// ── public API ────────────────────────────────────────────────────────────────

/// Shows a bottom sheet that lets the user pick tags from their tag list.
///
/// [selectedIds] — tag ids already attached to the item being edited.
/// Returns the updated set of selected tag ids, or null if cancelled.
///
/// The sheet reads [TagManagerCubit] from context; make sure it is provided
/// above the caller (e.g. at the app or deck level).
Future<Set<String>?> showTagPickerSheet(
  BuildContext context, {
  required Set<String> selectedIds,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<TagManagerCubit>(),
      child: _TagPickerSheet(initialSelectedIds: selectedIds),
    ),
  );
}

// ── private sheet ─────────────────────────────────────────────────────────────

class _TagPickerSheet extends HookWidget {
  const _TagPickerSheet({required this.initialSelectedIds});

  final Set<String> initialSelectedIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final selected = useState<Set<String>>({...initialSelectedIds});
    final filterText = useState('');
    final filterController = useTextEditingController();
    final isCreateDialogOpen = useState(false);
    final cubit = context.read<TagManagerCubit>();

    // Client-side filter
    final query = filterText.value.trim().toLowerCase();

    return Padding(
      padding: EdgeInsets.only(
        bottom: isCreateDialogOpen.value
            ? 0
            : MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Column(
          children: [
            // ── handle ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── title ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(loc.tagPickerTitle, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(selected.value),
                    child: Text(loc.tagPickerDone),
                  ),
                ],
              ),
            ),
            // ── search ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AppInput(
                controller: filterController,
                hint: loc.tagPickerSearchHint,
                prefix: const Icon(LucideIcons.search, size: 18),
                onChanged: (v) => filterText.value = v,
              ),
            ),
            const Divider(height: 1),
            // ── list ────────────────────────────────────────
            Expanded(
              child: BlocBuilder<TagManagerCubit, TagManagerState>(
                builder: (context, state) {
                  final filtered = query.isEmpty
                      ? state.tags
                      : state.tags
                            .where(
                              (tag) => tag.name.toLowerCase().contains(query),
                            )
                            .toList();

                  if (state.isLoading && state.tags.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filtered.isEmpty) {
                    return _EmptyState(
                      hasQuery: query.isNotEmpty,
                      query: query,
                    );
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final tag = filtered[i];
                          final isSelected = selected.value.contains(tag.id);
                          return _TagTile(
                            tag: tag,
                            selected: isSelected,
                            onToggle: () {
                              final next = {...selected.value};
                              if (isSelected) {
                                next.remove(tag.id);
                              } else {
                                next.add(tag.id);
                              }
                              selected.value = next;
                            },
                          );
                        },
                      ),
                      if (state.isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // ── create new tag ───────────────────────────────
            BlocBuilder<TagManagerCubit, TagManagerState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: state.tags.length >= 100
                      ? Text(
                          loc.tagLimitReached,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () async {
                            isCreateDialogOpen.value = true;
                            try {
                              await showTagEditDialog(
                                context,
                                title: loc.createTag,
                                confirmLabel: loc.save,
                                onConfirm: (name, description) async {
                                  final err = await cubit.createTag(
                                    name: name,
                                    description: description,
                                  );
                                  if (err != null) return err;
                                  final newest = cubit.state.tags.lastOrNull;
                                  if (newest != null) {
                                    selected.value = {
                                      ...selected.value,
                                      newest.id,
                                    };
                                  }
                                  return null;
                                },
                              );
                            } finally {
                              if (context.mounted) {
                                isCreateDialogOpen.value = false;
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: Text(loc.createTag),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.tag,
    required this.selected,
    required this.onToggle,
  });

  final Tag tag;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: selected
            ? Icon(
                LucideIcons.checkCircle2,
                key: const ValueKey(true),
                color: scheme.primary,
              )
            : Icon(
                LucideIcons.circle,
                key: const ValueKey(false),
                color: scheme.outline,
              ),
      ),
      title: Text(tag.name),
      subtitle: tag.description.isNotEmpty ? Text(tag.description) : null,
      onTap: onToggle,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.query});

  final bool hasQuery;
  final String query;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasQuery ? loc.tagPickerNoMatch(query) : loc.tagPickerEmptyHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

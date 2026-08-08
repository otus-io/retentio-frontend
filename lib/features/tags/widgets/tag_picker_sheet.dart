import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/features/tags/widgets/tag_edit_dialog.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/dismiss_keyboard_on_tap.dart';

// ── public API ────────────────────────────────────────────────────────────────

/// Pushes a full-screen tag picker page.
///
/// [selectedIds] — tag ids already attached to the item being edited.
/// Returns the updated set of selected tag ids, or null if cancelled.
///
/// Reads [TagManagerCubit] from context; make sure it is provided above caller.
Future<Set<String>?> showTagPickerSheet(
  BuildContext context, {
  required Set<String> selectedIds,
}) {
  return Navigator.of(context).push<Set<String>>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<TagManagerCubit>(),
        child: _TagPickerPage(initialSelectedIds: selectedIds),
      ),
    ),
  );
}

// ── page ──────────────────────────────────────────────────────────────────────

class _TagPickerPage extends HookWidget {
  const _TagPickerPage({required this.initialSelectedIds});

  final Set<String> initialSelectedIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final selected = useState<Set<String>>({...initialSelectedIds});
    final filterText = useState('');
    final filterController = useTextEditingController();
    final cubit = context.read<TagManagerCubit>();

    final query = filterText.value.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tagPickerTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(selected.value),
            child: Text(loc.tagPickerDone),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── search ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            child: DismissKeyboardOnTap(
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
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final tag = filtered[i];
                          final isSelected = selected.value.contains(tag.id);
                          return _TagTile(
                            tag: tag,
                            selected: isSelected,
                            onToggle: () {
                              FocusManager.instance.primaryFocus?.unfocus();
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
                child: cubit.isAtLimit
                    ? Text(
                        loc.tagLimitReached,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () async {
                          await showTagEditDialog(
                            context,
                            title: loc.createTag,
                            confirmLabel: loc.save,
                            onConfirm: (name, description) async {
                              final beforeIds = state.tags
                                  .map((tag) => tag.id)
                                  .toSet();
                              final err = await cubit.createTag(
                                name: name,
                                description: description,
                              );
                              if (err != null) {
                                return ApiErrorMessages.resolve(err, loc);
                              }
                              String? createdTagId;
                              for (final tag in cubit.state.tags) {
                                if (!beforeIds.contains(tag.id)) {
                                  createdTagId = tag.id;
                                  break;
                                }
                              }
                              if (createdTagId != null) {
                                selected.value = {
                                  ...selected.value,
                                  createdTagId,
                                };
                              }
                              return null;
                            },
                          );
                        },
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: Text(loc.createTag),
                      ),
              );
            },
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
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

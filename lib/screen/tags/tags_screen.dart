import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/features/tags/widgets/tag_edit_dialog.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/screen/tags/tag_facts_screen.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/app_toast.dart';

const double _kTagFabBorderOpacity = 0.12;
const double _kTagFabBgTint = 0.08;
const double _kTagListHorizontalPadding = 16;

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  late final TagManagerCubit _cubit;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cubit = TagManagerCubit()..loadTags();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    AppToast.show(context, msg);
  }

  bool _matchesTag(Tag tag, String query) {
    if (query.isEmpty) return true;
    final normalized = query.toLowerCase();
    return tag.name.toLowerCase().contains(normalized) ||
        tag.description.toLowerCase().contains(normalized);
  }

  Future<void> _showCreateDialog() async {
    final loc = AppLocalizations.of(context)!;
    await showTagEditDialog(
      context,
      title: loc.createTag,
      confirmLabel: loc.save,
      onConfirm: (name, desc) async {
        final err = await _cubit.createTag(name: name, description: desc);
        if (err != null) {
          return ApiErrorMessages.resolve(err, loc);
        }
        _snack(loc.tagCreated);
        return null;
      },
    );
  }

  Future<void> _showEditDialog(Tag tag) async {
    final loc = AppLocalizations.of(context)!;
    await showTagEditDialog(
      context,
      title: loc.editTag,
      confirmLabel: loc.save,
      initialName: tag.name,
      initialDescription: tag.description,
      onConfirm: (name, desc) async {
        final err = await _cubit.updateTag(
          tag.id,
          name: name,
          description: desc,
        );
        if (err != null) {
          return ApiErrorMessages.resolve(err, loc);
        }
        _snack(loc.tagUpdated);
        return null;
      },
    );
  }

  Future<void> _confirmDelete(Tag tag) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteTag),
        content: Text('"${tag.name}"'),
        actions: [
          AppButton(
            label: loc.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: loc.deleteTag,
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await _cubit.deleteTag(tag.id);
    if (err != null) _snack(ApiErrorMessages.resolve(err, loc));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider<TagManagerCubit>.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.tags), scrolledUnderElevation: 0),
        floatingActionButton: BlocBuilder<TagManagerCubit, TagManagerState>(
          builder: (context, state) {
            if (_cubit.isAtLimit) return const SizedBox.shrink();
            return FloatingActionButton.small(
              onPressed: _showCreateDialog,
              tooltip: loc.createTag,
              backgroundColor: Color.lerp(
                scheme.surfaceContainerHighest,
                scheme.primary,
                _kTagFabBgTint,
              ),
              foregroundColor: scheme.primary,
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              shape: CircleBorder(
                side: BorderSide(
                  color: scheme.primary.withValues(
                    alpha: _kTagFabBorderOpacity,
                  ),
                ),
              ),
              child: const Icon(LucideIcons.plus, size: 18),
            );
          },
        ),
        body: BlocBuilder<TagManagerCubit, TagManagerState>(
          builder: (context, state) {
            if (state.status == TagManagerStatus.loading &&
                state.tags.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == TagManagerStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ApiErrorMessages.resolve(state.errorMessage, loc),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: loc.retry,
                      variant: AppButtonVariant.ghost,
                      onPressed: _cubit.loadTags,
                    ),
                  ],
                ),
              );
            }

            if (state.tags.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Icon(
                      LucideIcons.tag,
                      size: 48,
                      color: scheme.onSurface.withValues(alpha: 0.25),
                    ),
                    Text(
                      loc.noTags,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    AppButton(
                      label: loc.createTag,
                      variant: AppButtonVariant.primary,
                      leading: const Icon(LucideIcons.plus),
                      onPressed: _showCreateDialog,
                    ),
                  ],
                ),
              );
            }

            final query = _searchQuery.trim();
            final filteredTags = state.tags
                .where((tag) => _matchesTag(tag, query))
                .toList(growable: false);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _kTagListHorizontalPadding,
                    12,
                    _kTagListHorizontalPadding,
                    6,
                  ),
                  child: AppInput(
                    controller: _searchController,
                    hint: loc.tagPickerSearchHint,
                    prefix: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(LucideIcons.x, size: 16),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).clearButtonTooltip,
                          ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.82,
                    ),
                  ),
                ),
                Expanded(
                  child: filteredTags.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 12,
                            children: [
                              Icon(
                                LucideIcons.searchX,
                                size: 40,
                                color: scheme.onSurface.withValues(alpha: 0.28),
                              ),
                              Text(
                                loc.tagPickerNoMatch(query),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cubit.loadTags,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              _kTagListHorizontalPadding,
                              6,
                              _kTagListHorizontalPadding,
                              12,
                            ),
                            itemCount: filteredTags.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final tag = filteredTags[i];
                              return _TagCard(
                                tag: tag,
                                onEdit: () => _showEditDialog(tag),
                                onDelete: () => _confirmDelete(tag),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => TagFactsScreen(tag: tag),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Tag card ──────────────────────────────────────────────────────────────────

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.tag, size: 16, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.tagUsageCounts(tag.deckCount, tag.factCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (tag.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tag.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<_TagAction>(
              icon: Icon(
                LucideIcons.ellipsis,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
              onSelected: (action) {
                switch (action) {
                  case _TagAction.edit:
                    onEdit();
                  case _TagAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _TagAction.edit,
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: scheme.onSurface,
                      ),
                      Text(loc.editTag),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _TagAction.delete,
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: scheme.error),
                      Text(
                        loc.deleteTag,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
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

enum _TagAction { edit, delete }

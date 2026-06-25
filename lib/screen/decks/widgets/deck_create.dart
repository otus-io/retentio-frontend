import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/features/tags/widgets/tag_chip.dart';
import 'package:retentio/features/tags/widgets/tag_picker_sheet.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/mixins/delayed_init_mixin.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/deck_text_styles.dart';
import 'package:retentio/services/apis/tag_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/number_picker.dart';
import 'deck_loading_state.dart';

const double _kDeckCreateNumberPickerSize = 44;
const double _kDeckCreateNumberPickerRadius = 14;
const double _kDeckCreateFieldLabelTopPadding = 8;
const double _kDeckCreateFieldLabelBottomPadding = 4;
const BoxConstraints _kDeckCreateSuffixConstraints = BoxConstraints(
  minWidth: 52,
  maxWidth: 52,
  minHeight: kTextFieldHeight,
  maxHeight: kTextFieldHeight,
);

class DeckCreate extends StatefulWidget {
  const DeckCreate({super.key, this.deck});

  final Deck? deck;

  @override
  State createState() => _DeckCreateState();
}

class _DeckCreateState extends State<DeckCreate> with DelayedInitMixin {
  /// Two empty column headers by default when creating a deck.
  static const List<String> _defaultNewDeckFields = ['', ''];
  late List<TextEditingController> _fieldControllers;
  late List<FocusNode> _fieldFocusNodes;
  late final FocusNode _deckNameFocusNode;

  // ── tag state ────────────────────────────────────────────
  /// Tag IDs already on the deck when the edit sheet opened (edit mode only).
  Set<String> _originalTagIds = {};

  /// Tag IDs currently selected by the user.
  Set<String> _selectedTagIds = {};

  /// Full Tag objects for the selected IDs (for display).
  List<Tag> _selectedTags = [];
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _deckNameFocusNode = FocusNode();
    _deckNameFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _fieldControllers = [
      for (final t in _defaultNewDeckFields) TextEditingController(text: t),
    ];
    _fieldFocusNodes = [
      for (var i = 0; i < _defaultNewDeckFields.length; i++)
        _createFieldFocusNode(),
    ];
  }

  @override
  void dispose() {
    _deckNameFocusNode.dispose();
    for (final c in _fieldControllers) {
      c.dispose();
    }
    for (final n in _fieldFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _createFieldFocusNode() {
    final node = FocusNode();
    node.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    return node;
  }

  void _resetFieldControllers(List<String> texts) {
    for (final c in _fieldControllers) {
      c.dispose();
    }
    for (final n in _fieldFocusNodes) {
      n.dispose();
    }
    _fieldControllers = [for (final t in texts) TextEditingController(text: t)];
    _fieldFocusNodes = [for (final _ in texts) _createFieldFocusNode()];
  }

  void _addField() {
    setState(() {
      _fieldControllers.add(TextEditingController());
      _fieldFocusNodes.add(_createFieldFocusNode());
    });
  }

  int? _draggingFieldIndex;

  TagManagerCubit? _maybeTagManager() {
    try {
      return context.read<TagManagerCubit>();
    } catch (_) {
      return null;
    }
  }

  @override
  void afterFirstLayout() {
    final createCubit = context.read<DeckCreateCubit>();
    if (widget.deck != null) {
      createCubit.setMode(
        name: widget.deck!.name,
        rate: widget.deck!.rate,
        cardType: DeckCardType.edit,
        deckId: widget.deck!.id,
        isImported: widget.deck!.isImported,
      );
      _resetFieldControllers(widget.deck!.fields);
      _loadExistingTags(widget.deck!.id);
    } else {
      createCubit.setMode(
        name: '',
        rate: kDeckEditorRateDefault,
        cardType: DeckCardType.add,
        deckId: '',
      );
      _resetFieldControllers(_defaultNewDeckFields);
    }
    // Load the user's full tag list so the picker has data.
    final tagManager = _maybeTagManager();
    if (tagManager == null) {
      setState(() {});
      return;
    }
    if (tagManager.state.status == TagManagerStatus.initial) {
      tagManager.loadTags();
    }
    setState(() {});
  }

  /// For edit mode: load the deck's current tags so we can show + diff them.
  Future<void> _loadExistingTags(String deckId) async {
    try {
      final existing = await TagService.of.getDeckTags(deckId);
      if (!mounted) return;
      final ids = existing.map((t) => t.id).toSet();
      setState(() {
        _selectedTags = existing;
        _selectedTagIds = ids;
        _originalTagIds = Set.of(ids); // snapshot for diff on save
      });
    } catch (_) {
      // Non-fatal: tag section will just start empty.
    }
  }

  /// Opens the tag picker and applies the returned selection.
  Future<void> _openTagPicker() async {
    final tagManager = _maybeTagManager();
    if (tagManager == null) return;

    final result = await showTagPickerSheet(
      context,
      selectedIds: _selectedTagIds,
    );
    if (result == null || !mounted) return;

    // Resolve full Tag objects from the manager's list.
    final allTags = tagManager.state.tags;
    final resolved = result
        .map(
          (id) => allTags.firstWhere(
            (t) => t.id == id,
            orElse: () => Tag(id: id, name: id, description: ''),
          ),
        )
        .toList();

    setState(() {
      _selectedTagIds = result;
      _selectedTags = resolved;
    });
  }

  /// After a successful save, syncs selected tags with the deck (diff-based).
  Future<void> _syncTags(String deckId) async {
    final toAdd = _selectedTagIds.difference(_originalTagIds);
    final toRemove = _originalTagIds.difference(_selectedTagIds);
    await Future.wait([
      ...toAdd.map((id) => TagService.of.addTagToDeck(deckId, id)),
      ...toRemove.map((id) => TagService.of.removeTagFromDeck(deckId, id)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rate = context.select((DeckCreateCubit cubit) => cubit.state.rate);
    final isImported = context.select(
      (DeckCreateCubit cubit) => cubit.state.isImported,
    );
    final createCubit = context.read<DeckCreateCubit>();

    return Column(
      spacing: 14,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              Row(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(LucideIcons.activity, size: 24, color: scheme.primary),
                  NumberPicker(
                    minValue: kDeckEditorRateMin,
                    maxValue: kDeckEditorRateMax,
                    itemWidth: _kDeckCreateNumberPickerSize,
                    itemHeight: _kDeckCreateNumberPickerSize,
                    step: 1,
                    axis: Axis.vertical,
                    value: rate,
                    textStyle: DeckTextStyles.rateValue(theme),
                    selectedTextStyle: DeckTextStyles.selectedRateValue(theme),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _kDeckCreateNumberPickerRadius,
                      ),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.8),
                      ),
                      color: scheme.surfaceContainerHighest,
                    ),
                    onChanged: (value) {
                      createCubit.changeRate(value);
                    },
                  ),
                  Text(loc.cardsPerDay, style: DeckTextStyles.rateLabel(theme)),
                ],
              ),
              Text(
                loc.newCardEveryMinutes(((86400 / rate) / 60).toInt()),
                textAlign: TextAlign.center,
                style: DeckTextStyles.rateHint(theme),
              ),
            ],
          ),
        ),

        // AppInput for deck name.
        AppInput(
          controller: createCubit.nameController,
          focusNode: _deckNameFocusNode,
          label: context.loc.createInputDeckName,
          enabled: !isImported,
          onChanged: (_) {
            if (_submitError != null) {
              setState(() => _submitError = null);
            }
          },
        ),

        // ── Tags section ──────────────────────────────────
        _TagsSection(
          selectedTags: _selectedTags,
          onRemove: (tagId) {
            setState(() {
              _selectedTagIds.remove(tagId);
              _selectedTags.removeWhere((t) => t.id == tagId);
            });
          },
          onPickTags: _openTagPicker,
        ),

        // TextFields for deck fields with reordering.
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isImported)
              ...List.generate(_fieldControllers.length, (i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        4,
                        _kDeckCreateFieldLabelTopPadding,
                        4,
                        _kDeckCreateFieldLabelBottomPadding,
                      ),
                      child: Text(
                        '${context.loc.addFactFieldShortLabel} ${i + 1}',
                        style: DeckTextStyles.fieldLabel(theme),
                      ),
                    ),
                    AppInput(
                      controller: _fieldControllers[i],
                      style: DeckTextStyles.fieldInput(theme),
                      enabled: false,
                    ),
                  ],
                );
              })
            else ...[
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderStart: (index) {
                  setState(() {
                    _draggingFieldIndex = index;
                  });
                },
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final controller = _fieldControllers.removeAt(oldIndex);
                    final focusNode = _fieldFocusNodes.removeAt(oldIndex);
                    _fieldControllers.insert(newIndex, controller);
                    _fieldFocusNodes.insert(newIndex, focusNode);
                    _draggingFieldIndex = null;
                  });
                },
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) {
                      final scale = 1.0 + 0.05 * animation.value;
                      return Transform.scale(
                        scale: scale,
                        child: Material(
                          type: MaterialType.transparency,
                          child: child,
                        ),
                      );
                    },
                  );
                },
                itemCount: _fieldControllers.length,
                itemBuilder: (context, i) {
                  final isDimmed =
                      _draggingFieldIndex != null && _draggingFieldIndex != i;
                  return AnimatedOpacity(
                    key: ValueKey('deck_field_$i'),
                    duration: const Duration(milliseconds: 150),
                    opacity: isDimmed ? 0.25 : 1,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                4,
                                _kDeckCreateFieldLabelTopPadding,
                                4,
                                _kDeckCreateFieldLabelBottomPadding,
                              ),
                              child: Text(
                                '${context.loc.addFactFieldShortLabel} ${i + 1}',
                                style: DeckTextStyles.fieldLabel(theme),
                              ),
                            ),
                            ReorderableDelayedDragStartListener(
                              index: i,
                              child: AppInput(
                                controller: _fieldControllers[i],
                                focusNode: _fieldFocusNodes[i],
                                style: DeckTextStyles.fieldInput(theme),
                                suffixConstraints:
                                    _kDeckCreateSuffixConstraints,
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: IgnorePointer(
                                    ignoring: !_fieldFocusNodes[i].hasFocus,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 140,
                                      ),
                                      opacity: _fieldFocusNodes[i].hasFocus
                                          ? 1
                                          : 0,
                                      child: AppIconButton(
                                        icon: LucideIcons.trash2,
                                        tooltip:
                                            loc.deckEditorRemoveFieldTooltip,
                                        variant: _fieldControllers.length == 2
                                            ? AppIconButtonVariant.subtle
                                            : AppIconButtonVariant.danger,
                                        size: 17,
                                        iconSize: 17,
                                        constraints: kIconBtnConstraints,
                                        onPressed: _fieldControllers.length == 2
                                            ? null
                                            : () {
                                                setState(() {
                                                  _fieldControllers
                                                      .removeAt(i)
                                                      .dispose();
                                                  _fieldFocusNodes
                                                      .removeAt(i)
                                                      .dispose();
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Add field button.
              Align(
                alignment: Alignment.center,
                child: AppButton(
                  label: loc.deckCreateAddField,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  onPressed: _addField,
                ),
              ),
            ],
          ],
        ),

        AppButton(
          label: loc.save,
          variant: AppButtonVariant.primary,
          fullWidth: true,
          leading: const DeckLoadingState(child: Icon(LucideIcons.save)),
          onPressed: () async {
            final deckListCubit = context.read<DeckListCubit>();
            final navigator = Navigator.of(context);
            setState(() => _submitError = null);
            final result = await createCubit.submit(
              fieldNames: _fieldControllers.map((c) => c.text).toList(),
            );
            if (!mounted) {
              return;
            }

            if (!result.success) {
              final msg = result.message?.isNotEmpty == true
                  ? result.message!
                  : (loc.deckEditorNameRequired);
              setState(() => _submitError = msg);
              return;
            }

            // Sync tags after successful save (diff-based).
            final deckId = result.newDeckId ?? createCubit.state.deckId;
            if (deckId.isNotEmpty) {
              try {
                await _syncTags(deckId);
              } catch (e) {
                if (!mounted) {
                  return;
                }
                setState(() => _submitError = e.toString());
                return;
              }
            }

            await deckListCubit.onRefresh();
            if (!mounted) {
              return;
            }
            navigator.pop(result.updatedDeckName);
          },
        ),
        if (_submitError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _submitError!,
              style: DeckTextStyles.feedbackMessage(theme, scheme.error),
            ),
          ),
      ],
    );
  }
}

// ── Tags section widget ───────────────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  const _TagsSection({
    required this.selectedTags,
    required this.onRemove,
    required this.onPickTags,
  });

  final List<Tag> selectedTags;
  final void Function(String tagId) onRemove;
  final VoidCallback onPickTags;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          children: [
            Icon(LucideIcons.tag, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              loc.tagLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onPickTags,
              icon: const Icon(LucideIcons.plus, size: 14),
              label: Text(loc.addTag),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (selectedTags.isNotEmpty)
          TagChipRow(tags: selectedTags, onRemove: onRemove),
      ],
    );
  }
}

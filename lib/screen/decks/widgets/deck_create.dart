import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/mixins/delayed_init_mixin.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/deck_text_styles.dart';
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

  @override
  void afterFirstLayout() {
    final createCubit = context.read<DeckCreateCubit>();
    if (widget.deck != null) {
      createCubit.setMode(
        name: widget.deck!.name,
        rate: widget.deck!.rate,
        cardType: DeckCardType.edit,
        deckId: widget.deck!.id,
      );
      _resetFieldControllers(widget.deck!.fields);
    } else {
      createCubit.setMode(
        name: '',
        rate: kDeckEditorRateDefault,
        cardType: DeckCardType.add,
        deckId: '',
      );
      _resetFieldControllers(_defaultNewDeckFields);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rate = context.select((DeckCreateCubit cubit) => cubit.state.rate);
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
        ),

        // TextFields for deck fields with reordering.
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderStart: (index) {
                setState(() {
                  _draggingFieldIndex = index;
                });
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
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
                              suffixConstraints: _kDeckCreateSuffixConstraints,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: IgnorePointer(
                                  ignoring: !_fieldFocusNodes[i].hasFocus,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 140),
                                    opacity: _fieldFocusNodes[i].hasFocus
                                        ? 1
                                        : 0,
                                    child: AppIconButton(
                                      icon: LucideIcons.trash2,
                                      tooltip: loc.deckEditorRemoveFieldTooltip,
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
        ),

        AppButton(
          label: loc.save,
          variant: AppButtonVariant.primary,
          fullWidth: true,
          leading: const DeckLoadingState(child: Icon(LucideIcons.save)),
          onPressed: () async {
            final deckListCubit = context.read<DeckListCubit>();
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
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
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    msg,
                    style: DeckTextStyles.feedbackMessage(
                      theme,
                      scheme.onError,
                    ),
                  ),
                  backgroundColor: scheme.error,
                ),
              );
              return;
            }

            await deckListCubit.onRefresh();
            if (!mounted) {
              return;
            }
            navigator.pop(result.updatedDeckName);
          },
        ),
      ],
    );
  }
}

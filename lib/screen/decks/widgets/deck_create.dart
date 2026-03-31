import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/mixins/delayed_init_mixin.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/providers/deck_create.dart';
import 'package:retentio/widgets/number_picker.dart';

import 'deck_loading_state.dart';

class DeckCreate extends ConsumerStatefulWidget {
  const DeckCreate({super.key, this.deck});

  final Deck? deck;

  @override
  ConsumerState createState() => _DeckCreateState();
}

class _DeckCreateState extends ConsumerState<DeckCreate> with DelayedInitMixin {
  /// Two empty column headers by default when creating a deck.
  static const List<String> _defaultNewDeckFields = ['', ''];
  static const double _textFieldHeight = 46;
  static const double _buttonHeight = 46;

  late List<TextEditingController> _fieldControllers;
  late final FocusNode _deckNameFocusNode;

  static const _fieldAddRemoveIconBtn = BoxConstraints(
    minWidth: 44,
    minHeight: 44,
  );

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
  }

  @override
  void dispose() {
    _deckNameFocusNode.dispose();
    for (final c in _fieldControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetFieldControllers(List<String> texts) {
    for (final c in _fieldControllers) {
      c.dispose();
    }
    _fieldControllers = [for (final t in texts) TextEditingController(text: t)];
  }

  void _addField() {
    setState(() {
      _fieldControllers.add(TextEditingController());
    });
  }

  int? _draggingFieldIndex;

  @override
  void afterFirstLayout() {
    if (widget.deck != null) {
      ref
          .read(createDeckParamsProvider.notifier)
          .update(
            (state) => CreateDeckParams(
              name: widget.deck!.name,
              rate: widget.deck!.rate,
              type: DeckCardType.edit,
              id: widget.deck!.id,
              fields: widget.deck!.fields,
            ),
          );
      _resetFieldControllers(widget.deck!.fields);
    } else {
      ref
          .read(createDeckParamsProvider.notifier)
          .update(
            (state) => CreateDeckParams(
              name: '',
              rate: kDeckEditorRateDefault,
              type: DeckCardType.add,
              id: '',
              fields: _defaultNewDeckFields,
            ),
          );
      _resetFieldControllers(_defaultNewDeckFields);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final rate = ref.watch(createDeckProvider.select((value) => value.rate));

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Row(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(LucideIcons.activity, size: 24),
                  NumberPicker(
                    minValue: kDeckEditorRateMin,
                    maxValue: kDeckEditorRateMax,
                    itemWidth: 44,
                    itemHeight: 44,
                    step: 1,
                    axis: Axis.vertical,
                    value: rate,
                    textStyle: TextStyle(fontSize: 16),
                    selectedTextStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                    ),
                    onChanged: (value) {
                      ref.read(createDeckProvider.notifier).changeRate(value);
                    },
                  ),
                  Text(loc.cardsPerDay, style: TextStyle(fontSize: 16)),
                ],
              ),
              Text(
                loc.newCardEveryMinutes(((86400 / rate) / 60).toInt()),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // TextField for deck name.
        TextField(
          controller: ref.read(createDeckProvider.notifier).nameController,
          focusNode: _deckNameFocusNode,
          minLines: 1,
          maxLines: 1,
          textAlign: TextAlign.left,
          selectAllOnFocus: true,
          onTapAlwaysCalled: true,
          decoration: InputDecoration(
            labelText: context.loc.createInputDeckName,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              // 使文本区域本身高度接近 _textFieldHeight（假设字体 16）
              vertical: (_textFieldHeight - 16) / 2,
            ),
            filled: Theme.of(context).inputDecorationTheme.filled,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
        ),

        // TextFields for deck fields with reordering.
        Column(
          spacing: 16,
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
                  _fieldControllers.insert(newIndex, controller);
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
                            padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
                            child: Text(
                              '${context.loc.addFactFieldShortLabel} ${i + 1}',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(fontSize: 14),
                            ),
                          ),
                          TextField(
                            controller: _fieldControllers[i],
                            minLines: 1,
                            maxLines: 1,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                // 控制文本区域本身高度接近 _textFieldHeight（假设字体 16）
                                vertical: (_textFieldHeight - 16) / 2,
                              ),
                              filled: Theme.of(
                                context,
                              ).inputDecorationTheme.filled,
                              fillColor: Theme.of(
                                context,
                              ).inputDecorationTheme.fillColor,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 2,
                                  children: [
                                    IconButton(
                                      tooltip: loc.deckEditorRemoveFieldTooltip,
                                      padding: EdgeInsets.zero,
                                      constraints: _fieldAddRemoveIconBtn,
                                      onPressed: _fieldControllers.length == 2
                                          ? null
                                          : () {
                                              setState(() {
                                                _fieldControllers
                                                    .removeAt(i)
                                                    .dispose();
                                              });
                                            },
                                      icon: Icon(
                                        LucideIcons.trash2,
                                        size: 18,
                                        color: _fieldControllers.length == 2
                                            ? Theme.of(context).disabledColor
                                            : Theme.of(
                                                context,
                                              ).colorScheme.error,
                                      ),
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: Icon(
                                        LucideIcons.gripVertical,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
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
              child: TextButton(
                onPressed: _addField,
                child: Text(
                  loc.deckCreateAddField,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),

        SizedBox(
          height: _buttonHeight,
          child: FilledButton(
            onPressed: () {
              ref
                  .read(createDeckProvider.notifier)
                  .createDeck(
                    context,
                    _fieldControllers.map((c) => c.text).toList(),
                  );
            },
            child: Row(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DeckLoadingState(child: Icon(LucideIcons.save)),
                Text(loc.save, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

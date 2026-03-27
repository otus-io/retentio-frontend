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

  late List<TextEditingController> _fieldControllers;
  late final FocusNode _deckNameFocusNode;

  static InputDecoration _borderlessDecoration(
    BuildContext context, {
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
    );
  }

  static const _fieldAddRemoveIconBtn = BoxConstraints(
    minWidth: 44,
    minHeight: 44,
  );

  /// Thinner than [ _outlineDecoration]: ~25% of theme vertical padding (half of prior compact).
  static InputDecoration _outlineDecorationCompact(
    BuildContext context, {
    String? hintText,
  }) {
    final base = Theme.of(context).inputDecorationTheme;
    final dir = Directionality.of(context);
    final resolved =
        base.contentPadding?.resolve(dir) ??
        const EdgeInsets.fromLTRB(12, 16, 12, 16);
    const verticalScale = 0.2;
    return InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      contentPadding: EdgeInsets.fromLTRB(
        resolved.left,
        resolved.top * verticalScale,
        resolved.right,
        resolved.bottom * verticalScale,
      ),
      isDense: true,
      filled: base.filled,
      fillColor: base.fillColor,
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

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

  void _removeLastField() {
    if (_fieldControllers.isEmpty) return;
    setState(() {
      _fieldControllers.removeLast().dispose();
    });
  }

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
      spacing: 20,
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
                  Icon(LucideIcons.activity),
                  NumberPicker(
                    minValue: kDeckEditorRateMin,
                    maxValue: kDeckEditorRateMax,
                    itemWidth: 50,
                    itemHeight: 30,
                    step: 1,
                    axis: Axis.vertical,
                    value: rate,
                    selectedTextStyle: TextStyle(
                      fontSize: 18,
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
                  Text(loc.cardsPerDay),
                ],
              ),
              Text(
                loc.newCardEveryMinutes(((86400 / rate) / 60).toInt()),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        TextField(
          controller: ref.read(createDeckProvider.notifier).nameController,
          focusNode: _deckNameFocusNode,
          minLines: 1,
          maxLines: 1,
          textAlign: TextAlign.center,
          selectAllOnFocus: true,
          onTapAlwaysCalled: true,
          decoration: _borderlessDecoration(
            context,
            hintText: _deckNameFocusNode.hasFocus
                ? null
                : context.loc.createInputDeckName,
          ),
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _fieldControllers.length; i++)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Header ${i + 1}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(fontSize: 9),
                    ),
                  ),
                  TextField(
                    controller: _fieldControllers[i],
                    minLines: 1,
                    maxLines: 1,
                    decoration: _outlineDecorationCompact(
                      context,
                      hintText: null,
                    ),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: loc.deckEditorAddFieldTooltip,
                    padding: EdgeInsets.zero,
                    constraints: _fieldAddRemoveIconBtn,
                    onPressed: _addField,
                    icon: Icon(LucideIcons.plus),
                  ),
                  if (_fieldControllers.isNotEmpty)
                    IconButton(
                      tooltip: loc.deckEditorRemoveFieldTooltip,
                      padding: EdgeInsets.zero,
                      constraints: _fieldAddRemoveIconBtn,
                      onPressed: _removeLastField,
                      icon: Icon(
                        LucideIcons.minus,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        Row(
          spacing: 12,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.cancel),
              ),
            ),
            Expanded(
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
                    Text(loc.save),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

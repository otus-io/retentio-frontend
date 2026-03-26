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
  late List<TextEditingController> _fieldControllers;

  static InputDecoration _outlineDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final base = Theme.of(context).inputDecorationTheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: const OutlineInputBorder(),
      contentPadding: base.contentPadding,
      isDense: base.isDense,
      filled: base.filled,
      fillColor: base.fillColor,
      floatingLabelBehavior: base.floatingLabelBehavior,
    );
  }

  static ButtonStyle _fieldRowTrailingIconStyle() {
    return IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// ~50% vertical size vs [ _outlineDecoration ]; width matches deck name row.
  static InputDecoration _outlineDecorationCompact(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final base = Theme.of(context).inputDecorationTheme;
    final dir = Directionality.of(context);
    final resolved =
        base.contentPadding?.resolve(dir) ??
        const EdgeInsets.fromLTRB(12, 16, 12, 16);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: const OutlineInputBorder(),
      contentPadding: EdgeInsets.fromLTRB(
        resolved.left,
        resolved.top * 0.4,
        resolved.right,
        resolved.bottom * 0.4,
      ),
      isDense: true,
      filled: base.filled,
      fillColor: base.fillColor,
      floatingLabelBehavior: base.floatingLabelBehavior,
    );
  }

  @override
  void initState() {
    super.initState();
    _fieldControllers = [TextEditingController()];
  }

  @override
  void dispose() {
    for (final c in _fieldControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetFieldControllers(List<String> texts) {
    for (final c in _fieldControllers) {
      c.dispose();
    }
    _fieldControllers = texts.isEmpty
        ? [TextEditingController()]
        : [for (final t in texts) TextEditingController(text: t)];
  }

  void _addField() {
    setState(() {
      _fieldControllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    if (_fieldControllers.length <= 1) return;
    setState(() {
      _fieldControllers.removeAt(index).dispose();
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
              rate: 10,
              type: DeckCardType.add,
              id: '',
              fields: const [],
            ),
          );
      _resetFieldControllers(const []);
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

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Expanded(
              child: TextField(
                controller: (ref
                    .read(createDeckProvider.notifier)
                    .nameController),
                minLines: 1,
                maxLines: 1,
                decoration: _outlineDecoration(
                  context,
                  labelText: context.loc.createInputDeckName,
                ),
              ),
            ),
            if (_fieldControllers.length > 1)
              Visibility(
                visible: false,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(LucideIcons.minus),
                  style: _fieldRowTrailingIconStyle(),
                ),
              ),
          ],
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _fieldControllers.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _fieldControllers[i],
                          minLines: 1,
                          maxLines: 1,
                          decoration: _outlineDecorationCompact(
                            context,
                            labelText: loc.deckEditorField,
                            hintText: loc.deckEditorFieldHint,
                          ),
                        ),
                        if (i == _fieldControllers.length - 1)
                          Align(
                            alignment: Alignment.center,
                            child: IconButton(
                              tooltip: loc.deckEditorAddFieldTooltip,
                              onPressed: _addField,
                              icon: Icon(LucideIcons.plus),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_fieldControllers.length > 1)
                    IconButton(
                      tooltip: loc.deckEditorRemoveFieldTooltip,
                      onPressed: () => _removeField(i),
                      icon: Icon(LucideIcons.minus),
                      style: _fieldRowTrailingIconStyle(),
                    ),
                ],
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

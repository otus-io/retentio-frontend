import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/mixins/delayed_init_mixin.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/learn/providers/create_deck_provider.dart';
import 'package:retentio/widgets/number_picker.dart';

import 'loading_state_widget.dart';

class CreateDeckWidget extends ConsumerStatefulWidget {
  const CreateDeckWidget({super.key, this.deck});

  final Deck? deck;

  @override
  ConsumerState createState() => _CreateDeckWidgetState();
}

class _CreateDeckWidgetState extends ConsumerState<CreateDeckWidget>
    with DelayedInitMixin {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 16,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(LucideIcons.activity),
                Text('${context.loc.rate}:'),
                NumberPicker(
                  minValue: kDeckEditorRateMin,
                  maxValue: kDeckEditorRateMax,
                  itemWidth: 50,
                  itemHeight: 30,
                  step: 1,
                  axis: Axis.vertical,
                  value: ref.watch(
                    createDeckProvider.select((value) => value.rate),
                  ),
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
              ],
            ),
            Text(
              loc.newCardEveryMinutes(
                ((86400 /
                            ref.watch(
                              createDeckProvider.select((value) => value.rate),
                            )) /
                        60)
                    .toInt(),
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),

        Row(
          spacing: 16,
          children: [
            TextField(
              controller: (ref
                  .read(createDeckProvider.notifier)
                  .nameController),
              decoration: InputDecoration(
                labelText: context.loc.createInputDeckName,
                //hintText: context.loc.createInputDeckNameHint,
                border: const OutlineInputBorder(),
              ),
            ).expanded(),
          ],
        ),
        Row(
          spacing: 16,
          mainAxisSize: .max,
          mainAxisAlignment: .spaceBetween,
          children: [
            TextField(
              controller: (ref
                  .read(createDeckProvider.notifier)
                  .fieldController1),
              decoration: InputDecoration(
                labelText: 'field',
                hintText: 'eg:English',
                border: const OutlineInputBorder(),
              ),
            ).expanded(),
            TextField(
              controller: (ref
                  .read(createDeckProvider.notifier)
                  .fieldController2),
              decoration: InputDecoration(
                labelText: 'field',
                hintText: 'eg:Chinese',
                border: const OutlineInputBorder(),
              ),
            ).expanded(),
          ],
        ),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ref.read(createDeckProvider.notifier).createDeck(context);
            },
            child: Row(
              spacing: 5,
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              children: [
                LoadingStateWidget(child: Icon(LucideIcons.save)),
                Text(loc.save),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

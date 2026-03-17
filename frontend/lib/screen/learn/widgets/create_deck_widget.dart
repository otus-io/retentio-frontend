import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/mixins/delayed_init_mixin.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/learn/providers/create_deck_provider.dart';

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
              fields: widget.deck!.fields,
              name: widget.deck!.name,
              templates: widget.deck!.templates,
              rate: widget.deck!.rate,
              type: DeckCardType.edit,
              id: widget.deck!.id,
            ),
          );
    } else {
      ref
          .read(createDeckParamsProvider.notifier)
          .update(
            (state) => CreateDeckParams(
              fields: ['English', 'Chinese'],
              name: '',
              rate: 10,
              templates: [
                [0, 1],
              ],
              type: DeckCardType.add,
              id: '',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        Row(
          spacing: 16,
          mainAxisSize: .max,
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          children: [
            Icon(LucideIcons.activity),
            Text('${context.loc.rate}:'),
            Spacer(),
            Column(
              mainAxisSize: .min,
              children: [
                SizedBox(
                  width: 200,
                  child: RadioGroup(
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(createDeckProvider.notifier).changeRate(value);
                      }
                    },
                    groupValue: ref.watch(
                      createDeckProvider.select((value) => value.rate),
                    ),
                    child: RadioListTile<Rate>(
                      contentPadding: .zero,
                      title: Text(context.loc.slow),
                      value: Rate.slow,
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: RadioGroup(
                    groupValue: ref.watch(
                      createDeckProvider.select((value) => value.rate),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(createDeckProvider.notifier).changeRate(value);
                      }
                    },
                    child: RadioListTile<Rate>(
                      contentPadding: .zero,
                      title: Text(context.loc.fast),
                      value: Rate.fast,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          spacing: 16,
          mainAxisSize: .max,
          mainAxisAlignment: .spaceAround,
          children: [
            Icon(LucideIcons.sendToBack),
            Text('${context.loc.template}:'),
            Spacer(),
            Column(
              children: [
                SizedBox(
                  width: 200,
                  child: RadioGroup(
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(createDeckProvider.notifier)
                            .changeTemplate(value);
                      }
                    },
                    groupValue: ref.read(
                      createDeckProvider.select((value) => value.templates),
                    ),
                    child: RadioListTile<int>(
                      hoverColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      contentPadding: .zero,
                      title: Text(context.loc.unidirectional),
                      value: 0,
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: RadioGroup(
                    groupValue: ref.watch(
                      createDeckProvider.select((value) => value.templates),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(createDeckProvider.notifier)
                            .changeTemplate(value);
                      }
                    },
                    child: RadioListTile<int>(
                      contentPadding: .zero,
                      title: Text(context.loc.bidirectional),
                      value: 1,
                    ),
                  ),
                ),
              ],
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
                hintText: context.loc.createInputDeckNameHint,
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
                Text('Save'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

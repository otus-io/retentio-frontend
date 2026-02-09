import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wordupx/extensions/context_extension.dart';
import 'package:wordupx/extensions/widget_extension.dart';
import 'package:wordupx/main.dart';
import 'package:wordupx/screen/learn/providers/create_deck_provider.dart';

class CreateDeckWidget extends ConsumerStatefulWidget {
  const CreateDeckWidget({super.key});

  @override
  ConsumerState createState() => _CreateDeckWidgetState();
}

class _CreateDeckWidgetState extends ConsumerState<CreateDeckWidget> {
  @override
  Widget build(BuildContext context) {
    final desk = ref.watch(createDeckProvider);
    final languages = ref.read(createDeckProvider.notifier).languages;
    return Column(
      spacing: 20,
      children: [
        Row(
          spacing: 16,
          children: [
            Icon(LucideIcons.languages),
            Text('${context.loc.language}:'),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: desk.fields.first,
                icon: const Icon(Icons.arrow_drop_down),
                padding: .zero,
                style: Theme.of(context).textTheme.titleMedium,
                borderRadius: BorderRadius.circular(4),

                items: languages
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),

                // 语言切换
                onChanged: (String? newLocale) {
                  if (newLocale != null) {
                    ref
                        .read(createDeckProvider.notifier)
                        .changeField(0, newLocale);
                  }
                },
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: desk.fields.last,
                padding: .symmetric(horizontal: 5),
                icon: const Icon(Icons.arrow_drop_down),
                style: Theme.of(context).textTheme.titleMedium,
                borderRadius: BorderRadius.circular(4),
                items: languages
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),

                // 语言切换
                onChanged: (String? newLocale) {
                  if (newLocale != null) {
                    ref
                        .read(createDeckProvider.notifier)
                        .changeField(0, newLocale);
                  }
                },
              ),
            ),
          ],
        ),

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
                    groupValue: ref.read(
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
                    groupValue: ref.read(
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
            Text('${context.loc.rate}:'),
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
                    groupValue: ref.read(
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
          child: FilledButton.icon(
            onPressed: () {

              ref.read(createDeckProvider.notifier).createDeck();
            },
            icon: Icon(LucideIcons.save),
            label: Text('Save'),
          ),
        ),
      ],
    );
  }
}

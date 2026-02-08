import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wordupx/extensions/context_extension.dart';
import 'package:wordupx/extensions/widget_extension.dart';
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
          spacing: 25,
          children: [
            Icon(LucideIcons.languages),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: desk.fields.first,
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
              obscureText: true,
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

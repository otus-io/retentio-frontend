import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/deck.dart';
import '../../learn/widgets/loading_state_widget.dart';
import '../providers/edit_fact_provider.dart';

class EditFactWidget extends ConsumerWidget {
  const EditFactWidget({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: FocusTraversalGroup(
        child: Form(
          autovalidateMode: AutovalidateMode.always,
          onChanged: () {},
          child: Column(
            spacing: 20,
            children: [
              TextFormField(
                controller: ref
                    .watch(editFactProvider.notifier)
                    .questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: ref
                    .watch(editFactProvider.notifier)
                    .answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an answer';
                  }
                  return null;
                },
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
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
          ),
        ),
      ),
    );
  }
}

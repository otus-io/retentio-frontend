import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_menu.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_body.dart';

import '../decks/providers/deck_create.dart';

class DeckViewScreen extends StatefulWidget {
  final Deck deck;

  const DeckViewScreen({super.key, required this.deck});

  @override
  State<DeckViewScreen> createState() => _DeckViewScreenState();
}

class _DeckViewScreenState extends State<DeckViewScreen> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        deckProvider.overrideWithValue(widget.deck),
        createDeckParamsProvider.overrideWithBuild((ref, notifier) {
          return CreateDeckParams(
            name: widget.deck.name,
            rate: widget.deck.rate,
            type: DeckCardType.edit,
            id: widget.deck.id,
            fields: widget.deck.fields,
          );
        }),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(ref.watch(createDeckParamsProvider).name),
              actions: [DeckMenu(deck: widget.deck)],
            ),
            body: const DeckViewBody(),
          );
        },
      ),
    );
  }
}

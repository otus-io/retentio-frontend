import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deck.dart';
import 'card_provider.dart';

final editFactProvider = NotifierProvider.autoDispose(
  EditFactNotifier.new,
  dependencies: [deckProvider],
);
final deckProvider = Provider.autoDispose<Deck>(
  (ref) => throw UnimplementedError(
    'deckProvider must be overridden in EditFactNotifier',
  ),
);

class EditFactNotifier extends Notifier {
  final TextEditingController answerController = TextEditingController();
  final TextEditingController questionController = TextEditingController();

  @override
  build() {
    final deck = ref.watch(deckProvider);
    final fact = ref.read(cardProvider(deck)).cardDetail?.card.fact;
    if (fact != null) {
      questionController.text = fact.fields.first;
      answerController.text = fact.fields.last;
    }
    ref.onDispose(() {
      answerController.dispose();
      questionController.dispose();
    });
  }
}

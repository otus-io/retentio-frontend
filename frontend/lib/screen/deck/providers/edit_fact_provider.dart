import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deck.dart';
import '../../../services/apis/card_service.dart';
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

  Future<bool> updateFact() async {
    final deck = ref.read(deckProvider);
    final fact = ref.read(cardProvider(deck)).cardDetail?.card.fact;
    final facts = [questionController.text, answerController.text];
    final res = await CardService.updateFact(deck.id, fact!.id, facts);
    bool success = res?.isSuccess == true;
    if (success) {
      ref.read(cardProvider(deck).notifier).refreshFact();
    }
    return success;
  }
}

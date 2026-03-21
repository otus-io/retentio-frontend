import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/card.dart';
import '../../../services/apis/card_service.dart';
import 'card_provider.dart';

String _primaryTextFromSlot(Back slot) {
  for (final i in slot.items) {
    if (i.type == "text") return i.value;
  }
  if (slot.items.isEmpty) return "";
  return slot.items.first.value;
}

final editFactProvider = NotifierProvider.autoDispose(
  EditFactNotifier.new,
  dependencies: [deckProvider],
);

class EditFactNotifier extends Notifier {
  final TextEditingController answerController = TextEditingController();
  final TextEditingController questionController = TextEditingController();

  @override
  build() {
    final fact = ref.read(cardProvider).cardDetail?.card;
    if (fact != null) {
      questionController.text = _primaryTextFromSlot(fact.front.first);
      answerController.text = _primaryTextFromSlot(fact.back.last);
    }
    ref.onDispose(() {
      answerController.dispose();
      questionController.dispose();
    });
  }

  Future<bool> updateFact() async {
    final deck = ref.read(deckProvider);
    final fact = ref.read(cardProvider).cardDetail?.card;
    final facts = [questionController.text, answerController.text];
    final res = await CardService.updateFact(deck.id, fact!.id, facts);
    bool success = res?.isSuccess == true;
    if (success) {
      ref.read(cardProvider.notifier).getCardDetail();
    }
    return success;
  }
}

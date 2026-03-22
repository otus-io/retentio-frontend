import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/apis/card_service.dart';
import 'card_provider.dart';

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
      // questionController.text = fact.front.first.items.first.value;
      // answerController.text = fact.back.last.items.first.value;
    }
    ref.onDispose(() {
      answerController.dispose();
      questionController.dispose();
    });
  }

  Future<bool> updateFact() async {
    final deck = ref.read(deckProvider);
    final fact = ref.read(cardProvider).cardDetail?.card;
    // final facts = [questionController.text, answerController.text];
    final res = await CardService.updateFact(deck.id, fact!.id, {});
    bool success = res?.isSuccess == true;
    if (success) {
      ref.read(cardProvider.notifier).getCardDetail();
    }
    return success;
  }
}

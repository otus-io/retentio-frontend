import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/card.dart';
import '../providers/card_review.dart';
import 'card_content_container.dart';
import 'card_menu.dart';

/// One side (front or back) of the current review card on the deck study screen:
/// field tabs, field content, and card actions (hide / edit fact / delete).
class CardSideContent extends ConsumerWidget {
  const CardSideContent({super.key, required this.isFront});

  final bool isFront;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.read(
      cardProvider.select(
        (value) => isFront
            ? value.cardDetail?.card.front
            : value.cardDetail?.card.back,
      ),
    );
    final sideCards = cards ?? <CardSlot>[];
    final color = isFront ? Colors.blue : Colors.green;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: DefaultTabController(
        key: ValueKey('${ref.read(cardProvider).cardDetail?.card.id}'),
        length: sideCards.length,
        child: CardContentContainer(
          cards: sideCards,
          color: color,
          trailing: sideCards.isNotEmpty ? CardMenu(color: color) : null,
        ),
      ),
    );
  }
}

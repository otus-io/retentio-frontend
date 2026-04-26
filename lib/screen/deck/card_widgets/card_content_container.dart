import 'package:flutter/material.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';

class CardContentContainer extends StatelessWidget {
  const CardContentContainer({
    super.key,
    required this.cards,
    required this.color,
    this.trailing,
  });

  static const int _maxVisibleFields = 5;

  final List<CardSlot> cards;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleCards = cards.take(_maxVisibleFields).toList(growable: false);
    final hiddenCards = cards.skip(_maxVisibleFields).toList(growable: false);

    return Column(
      children: [
        if (trailing != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
            child: Align(alignment: Alignment.centerRight, child: trailing!),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const verticalPadding = 20.0;
              const dividerExtent = 1.0;
              final dividerCount = visibleCards.isNotEmpty
                  ? visibleCards.length - 1
                  : 0;
              final availableHeight =
                  (constraints.maxHeight -
                          verticalPadding -
                          (dividerCount * dividerExtent))
                      .clamp(0.0, double.infinity);
              final rowHeight = visibleCards.isEmpty
                  ? 0.0
                  : availableHeight / visibleCards.length;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    for (
                      var index = 0;
                      index < visibleCards.length;
                      index++
                    ) ...[
                      FactSummaryFieldRow(
                        card: visibleCards[index],
                        color: color,
                        rowHeight: rowHeight,
                      ),
                      if (index < visibleCards.length - 1)
                        Divider(
                          height: dividerExtent,
                          thickness: 0.3,
                          color: color.withValues(alpha: 0.22),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (hiddenCards.isNotEmpty)
          FactSummaryHiddenFieldsButton(
            count: hiddenCards.length,
            color: color,
            onPressed: () => showFactSummaryHiddenFieldsDialog(
              context,
              hiddenCards: hiddenCards,
              color: color,
            ),
          ),
      ],
    );
  }
}

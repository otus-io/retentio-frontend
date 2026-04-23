import 'package:flutter/material.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:retentio/widgets/buttons_tab_bar.dart';

class CardContentContainer extends StatelessWidget {
  const CardContentContainer({
    super.key,
    required this.cards,
    required this.color,
    this.trailing,
    this.typographyDeckId,
    this.typographyIsFront = true,
  });

  final List<CardSlot> cards;
  final Color color;
  final Widget? trailing;
  final String? typographyDeckId;
  final bool typographyIsFront;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.3, color: color)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              ButtonsTabBar(
                backgroundColor: Colors.transparent,
                unselectedBackgroundColor: Colors.transparent,
                borderWidth: 1,
                radius: 10,
                borderColor: Colors.transparent,
                unselectedBorderColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
                tabs: cards.map((e) => Tab(text: e.field)).toList(),
              ).expanded(),
              ?trailing,
            ],
          ),
        ),
        TabBarView(
          children: cards
              .map(
                (e) => FactContent(
                  items: e.items,
                  color: color,
                  typographyDeckId: typographyDeckId,
                  typographyIsFront: typographyIsFront,
                ),
              )
              .toList(),
        ).expanded(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/extensions/widget_extension.dart';

import '../../../extensions/context_extension.dart';
import '../../../models/deck.dart';
import '../providers/card_provider.dart';
import 'buttons_tabbar/buttons_tab_bar_widget.dart';
import 'field_content_widget.dart';

class CardWidget extends ConsumerWidget {
  const CardWidget({super.key, required this.deck, required this.isFront});

  final Deck deck;
  final bool isFront;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(
      cardProvider(deck).select(
        (value) => isFront
            ? value.cardDetail?.card.front
            : value.cardDetail?.card.back,
      ),
    );
    final color = isFront ? Colors.blue : Colors.green;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: DefaultTabController(
        key: ValueKey('${ref.read(cardProvider(deck)).cardDetail?.card.id}'),
        length: cards?.length ?? 0,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(width: 0.3, color: color)),
              ),
              child: Row(
                mainAxisSize: .max,
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
                    // Add your tabs here
                    tabs:
                        cards?.map((e) {
                          return Tab(text: e.field);
                        }).toList() ??
                        [],
                  ).expanded(),
                  if (cards?.isNotEmpty == true)
                    SizedBox(
                      width: 50,
                      height: 46,
                      child: PullDownButton(
                        routeTheme: PullDownMenuRouteTheme(
                          width: 150,
                          backgroundColor: context.colorScheme.surface,
                        ),
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            title: 'Edit Fact',
                            onTap: () {
                              // showCommonBottomSheet(
                              //   context: context,
                              //   initialChildSize: 0.4,
                              //   minChildSize: 0.3,
                              //   maxChildSize: 0.5,
                              //   title: 'Edit Fact',
                              //   child: ProviderScope(
                              //     overrides: [deckProvider.overrideWithValue(widget.deck)],
                              //     child: EditFactWidget(deck: widget.deck),
                              //   ),
                              // );
                            },
                            icon: LucideIcons.pencil,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => IconButton(
                          onPressed: showMenu,
                          icon: Icon(
                            LucideIcons.ellipsisVertical,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TabBarView(
              children:
                  cards?.map((e) {
                    return FieldContentWidget(items: e.items, color: color);
                  }).toList() ??
                  [],
            ).expanded(),
          ],
        ),
      ),
    );
  }
}

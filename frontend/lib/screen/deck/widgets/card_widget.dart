import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/extensions/widget_extension.dart';

import '../../../models/deck.dart';
import '../providers/card_provider.dart';
import 'buttons_tabbar/buttons_tab_bar_widget.dart';

class CardWidget extends ConsumerWidget {
  const CardWidget({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardDetail = ref.watch(
      cardProvider(deck).select((value) => value.cardDetail),
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: DefaultTabController(
        length: cardDetail?.card.front.length ?? 0,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 0.3, color: Colors.blue),
                ),
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
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                    // Add your tabs here
                    tabs:
                        cardDetail?.card.front.map((e) {
                          return Tab(
                            icon: Icon(
                              ref
                                  .read(cardProvider(deck).notifier)
                                  .icons[e.type],
                            ),
                          );
                        }).toList() ??
                        [],
                  ).expanded(),
                  SizedBox(width: 50, height: 46),
                ],
              ),
            ),
            TabBarView(
              children:
                  cardDetail?.card.front.map((e) {
                    return Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  }).toList() ??
                  [],
            ).expanded(),
          ],
        ),
      ),
    );
  }

  // Widget _buildCardFace(
  //     WidgetRef ref,
  //     Color color
  //     ) {
  //   final loadingState = ref.watch(
  //     cardProvider(deck).select((value) => value.loadingState),
  //   );
  //   return Container(
  //     width: double.infinity,
  //     constraints: const BoxConstraints(minHeight: 200),
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.w600,
  //             color: color,
  //             letterSpacing: 1.2,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           loadingState == LoadingState.initial ? '' : content,
  //           style: const TextStyle(
  //             fontSize: 24,
  //             fontWeight: FontWeight.w500,
  //             height: 1.4,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

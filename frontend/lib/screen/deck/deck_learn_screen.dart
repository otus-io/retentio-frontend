import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';
import 'package:retentio/screen/deck/widgets/card_widget.dart';
import 'package:retentio/screen/deck/widgets/flash_card/flash_card.dart';

import '../../widgets/common_bottom_sheet.dart';
import '../decks/providers/create_deck_provider.dart';
import '../decks/providers/deck_provider.dart';
import '../decks/widgets/create_deck_widget.dart';

/// [intervalSec] is the review interval in seconds (same as [CardState.selectedInterval]).
String _formatReviewIntervalLabel(double intervalSec) {
  const secPerMinute = 60;
  const secPerHour = 60 * secPerMinute;
  const secPerDay = 24 * secPerHour;
  const secPerMonth = 30 * secPerDay;
  const secPerYear = 12 * secPerMonth;

  if (intervalSec < secPerMinute) {
    return '${intervalSec.ceil()}s';
  }
  if (intervalSec < secPerHour) {
    return '${(intervalSec / secPerMinute).ceil()}m';
  }
  if (intervalSec < secPerDay) {
    return '${(intervalSec / secPerHour).toStringAsFixed(1)}h';
  }
  if (intervalSec < secPerMonth) {
    return '${(intervalSec / secPerDay).toStringAsFixed(1)}d';
  }
  if (intervalSec < secPerYear) {
    return '${(intervalSec / secPerMonth).toStringAsFixed(1)}mo';
  }
  return '${(intervalSec / secPerYear).toStringAsFixed(1)}y';
}

class DeckLearnScreen extends StatefulWidget {
  final Deck deck;

  const DeckLearnScreen({super.key, required this.deck});

  @override
  State<DeckLearnScreen> createState() => _DeckLearnScreenState();
}

class _DeckLearnScreenState extends State<DeckLearnScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
              actions: [
                PullDownButton(
                  routeTheme: PullDownMenuRouteTheme(
                    width: 200,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                  itemBuilder: (context) => [
                    // PullDownMenuItem(
                    //   title: 'Add Fact',
                    //   onTap: () {},
                    //   icon: LucideIcons.layersPlus,
                    // ),
                    PullDownMenuItem(
                      title: loc.editDeck,
                      onTap: () {
                        showCommonBottomSheet(
                          context: ref.context,
                          title: loc.editDeck,
                          initialChildSize: 0.5,
                          minChildSize: 0.5,
                          child: CreateDeckWidget(deck: widget.deck),
                        ).then((value) {
                          if (value != null && value.isNotEmpty) {
                            ref
                                .read(createDeckParamsProvider.notifier)
                                .update((state) => state.copyWith(name: value));
                          }
                        });
                      },
                      icon: LucideIcons.squarePen,
                    ),
                    PullDownMenuItem(
                      title: loc.deleteDeck,
                      onTap: () async {
                        await ref
                            .read(deckListProvider.notifier)
                            .deleteDeck(widget.deck);
                        if (ref.context.mounted) {
                          ref.context.pop();
                        }
                      },
                      icon: LucideIcons.delete,
                      iconColor: Colors.red,
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  buttonBuilder: (context, showMenu) => IconButton(
                    onPressed: showMenu,
                    icon: Icon(LucideIcons.ellipsisVertical),
                  ),
                ),
              ],
            ),
            body: _buildBody(theme, loc, ref),
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations loc, WidgetRef ref) {
    final deck = ref.watch(deckProvider);
    final cardState = ref.watch(cardProvider);
    if (cardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalCardsInSession =
        cardState.refreshedCardsCount ?? deck.stats.cardsCount;
    final cardsStudied = cardState.cardsStudied;
    final cardDetail = cardState.cardDetail;

    // No next due card from API (empty deck, or nothing scheduled) — avoid FlashCard.
    if (cardDetail == null) {
      if (totalCardsInSession == 0) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.circleQuestionMark,
                size: 80,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                loc.noCardsInThisDeck,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circleCheckBig,
              size: 80,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              loc.allCaughtUp,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cardProvider.notifier).reviewAgain();
              },
              child: Text(loc.reviewAgain),
            ),
          ],
        ),
      );
    }

    final bool isCompleted = totalCardsInSession == cardsStudied;
    if (totalCardsInSession == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circleQuestionMark,
              size: 80,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              loc.noCardsInThisDeck,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circleCheckBig,
              size: 80,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              loc.allCaughtUp,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cardProvider.notifier).reviewAgain();
              },
              child: Text(loc.reviewAgain),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        // 进度指示器
        LinearProgressIndicator(
          value: totalCardsInSession > 0
              ? cardsStudied / totalCardsInSession
              : 0.0,
          minHeight: 4,
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[300],
        ),

        // 卡片内容区域
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlashCard(
                height: context.width - 48 - 46,
                flashCardController: ref
                    .read(cardProvider.notifier)
                    .flashCardController,
                width: double.infinity,
                frontWidget: CardWidget(isFront: true),
                backWidget: CardWidget(isFront: false),
                onFlip: (value) {
                  ref.read(cardProvider.notifier).toggleShowAnswer();
                },
              ),
              SizedBox(height: 100),
            ],
          ),
        ),

        // 底部按钮区域
        Positioned(
          bottom: 0,
          width: ref.context.width,
          child: _buildBottomButtons(theme, loc),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(ThemeData theme, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final showAnswer = ref.watch(
              cardProvider.select((value) => value.showAnswer),
            );

            return Column(
              spacing: 8,
              children: [
                if (!showAnswer)
                  Consumer(
                    builder: (context, ref, child) {
                      final interval = ref.watch(
                        cardProvider.select((value) => value.selectedInterval),
                      );
                      final intervalRange = ref.read(
                        cardProvider.notifier.select(
                          (value) => value.intervalRange,
                        ),
                      );
                      final label = _formatReviewIntervalLabel(interval);
                      return Row(
                        children: [
                          Text(
                            loc.hard,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: interval.ceilToDouble(),
                            min: intervalRange.first,
                            max: intervalRange.last,
                            divisions: 100,
                            label: label,
                            onChanged: (double value) {
                              ref
                                  .read(cardProvider.notifier)
                                  .selectInterval(value);
                            },
                          ).expanded(),
                          Text(
                            loc.easy,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final isFond = ref
                        .read(cardProvider.notifier)
                        .flashCardController
                        .isFront;
                    if (isFond) {
                      ref
                          .read(cardProvider.notifier)
                          .flashCardController
                          .flip();
                    } else {
                      await ref.read(cardProvider.notifier).nextCard();
                      ref
                          .read(cardProvider.notifier)
                          .flashCardController
                          .showFront();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      if (showAnswer) const Icon(Icons.visibility),
                      Text(
                        showAnswer ? loc.showAnswer : loc.review,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

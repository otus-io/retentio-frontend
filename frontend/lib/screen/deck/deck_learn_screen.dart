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

import '../../mixins/delayed_init_mixin.dart';
import '../../widgets/common_bottom_sheet.dart';
import '../learn/providers/create_deck_provider.dart';
import '../learn/providers/deck_provider.dart';
import '../learn/widgets/create_deck_widget.dart';

class DeckLearnScreen extends ConsumerStatefulWidget {
  final Deck deck;

  const DeckLearnScreen({super.key, required this.deck});

  @override
  ConsumerState<DeckLearnScreen> createState() => _DeckLearnScreenState();
}

class _DeckLearnScreenState extends ConsumerState<DeckLearnScreen>
    with DelayedInitMixin {
  @override
  void afterFirstLayout() {
    ref
        .read(createDeckParamsProvider.notifier)
        .update(
          (state) => CreateDeckParams(
            fields: widget.deck.fields,
            name: widget.deck.name,
            templates: widget.deck.templates,
            rate: widget.deck.rate,
            type: DeckCardType.edit,
            id: widget.deck.id,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                title: 'Edit Deck',
                onTap: () {
                  showCommonBottomSheet(
                    context: ref.context,
                    title: 'Edit Deck',
                    child: CreateDeckWidget(),
                  ).then((value) {
                    if (value.isNotEmpty) {
                      ref
                          .read(createDeckParamsProvider.notifier)
                          .update((state) => state.copyWith(name: value));
                    }
                  });
                },
                icon: LucideIcons.squarePen,
              ),
              if (ref
                      .watch(cardProvider(widget.deck).notifier)
                      .totalCardsInSession >
                  0)
                PullDownMenuItem(
                  title: 'Hide Card',
                  onTap: () async {
                    await ref
                        .read(cardProvider(widget.deck).notifier)
                        .nextCard(isHide: true);
                    ref
                        .read(cardProvider(widget.deck).notifier)
                        .flashCardController
                        .showFront();
                    ref.read(cardProvider(widget.deck).notifier).showAnswer();
                  },
                  icon: LucideIcons.eyeOff,
                ),
              PullDownMenuItem(
                title: 'Delete Deck',
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
      body: _buildBody(theme, loc),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations loc) {
    final isLoading = ref.watch(
      cardProvider(widget.deck).select((value) => value.isLoading),
    );
    final card = ref.watch(
      cardProvider(widget.deck).select((value) => value.cardDetail),
    );
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // if (_error != null) {
    //   return Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         const Icon(Icons.error_outline, size: 64, color: Colors.grey),
    //         const SizedBox(height: 16),
    //         Text(
    //           'Error: $_error',
    //           style: const TextStyle(color: Colors.grey),
    //           textAlign: TextAlign.center,
    //         ),
    //         const SizedBox(height: 16),
    //         ElevatedButton(onPressed: _loadNextCard, child: Text(loc.retry)),
    //       ],
    //     ),
    //   );
    // }

    final totalCardsInSession = ref
        .read(cardProvider(widget.deck).notifier)
        .totalCardsInSession;
    final cardsStudied = ref.watch(
      cardProvider(widget.deck).select((value) => value.cardsStudied),
    );
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
              'No cards in this deck',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    if (card == null) {
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
              onPressed: () => Navigator.pop(context),
              child: Text(loc.backToDeck),
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
                    .read(cardProvider(widget.deck).notifier)
                    .flashCardController,
                width: double.infinity,
                frontWidget: CardWidget(deck: widget.deck, isFront: true),
                backWidget: CardWidget(deck: widget.deck, isFront: false),
                onFlip: (value) {
                  ref
                      .read(cardProvider(widget.deck).notifier)
                      .toggleShowAnswer();
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
              cardProvider(widget.deck).select((value) => value.showAnswer),
            );

            return Column(
              spacing: 8,
              children: [
                if (!showAnswer)
                  Consumer(
                    builder: (context, ref, child) {
                      final interval = ref.watch(
                        cardProvider(
                          widget.deck,
                        ).select((value) => value.selectedInterval),
                      );
                      final scope = ref.read(
                        cardProvider(
                          widget.deck,
                        ).notifier.select((value) => value.scope),
                      );
                      var label = '${(interval).ceil() ~/ 60}m';

                      ///超过 60m 就可以显示 1h （小时）， 超过 24 小时显示 1d
                      if (interval > 24 * 60 * 60) {
                        label = '${(interval ~/ 60 / 60 / 24).ceil()}d';
                      } else if (interval > 60 * 60) {
                        label = '${(interval ~/ 60 / 60).toStringAsFixed(1)}h';
                      }
                      return Row(
                        children: [
                          Text(
                            'Hard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: interval.ceilToDouble(),
                            min: scope.first.roundToDouble(),
                            max: scope.last.roundToDouble(),
                            divisions: 100,
                            label: label,
                            onChanged: (double value) {
                              ref
                                  .read(cardProvider(widget.deck).notifier)
                                  .selectInterval(value);
                            },
                          ).expanded(),
                          Text(
                            'Easy',
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
                        .read(cardProvider(widget.deck).notifier)
                        .flashCardController
                        .isFront;
                    if (isFond) {
                      ref
                          .read(cardProvider(widget.deck).notifier)
                          .flashCardController
                          .flip();
                    } else {
                      await ref
                          .read(cardProvider(widget.deck).notifier)
                          .nextCard();
                      ref
                          .read(cardProvider(widget.deck).notifier)
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

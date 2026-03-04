import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:wordupx/extensions/context_extension.dart';
import 'package:wordupx/extensions/widget_extension.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/models/deck.dart';
import 'package:wordupx/screen/deck/providers/card_provider.dart';
import 'package:wordupx/screen/deck/providers/edit_fact_provider.dart';
import 'package:wordupx/screen/deck/widgets/card_widget.dart';
import 'package:wordupx/screen/deck/widgets/edit_fact_widget.dart';
import 'package:wordupx/screen/deck/widgets/flash_card/flash_card.dart';

import '../../widgets/common_bottom_sheet.dart';

class DeckLearnScreen extends ConsumerStatefulWidget {
  final Deck deck;

  const DeckLearnScreen({super.key, required this.deck});

  @override
  ConsumerState<DeckLearnScreen> createState() => _DeckLearnScreenState();
}

class _DeckLearnScreenState extends ConsumerState<DeckLearnScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          PullDownButton(
            routeTheme: PullDownMenuRouteTheme(
              width: 150,
              backgroundColor: theme.colorScheme.surface,
            ),
            itemBuilder: (context) => [
              PullDownMenuItem(
                title: 'Edit Fact',
                onTap: () {
                  showCommonBottomSheet(
                    context: context,
                    initialChildSize: 0.4,
                    minChildSize: 0.3,
                    maxChildSize: 0.5,
                    title: 'Edit Fact',
                    child: ProviderScope(
                      overrides: [deckProvider.overrideWithValue(widget.deck)],
                      child: EditFactWidget(deck: widget.deck),
                    ),
                  );
                },
                icon: LucideIcons.pencil,
              ),
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
    final isLoading = ref.read(
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

    if (card == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
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
                    return Row(
                      children: [
                        Text(
                          'Easy',
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
                          label: '${(interval).ceil() ~/ 60}m',
                          onChanged: (double value) {
                            ref
                                .read(cardProvider(widget.deck).notifier)
                                .selectInterval(value);
                          },
                        ).expanded(),
                        Text(
                          'Hard',
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

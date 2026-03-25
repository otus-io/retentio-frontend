import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/card_widgets/card_flip.dart';

class DeckViewBody extends ConsumerWidget {
  const DeckViewBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final deck = ref.watch(deckProvider);
    final cardState = ref.watch(cardProvider);

    if (cardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalCardsInSession =
        cardState.refreshedCardsCount ?? deck.stats.cardsCount;
    final cardsStudied = cardState.cardsStudied;
    final cardDetail = cardState.cardDetail;

    if (cardDetail == null) {
      if (totalCardsInSession == 0) {
        return _DeckStudyMessageColumn(
          icon: LucideIcons.circleQuestionMark,
          title: loc.noCardsInThisDeck,
          theme: theme,
        );
      }
      return _CaughtUpColumn(
        loc: loc,
        theme: theme,
        onReviewAgain: () {
          ref.read(cardProvider.notifier).reviewAgain();
        },
      );
    }

    if (totalCardsInSession == 0) {
      return _DeckStudyMessageColumn(
        icon: LucideIcons.circleQuestionMark,
        title: loc.noCardsInThisDeck,
        theme: theme,
      );
    }

    final isCompleted = totalCardsInSession == cardsStudied;
    if (isCompleted) {
      return _CaughtUpColumn(
        loc: loc,
        theme: theme,
        onReviewAgain: () {
          ref.read(cardProvider.notifier).reviewAgain();
        },
      );
    }

    return Stack(
      children: [
        LinearProgressIndicator(
          value: totalCardsInSession > 0
              ? cardsStudied / totalCardsInSession
              : 0.0,
          minHeight: 4,
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[300],
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardFlip(
                height: context.width - 48 - 46,
                flipCardController: ref
                    .read(cardProvider.notifier)
                    .flipCardController,
                width: double.infinity,
                frontWidget: CardSideContent(isFront: true),
                backWidget: CardSideContent(isFront: false),
                onFlip: (value) {
                  ref.read(cardProvider.notifier).toggleShowAnswer();
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          width: context.width,
          child: const DeckViewIntervalSliderControls(),
        ),
      ],
    );
  }
}

class _CaughtUpColumn extends StatelessWidget {
  const _CaughtUpColumn({
    required this.loc,
    required this.theme,
    required this.onReviewAgain,
  });

  final AppLocalizations loc;
  final ThemeData theme;
  final VoidCallback onReviewAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.circleCheckBig, size: 80, color: theme.primaryColor),
          const SizedBox(height: 24),
          Text(
            loc.allCaughtUp,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onReviewAgain,
            child: Text(loc.reviewAgain),
          ),
        ],
      ),
    );
  }
}

class _DeckStudyMessageColumn extends StatelessWidget {
  const _DeckStudyMessageColumn({
    required this.icon,
    required this.title,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.primaryColor),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

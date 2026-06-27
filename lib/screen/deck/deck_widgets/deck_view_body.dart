import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/deck_study/deck_study.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/card_widgets/card_flip.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';

const _kMessageIconSize = 84.0;
const _kMessageTitleTopSpacing = 24.0;
const _kMessageButtonTopSpacing = 16.0;

class DeckViewBody extends StatelessWidget {
  const DeckViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final flipController = context
        .read<DeckStudyFlipCardControllerCubit>()
        .state;
    final deck = context.select(
      (DeckStudyContextCubit cubit) => cubit.state.deck,
    );

    return BlocListener<DeckStudyBloc, DeckStudyState>(
      listenWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.cardDetail?.card.id != current.cardDetail?.card.id,
      listener: (context, state) {
        if (state.isLoading || state.cardDetail == null) {
          flipController.showFront();
        }
      },
      child: BlocBuilder<DeckStudyBloc, DeckStudyState>(
        builder: (context, state) {
          Widget buildTagFilterBar() {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.deckTags.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tag = state.deckTags[index];
                    final selected = state.activeTagId == tag.id;
                    return ChoiceChip(
                      label: Text(tag.name),
                      selected: selected,
                      onSelected: (_) {
                        requestDeckStudyTagFilterChanged(
                          context,
                          selected ? null : tag.id,
                        );
                      },
                    );
                  },
                ),
              ),
            );
          }

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalCardsInSession =
              state.refreshedCardsCount ?? deck.stats.cardsCount;
          final cardsStudied = state.cardsStudied;
          final cardDetail = state.cardDetail;

          if (cardDetail == null) {
            final messageBody = totalCardsInSession == 0
                ? _DeckStudyMessageColumn(
                    icon: LucideIcons.circleQuestionMark,
                    title: loc.noCardsInThisDeck,
                    theme: theme,
                  )
                : _CaughtUpColumn(
                    loc: loc,
                    theme: theme,
                    onReviewAgain: () {
                      requestDeckStudyReviewAgain(context);
                    },
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.deckTags.isNotEmpty) buildTagFilterBar(),
                Expanded(child: messageBody),
              ],
            );
          }

          final isCompleted = totalCardsInSession == cardsStudied;
          if (isCompleted) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.deckTags.isNotEmpty) buildTagFilterBar(),
                Expanded(
                  child: _CaughtUpColumn(
                    loc: loc,
                    theme: theme,
                    onReviewAgain: () {
                      requestDeckStudyReviewAgain(context);
                    },
                  ),
                ),
              ],
            );
          }

          final currentCardNumber = totalCardsInSession > 0
              ? (cardsStudied + 1).clamp(1, totalCardsInSession)
              : cardsStudied + 1;
          final currentProgress = totalCardsInSession > 0
              ? currentCardNumber / totalCardsInSession
              : 0.0;
          final progressPercent = currentProgress * 100;
          final progressPercentLabel = progressPercent >= 1
              ? '${progressPercent.toStringAsFixed(0)}%'
              : progressPercent > 0
              ? '${progressPercent.toStringAsFixed(2)}%'
              : '${progressPercent.toStringAsFixed(0)}%';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.deckTags.isNotEmpty) buildTagFilterBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  spacing: 6,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$currentCardNumber / $totalCardsInSession',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          progressPercentLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    LinearProgressIndicator(
                      value: currentProgress,
                      minHeight: 4,
                      borderRadius: AppThemeTokens.borderRadiusPill,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      backgroundColor: scheme.outline.withValues(alpha: 0.18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final idealCardHeight = screenWidth - 48 - 46;
                    final maxCardHeight = (constraints.maxHeight - 150).clamp(
                      180.0,
                      idealCardHeight,
                    );
                    final cardHeight = maxCardHeight.toDouble();
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CardFlip(
                                height: cardHeight,
                                width: double.infinity,
                                flipCardController: flipController,
                                frontWidget: const CardSideContent(
                                  isFront: true,
                                ),
                                backWidget: const CardSideContent(
                                  isFront: false,
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          width: screenWidth,
                          child: const DeckViewIntervalSliderControls(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
          Icon(
            LucideIcons.circleCheckBig,
            size: _kMessageIconSize,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: _kMessageTitleTopSpacing),
          Text(
            loc.allCaughtUp,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _kMessageButtonTopSpacing),
          AppButton(
            label: loc.reviewAgain,
            onPressed: onReviewAgain,
            variant: AppButtonVariant.primary,
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
          Icon(icon, size: _kMessageIconSize, color: theme.colorScheme.primary),
          const SizedBox(height: _kMessageTitleTopSpacing),
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

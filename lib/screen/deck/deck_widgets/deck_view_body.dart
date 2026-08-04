import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/deck_study/deck_study.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/card_widgets/card_flip.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_study_tag_filter_bar.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/decks/deck_text_styles.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

const _kMessageIconSize = 84.0;
const _kMessageTitleTopSpacing = 24.0;
const _kMessageButtonTopSpacing = 16.0;

String? _tagNameFor(DeckStudyState state) {
  final activeTagId = state.activeTagId;
  if (activeTagId == null) {
    return null;
  }
  for (final tag in state.deckTags) {
    if (tag.id == activeTagId) {
      return tag.name;
    }
  }
  return null;
}

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
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        AppToast.error(
          context,
          ApiErrorMessages.resolve(state.errorMessage, loc),
        );
      },
      child: BlocListener<DeckStudyBloc, DeckStudyState>(
        listenWhen: (previous, current) =>
            (current.isLoading && !previous.isLoading) ||
            previous.cardDetail?.card.id != current.cardDetail?.card.id,
        listener: (context, state) {
          flipController.showFront();
        },
        child: BlocBuilder<DeckStudyBloc, DeckStudyState>(
          builder: (context, state) {
            Widget buildTagFilterBar() {
              return DeckStudyTagFilterBar(
                tags: state.deckTags,
                activeTagId: state.activeTagId,
                onTagSelected: (tagId) {
                  requestDeckStudyTagFilterChanged(context, tagId);
                },
              );
            }

            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalCardsInSession =
                state.refreshedCardsCount ?? deck.stats.cardsCount;
            final cardsStudied = state.cardsStudied;
            final cardDetail = state.cardDetail;
            final liveDue = state.refreshedDueCardsCount ?? deck.stats.dueCards;
            final dueTarget = state.sessionDueTarget ?? liveDue;
            // Live cleared toward the frozen target. When new cards fall due and
            // liveDue jumps above dueTarget, liveCleared collapses to 0 — keep
            // session review count as a floor so the bar does not reset.
            final liveCleared = liveDue < dueTarget ? dueTarget - liveDue : 0;
            final reviewFloor = cardsStudied < dueTarget
                ? cardsStudied
                : dueTarget;
            final clearedDue = liveCleared > reviewFloor
                ? liveCleared
                : reviewFloor;
            final dueProgress = dueTarget <= 0
                ? 1.0
                : (clearedDue / dueTarget).clamp(0.0, 1.0);
            final dueProgressPercent = dueProgress * 100;
            final dueProgressPercentLabel = dueProgressPercent >= 1
                ? '${dueProgressPercent.toStringAsFixed(0)}%'
                : dueProgressPercent > 0
                ? '${dueProgressPercent.toStringAsFixed(2)}%'
                : '${dueProgressPercent.toStringAsFixed(0)}%';

            if (cardDetail == null) {
              final messageBody = state.activeTagId != null
                  ? _TagFilterEmptyColumn(
                      loc: loc,
                      theme: theme,
                      tagName: _tagNameFor(state),
                      onClearFilter: () {
                        requestDeckStudyTagFilterChanged(context, null);
                      },
                    )
                  : totalCardsInSession == 0
                  ? _DeckStudyMessageColumn(
                      icon: LucideIcons.circleQuestionMark,
                      title: loc.noCardsInThisDeck,
                      theme: theme,
                    )
                  : _DeckStudyMessageColumn(
                      icon: LucideIcons.circleQuestionMark,
                      title: loc.noCardsInThisDeck,
                      theme: theme,
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.deckTags.isNotEmpty) buildTagFilterBar(),
                  Expanded(child: messageBody),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.deckTags.isNotEmpty) buildTagFilterBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: AppThemeTokens.borderRadiusPill,
                        child: LinearProgressIndicator(
                          value: dueProgress,
                          minHeight: 6,
                          backgroundColor: scheme.outline.withValues(
                            alpha: 0.28,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.todaysDue,
                            style: DeckTextStyles.progressLabel(theme),
                          ),
                          Text(
                            '$clearedDue/$dueTarget ($dueProgressPercentLabel)',
                            style: DeckTextStyles.progressValue(theme),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final maxCardHeight = (constraints.maxHeight * 0.62)
                          .clamp(180.0, constraints.maxHeight - 150.0);
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
      ),
    );
  }
}

class _TagFilterEmptyColumn extends StatelessWidget {
  const _TagFilterEmptyColumn({
    required this.loc,
    required this.theme,
    required this.tagName,
    required this.onClearFilter,
  });

  final AppLocalizations loc;
  final ThemeData theme;
  final String? tagName;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final title = tagName == null
        ? loc.noCardsForTagFilter
        : loc.noCardsForTagFilterNamed(tagName!);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.tags,
            size: _kMessageIconSize,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: _kMessageTitleTopSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _kMessageButtonTopSpacing),
          AppButton(
            label: loc.clearTagFilter,
            onPressed: onClearFilter,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/features/deck_study/deck_study.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/formatters/review_interval_label.dart';
import 'package:retentio/widgets/app_button.dart';

// Backward-compatible provider bridge for existing tests that override
// study bloc/state via Riverpod.
final deckStudyBlocProvider = Provider.autoDispose<DeckStudyBloc>(
  (ref) => throw UnimplementedError(
    'deckStudyBlocProvider is test-only compatibility bridge. '
    'Use BlocProvider<DeckStudyBloc> at runtime.',
  ),
);

final deckStudyStateProvider = StreamProvider.autoDispose<DeckStudyState>((
  ref,
) async* {
  final bloc = ref.watch(deckStudyBlocProvider);
  yield bloc.state;
  yield* bloc.stream;
});

DeckStudyBloc _readDeckStudyBloc(BuildContext context) {
  try {
    return context.read<DeckStudyBloc>();
  } catch (_) {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(deckStudyBlocProvider);
  }
}

void requestDeckStudyIntervalSelected(
  BuildContext context,
  double intervalSeconds,
) {
  _readDeckStudyBloc(context).add(DeckStudyIntervalSelected(intervalSeconds));
}

void requestDeckStudyNextCard(
  BuildContext context, {
  bool hideCurrentCard = false,
}) {
  _readDeckStudyBloc(
    context,
  ).add(DeckStudyNextCardRequested(hideCurrentCard: hideCurrentCard));
}

void requestDeckStudyDeleteCurrentCard(BuildContext context) {
  _readDeckStudyBloc(context).add(const DeckStudyDeleteCurrentCardRequested());
}

void requestDeckStudyReloadCurrentCard(BuildContext context) {
  _readDeckStudyBloc(context).add(const DeckStudyReloadRequested());
}

void requestDeckStudyReviewAgain(BuildContext context) {
  _readDeckStudyBloc(context).add(const DeckStudyReviewAgainRequested());
}

void requestDeckStudyTagFilterChanged(BuildContext context, String? tagId) {
  _readDeckStudyBloc(context).add(DeckStudyTagFilterChanged(tagId));
}

class DeckViewIntervalSliderControls extends StatelessWidget {
  const DeckViewIntervalSliderControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    dynamic flipController;
    try {
      flipController = context.read<DeckStudyFlipCardControllerCubit>().state;
    } catch (_) {
      flipController = null;
    }

    return BlocBuilder<DeckStudyBloc, DeckStudyState>(
      builder: (context, state) {
        Widget buildPanel(bool isFront) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                spacing: 8,
                children: [
                  if (!isFront)
                    Row(
                      children: [
                        Text(
                          loc.hard,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: scheme.primary,
                            inactiveTrackColor: scheme.outline.withValues(
                              alpha: 0.25,
                            ),
                            thumbColor: scheme.primary,
                            overlayColor: scheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            value: state.selectedInterval.clamp(
                              state.minInterval,
                              state.maxInterval,
                            ),
                            min: state.minInterval,
                            max: state.maxInterval,
                            divisions: 100,
                            label: formatReviewIntervalLabel(
                              state.selectedInterval,
                            ),
                            onChanged: (double value) {
                              requestDeckStudyIntervalSelected(context, value);
                            },
                          ),
                        ).expanded(),
                        Text(
                          loc.easy,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  AppButton(
                    label: isFront ? loc.showAnswer : loc.next,
                    onPressed: () {
                      if (isFront) {
                        flipController?.showBack();
                      } else {
                        requestDeckStudyNextCard(context);
                        flipController?.showFront();
                      }
                    },
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.md,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          );
        }

        if (flipController == null) {
          return buildPanel(true);
        }

        return AnimatedBuilder(
          animation: flipController,
          builder: (context, _) {
            return buildPanel(flipController.isFront);
          },
        );
      },
    );
  }
}

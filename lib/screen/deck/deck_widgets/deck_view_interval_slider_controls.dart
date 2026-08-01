import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/features/deck_study/deck_study.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/card_widgets/card_flip_controller.dart';
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

/// Preferred size for the interval-label thumb at [textScaleFactor].
@visibleForTesting
Size intervalLabelThumbPreferredSize(double textScaleFactor) {
  return _IntervalLabelThumbShape(
    textScaleFactor: textScaleFactor,
  ).getPreferredSize(true, true);
}

/// Thumb with always-visible interval pill; preferred size includes the pill
/// so users can drag from the label as well as the circle.
class _IntervalLabelThumbShape extends SliderComponentShape {
  const _IntervalLabelThumbShape({this.textScaleFactor = 1.0});

  final double textScaleFactor;

  static const double thumbRadius = 7;
  static const double labelHeight = 22;
  static const double labelGap = 6;
  static const double labelHorizontalPadding = 8;

  /// Matches paint pill height when approximating from text scale alone.
  static double pillHeightForScale(double textScaleFactor) {
    // paint uses max(labelHeight, labelPainter.height + 6). Approximate the
    // unscaled label text height; labelHeight itself is the pill floor.
    const baseTextHeight = 12.0;
    return math.max(labelHeight, baseTextHeight * textScaleFactor + 6.0);
  }

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    // Hit target is centered on the track thumb; include scaled pill height so
    // large accessibility text stays inside the slider drag/overflow region.
    final halfHeight =
        thumbRadius + labelGap + pillHeightForScale(textScaleFactor);
    return Size(64, halfHeight * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final thumbColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;

    if (labelPainter != null) {
      _paintLabelPill(
        canvas: canvas,
        center: center,
        labelPainter: labelPainter,
        thumbColor: thumbColor,
        sizeWithOverflow: sizeWithOverflow,
      );
    }

    canvas.drawCircle(center, thumbRadius, Paint()..color = thumbColor);
  }

  void _paintLabelPill({
    required Canvas canvas,
    required Offset center,
    required TextPainter labelPainter,
    required Color thumbColor,
    required Size sizeWithOverflow,
  }) {
    labelPainter.layout();
    final pillW = math.max(
      36.0,
      labelPainter.width + labelHorizontalPadding * 2,
    );
    final pillH = math.max(labelHeight, labelPainter.height + 6.0);
    var pillCenter = Offset(
      center.dx,
      center.dy - thumbRadius - labelGap - pillH / 2,
    );

    // Keep the pill inside the allocated overflow bounds (same idea as Material
    // value indicators) so large text is not clipped horizontally.
    if (!sizeWithOverflow.isEmpty && pillW < sizeWithOverflow.width) {
      const edgePadding = 8.0;
      final left = pillCenter.dx - pillW / 2;
      final right = pillCenter.dx + pillW / 2;
      final shift = math.max(
        edgePadding - left,
        math.min(0.0, sizeWithOverflow.width - edgePadding - right),
      );
      pillCenter = Offset(pillCenter.dx + shift, pillCenter.dy);
    }

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pillCenter, width: pillW, height: pillH),
      const Radius.circular(11),
    );
    canvas.drawRRect(pillRect, Paint()..color = thumbColor);

    final tip = Path()
      ..moveTo(center.dx - 5, pillCenter.dy + pillH / 2 - 0.5)
      ..lineTo(center.dx + 5, pillCenter.dy + pillH / 2 - 0.5)
      ..lineTo(center.dx, pillCenter.dy + pillH / 2 + 5)
      ..close();
    canvas.drawPath(tip, Paint()..color = thumbColor);

    labelPainter.paint(
      canvas,
      Offset(
        pillCenter.dx - labelPainter.width / 2,
        pillCenter.dy - labelPainter.height / 2,
      ),
    );
  }
}

class DeckViewIntervalSliderControls extends StatelessWidget {
  const DeckViewIntervalSliderControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    CardFlipController? flipController;
    try {
      flipController = context.read<DeckStudyFlipCardControllerCubit>().state;
    } catch (_) {
      flipController = null;
    }

    return BlocBuilder<DeckStudyBloc, DeckStudyState>(
      builder: (context, state) {
        // Flutter Slider asserts min < max; study state can emit equal bounds
        // (e.g. empty session → 0/0).
        final minInterval = state.minInterval;
        final maxInterval = state.maxInterval > minInterval
            ? state.maxInterval
            : minInterval + 1;

        Widget buildPanel(bool isFront) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
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
                            thumbShape: _IntervalLabelThumbShape(
                              textScaleFactor: MediaQuery.textScalerOf(
                                context,
                              ).scale(1),
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 18,
                            ),
                            tickMarkShape: const RoundSliderTickMarkShape(
                              tickMarkRadius: 2.5,
                            ),
                            showValueIndicator: ShowValueIndicator.never,
                            activeTrackColor: scheme.primary,
                            inactiveTrackColor: scheme.outline.withValues(
                              alpha: 0.25,
                            ),
                            activeTickMarkColor: scheme.primary.withValues(
                              alpha: 0.55,
                            ),
                            inactiveTickMarkColor: scheme.outline.withValues(
                              alpha: 0.45,
                            ),
                            thumbColor: scheme.primary,
                            overlayColor: scheme.primary.withValues(alpha: 0.1),
                            valueIndicatorTextStyle: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onPrimary),
                          ),
                          child: Slider(
                            value: state.selectedInterval.clamp(
                              minInterval,
                              maxInterval,
                            ),
                            min: minInterval,
                            max: maxInterval,
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
          // Fallback when flip controller is unavailable: keep study flow usable
          // by showing the "back" controls directly (interval slider + next).
          return buildPanel(false);
        }

        final controller = flipController;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return buildPanel(controller.isFront);
          },
        );
      },
    );
  }
}

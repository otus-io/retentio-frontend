import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/formatters/review_interval_label.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';

class DeckViewIntervalSliderControls extends ConsumerWidget {
  const DeckViewIntervalSliderControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final showAnswer = ref.watch(
      cardProvider.select((value) => value.showAnswer),
    );

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
        child: Column(
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
                  final label = formatReviewIntervalLabel(interval);
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
                          ref.read(cardProvider.notifier).selectInterval(value);
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
                    .flipCardController
                    .isFront;
                if (isFond) {
                  ref.read(cardProvider.notifier).flipCardController.flip();
                } else {
                  await ref.read(cardProvider.notifier).nextCard();
                  ref
                      .read(cardProvider.notifier)
                      .flipCardController
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
        ),
      ),
    );
  }
}

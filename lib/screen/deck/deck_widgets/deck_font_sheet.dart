import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/screen/deck/providers/deck_card_typography.dart';
import 'package:retentio/theme/theme_tokens.dart';

/// Japanese sample for live preview (wiki-style ruby).
const String kDeckFontPreviewJapanese = '[[例|れい]]の[[漢字|かんじ]]';

class DeckFontSheet extends HookConsumerWidget {
  const DeckFontSheet({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editingFront = useState(true);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final previewColor = theme.colorScheme.onSurface;
    final sides = ref.watch(deckSidesTypographyProvider(deckId));
    final notifier = ref.read(deckSidesTypographyProvider(deckId).notifier);
    final typography = sides.forSide(editingFront.value);

    final baseStyle = typography.baseTextStyle(previewColor);
    final rubyStyle = typography.rubyTextStyle(previewColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(value: true, label: Text(loc.deckFontTabFront)),
            ButtonSegment<bool>(value: false, label: Text(loc.deckFontTabBack)),
          ],
          selected: {editingFront.value},
          onSelectionChanged: (Set<bool> next) {
            editingFront.value = next.single;
          },
        ),
        const SizedBox(height: 16),
        Text(
          loc.deckFontPreviewCaption,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.6),
            ),
            borderRadius: AppThemeTokens.borderRadiusSm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Center(
              child: wikiRubyWrappedText(
                text: kDeckFontPreviewJapanese,
                baseStyle: baseStyle,
                rubyStyle: rubyStyle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(loc.deckFontMainSizeLabel, style: theme.textTheme.labelLarge),
        Slider(
          value: typography.baseFontSize,
          min: DeckCardTypography.minBase,
          max: DeckCardTypography.maxBase,
          divisions: 40,
          label: typography.baseFontSize.toStringAsFixed(0),
          onChanged: (v) => notifier.setBaseFontSize(editingFront.value, v),
          onChangeEnd: (_) => notifier.persistCurrent(),
        ),
        const SizedBox(height: 8),
        Text(loc.deckFontRubySizeLabel, style: theme.textTheme.labelLarge),
        Slider(
          value: typography.rubyFontSize,
          min: DeckCardTypography.minRuby,
          max: DeckCardTypography.maxRuby,
          divisions: 44,
          label: typography.rubyFontSize.toStringAsFixed(0),
          onChanged: (v) => notifier.setRubyFontSize(editingFront.value, v),
          onChangeEnd: (_) => notifier.persistCurrent(),
        ),
      ],
    );
  }
}

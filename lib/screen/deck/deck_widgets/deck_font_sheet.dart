import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/screen/deck/providers/deck_card_typography.dart';

/// Japanese sample for live preview (wiki-style ruby).
const String kDeckFontPreviewJapanese = '[[例|れい]]の[[漢字|かんじ]]';

class DeckFontSheet extends ConsumerStatefulWidget {
  const DeckFontSheet({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckFontSheet> createState() => _DeckFontSheetState();
}

class _DeckFontSheetState extends ConsumerState<DeckFontSheet> {
  bool _editingFront = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final previewColor = theme.colorScheme.onSurface;
    final sides = ref.watch(deckSidesTypographyProvider(widget.deckId));
    final notifier = ref.read(
      deckSidesTypographyProvider(widget.deckId).notifier,
    );
    final typography = sides.forSide(_editingFront);

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
          selected: {_editingFront},
          onSelectionChanged: (Set<bool> next) {
            setState(() => _editingFront = next.single);
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(12),
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
          onChanged: (v) => notifier.setBaseFontSize(_editingFront, v),
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
          onChanged: (v) => notifier.setRubyFontSize(_editingFront, v),
          onChangeEnd: (_) => notifier.persistCurrent(),
        ),
      ],
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/constants.dart';

import '../../../models/card.dart';
import '../../../models/transcript_sync.dart';
import '../card_widgets/card_audio.dart';
import '../card_widgets/card_image.dart';
import '../card_widgets/card_text.dart';
import '../card_widgets/card_transcript_text.dart';
import '../card_widgets/card_video.dart';
import '../providers/audio_player.dart';
import '../providers/transcript_sync_provider.dart';

class FactContent extends ConsumerWidget {
  const FactContent({super.key, required this.items, required this.color});

  final List<Item> items;
  final Color color;

  static String _fallbackTextFromItems(List<Item> textItems) {
    final parts = <String>[];
    for (final t in textItems) {
      final v = t.value.trim();
      if (v.isNotEmpty) parts.add(v);
    }
    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final textLikeItems = <Item>[];
    final audioItems = <Item>[];
    final jsonItems = <Item>[];
    final mediaItems = <Item>[];

    for (final e in items) {
      switch (e.type) {
        case 'audio':
          audioItems.add(e);
        case 'json':
          jsonItems.add(e);
        case 'image':
        case 'video':
          mediaItems.add(e);
        default:
          textLikeItems.add(e);
      }
    }

    final singleAudioScope = audioItems.length == 1;
    final transcriptUrl = singleAudioScope && jsonItems.length == 1
        ? jsonItems.first.value
        : null;

    final showCombined = textLikeItems.isNotEmpty || audioItems.isNotEmpty;

    final scrollChildren = <Widget>[];

    if (showCombined) {
      scrollChildren.add(
        _CombinedTextPane(
          textItems: textLikeItems,
          color: color,
          transcriptUrl: transcriptUrl,
        ),
      );
    }

    for (final e in mediaItems) {
      scrollChildren.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: switch (e.type) {
            'video' => CardVideo(url: e.value),
            'image' => Center(child: CardImage(url: e.value)),
            String() => const SizedBox.shrink(),
          },
        ),
      );
    }

    if (scrollChildren.isEmpty) {
      scrollChildren.add(CardText(text: '', color: color));
    }

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: scrollChildren,
            ),
          ),
        ),
        if (showCombined && audioItems.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(width: 0.3, color: color)),
            ),
            padding: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: _CombinedAudioTrailing(
                audioItems: audioItems,
                color: color,
                singleAudioScope: singleAudioScope,
                transcriptUrl: transcriptUrl,
              ),
            ),
          ),
      ],
    );

    if (singleAudioScope) {
      body = ProviderScope(
        overrides: [audioUrlProvider.overrideWithValue(audioItems.first.value)],
        child: body,
      );
    }

    return body;
  }
}

class _CombinedAudioTrailing extends ConsumerWidget {
  const _CombinedAudioTrailing({
    required this.audioItems,
    required this.color,
    required this.singleAudioScope,
    this.transcriptUrl,
  });

  final List<Item> audioItems;
  final Color color;
  final bool singleAudioScope;
  final String? transcriptUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TranscriptSync? sync;
    final url = transcriptUrl;
    if (url != null && url.isNotEmpty) {
      final av = ref.watch(transcriptSyncProvider(url));
      sync = switch (av) {
        AsyncData(:final value) => value,
        _ => null,
      };
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final a in audioItems)
          CardAudio(
            audioUrl: a.value,
            color: color,
            compact: true,
            useExternalScope: singleAudioScope,
            transcriptForWordNav: sync,
            transcriptJsonUrl: url,
          ),
      ],
    );
  }
}

/// Text (and optional transcript) for the combined text block in [FactContent].
class _CombinedTextPane extends StatelessWidget {
  const _CombinedTextPane({
    required this.textItems,
    required this.color,
    this.transcriptUrl,
  });

  final List<Item> textItems;
  final Color color;
  final String? transcriptUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (transcriptUrl != null && transcriptUrl!.isNotEmpty)
          CardTranscriptText(
            transcriptUrl: transcriptUrl!,
            fallbackText: FactContent._fallbackTextFromItems(textItems),
            color: color,
          )
        else
          for (final t in textItems)
            if (t.value.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CardText(text: t.value, color: color, scrollable: false),
              ),
      ],
    );
  }
}

// --- Card review summary (multi-field list); used by [CardContentContainer]. ---

/// One row in the deck card summary: field label + compact value / media.
class FactSummaryFieldRow extends StatelessWidget {
  const FactSummaryFieldRow({
    super.key,
    required this.card,
    required this.color,
    required this.rowHeight,
  });

  final CardSlot card;
  final Color color;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    const gap = 12.0;
    return SizedBox(
      width: double.infinity,
      height: rowHeight,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final innerW = constraints.maxWidth;
            final wField = ((innerW - gap) * 3.0 / 9.0).clamp(
              0.0,
              double.infinity,
            );
            final wValue = (innerW - gap - wField).clamp(0.0, double.infinity);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: wField,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      card.field,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: kFontSizeMedium,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: wValue,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _FactSummaryFieldValue(card: card, color: color),
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

class _FactSummaryFieldValue extends StatelessWidget {
  const _FactSummaryFieldValue({required this.card, required this.color});

  final CardSlot card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _FactFieldSummaryData.fromItems(card.items);
    final mainText = summary.mainText;
    final badges = summary.compactBadges;
    final hasMedia = summary.hasStructuredMedia;

    if (mainText == null || mainText.isEmpty) {
      if (hasMedia) {
        return _FactMediaSummaryLines(
          summary: summary,
          color: color,
          alignEnd: true,
        );
      }
      if (badges.isNotEmpty) {
        return _FactInlineMediaIcons(
          badges: badges,
          color: color,
          alignEnd: true,
        );
      }
      return Text(
        '-',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
          fontSize: kFontSizeMedium,
          fontWeight: FontWeight.normal,
        ),
      );
    }

    final mainWidget = Text(
      mainText,
      textAlign: TextAlign.right,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: kFontSizeMedium,
        fontWeight: FontWeight.normal,
        height: 1,
      ),
    );

    if (!hasMedia && badges.isEmpty) {
      return mainWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        mainWidget,
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 8,
          runSpacing: 6,
          children: [
            ..._buildFactSummaryMediaTiles(context, summary, color),
            for (final b in badges) _FactMediaIconText(badge: b, color: color),
          ],
        ),
      ],
    );
  }
}

void _showFactSummaryImagePreviewDialog(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.65,
                maxWidth: MediaQuery.sizeOf(ctx).width * 0.88,
              ),
              child: Consumer(
                builder: (context, ref, _) => CardImage(url: url),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

List<Widget> _buildFactSummaryMediaTiles(
  BuildContext context,
  _FactFieldSummaryData summary,
  Color color,
) {
  final iconColor = color.withValues(alpha: 0.85);
  final out = <Widget>[];
  for (final url in summary.audioUrls) {
    if (url.trim().isEmpty) continue;
    out.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProviderScope(
              overrides: [audioUrlProvider.overrideWithValue(url)],
              child: CardAudio(
                audioUrl: url,
                color: color,
                compact: true,
                useExternalScope: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  for (final url in summary.imageUrls) {
    out.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showFactSummaryImagePreviewDialog(context, url),
          child: Icon(Icons.image_outlined, size: 20, color: iconColor),
        ),
      ),
    );
  }
  for (final _ in summary.videoUrls) {
    out.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Icon(Icons.videocam_outlined, size: 20, color: iconColor),
        ),
      ),
    );
  }
  return out;
}

class _FactMediaSummaryLines extends StatelessWidget {
  const _FactMediaSummaryLines({
    required this.summary,
    required this.color,
    required this.alignEnd,
  });

  final _FactFieldSummaryData summary;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tiles = _buildFactSummaryMediaTiles(context, summary, color);
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 6,
      runSpacing: 6,
      children: tiles,
    );
  }
}

/// Bottom bar [+N] control to open hidden fields for the card summary.
class FactSummaryHiddenFieldsButton extends StatelessWidget {
  const FactSummaryHiddenFieldsButton({
    super.key,
    required this.count,
    required this.color,
    required this.onPressed,
  });

  final int count;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 0.3, color: color)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color.withValues(alpha: 0.88),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.unfold_more_rounded,
                size: 20,
                color: color.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 6),
              Text(
                '+$count',
                style: TextStyle(
                  fontSize: kFontSizeMedium,
                  fontWeight: FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showFactSummaryHiddenFieldsDialog(
  BuildContext context, {
  required List<CardSlot> hiddenCards,
  required Color color,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenSize.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: _FactSummaryHiddenFieldsSheet(
            cards: hiddenCards,
            color: color,
          ),
        ),
      ),
    ),
  );
}

class _FactSummaryHiddenFieldsSheet extends StatelessWidget {
  const _FactSummaryHiddenFieldsSheet({
    required this.cards,
    required this.color,
  });

  final List<CardSlot> cards;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            _FactSummaryHiddenFieldSection(card: cards[index], color: color),
            if (index < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FactSummaryHiddenFieldSection extends StatelessWidget {
  const _FactSummaryHiddenFieldSection({
    required this.card,
    required this.color,
  });

  final CardSlot card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final summary = _FactFieldSummaryData.fromItems(card.items);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56, maxWidth: 92),
            child: Text(
              card.field,
              style: TextStyle(
                color: color,
                fontSize: kFontSizeMedium,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: kFontSizeMedium,
                fontWeight: FontWeight.normal,
                height: 1.35,
              ),
            ),
          ),
          Expanded(
            child: _FactSummaryHiddenFieldContent(
              summary: summary,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactSummaryHiddenFieldContent extends StatelessWidget {
  const _FactSummaryHiddenFieldContent({
    required this.summary,
    required this.color,
  });

  final _FactFieldSummaryData summary;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = summary.mainText;
    final hasMedia = summary.hasStructuredMedia;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (primary != null && primary.isNotEmpty) ...[
          Text(
            primary,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: kFontSizeMedium,
              fontWeight: FontWeight.normal,
              height: 1.45,
            ),
            softWrap: true,
          ),
          if (hasMedia || summary.compactBadges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 8,
              runSpacing: 6,
              children: [
                ..._buildFactSummaryMediaTiles(context, summary, color),
                for (final b in summary.compactBadges)
                  _FactMediaIconText(badge: b, color: color),
              ],
            ),
          ],
        ] else ...[
          if (hasMedia || summary.compactBadges.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 8,
              runSpacing: 6,
              children: [
                ..._buildFactSummaryMediaTiles(context, summary, color),
                for (final b in summary.compactBadges)
                  _FactMediaIconText(badge: b, color: color),
              ],
            )
          else
            Text(
              '-',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                fontSize: kFontSizeMedium,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
        if (summary.metaEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: summary.metaEntries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                        fontSize: kFontSizeMedium,
                        fontWeight: FontWeight.normal,
                        height: 1.3,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _FactInlineMediaIcons extends StatelessWidget {
  const _FactInlineMediaIcons({
    required this.badges,
    required this.color,
    this.alignEnd = false,
  });

  final List<String> badges;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final b in badges) _FactMediaIconText(badge: b, color: color),
      ],
    );
  }
}

class _FactMediaIconText extends StatelessWidget {
  const _FactMediaIconText({required this.badge, required this.color});

  final String badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _iconForBadge(badge),
          size: 20,
          color: color.withValues(alpha: 0.78),
        ),
        const SizedBox(width: 4),
        Text(
          badge,
          style: TextStyle(
            color: color.withValues(alpha: 0.82),
            fontSize: kFontSizeMedium,
            fontWeight: FontWeight.normal,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  IconData _iconForBadge(String badge) {
    final normalized = badge.toLowerCase();
    if (normalized.contains('audio')) {
      return Icons.play_circle_outline_rounded;
    }
    if (normalized.contains('image')) {
      return Icons.image_outlined;
    }
    if (normalized.contains('video')) {
      return Icons.videocam_outlined;
    }
    return Icons.info_outline_rounded;
  }
}

class _FactFieldSummaryData {
  const _FactFieldSummaryData({
    required this.mainText,
    required this.compactBadges,
    required this.metaEntries,
    required this.audioUrls,
    required this.imageUrls,
    required this.videoUrls,
  });

  final String? mainText;
  final List<String> compactBadges;
  final List<MapEntry<String, String>> metaEntries;
  final List<String> audioUrls;
  final List<String> imageUrls;
  final List<String> videoUrls;

  bool get hasStructuredMedia =>
      audioUrls.isNotEmpty || imageUrls.isNotEmpty || videoUrls.isNotEmpty;

  factory _FactFieldSummaryData.fromItems(List<Item> items) {
    final textValues = <String>[];
    final badges = <String>[];
    final metaEntries = <MapEntry<String, String>>[];
    final audioUrls = <String>[];
    final imageUrls = <String>[];
    final videoUrls = <String>[];

    for (final item in items) {
      final value = item.value.trim();
      if (value.isEmpty) continue;

      switch (item.type) {
        case 'text':
          textValues.add(value);
        case 'audio':
          audioUrls.add(value);
        case 'image':
          imageUrls.add(value);
        case 'video':
          videoUrls.add(value);
        case 'json':
          final parsedEntries = _parseMetaEntries(value);
          if (parsedEntries.isNotEmpty) {
            metaEntries.addAll(parsedEntries);
          }
          badges.add('Meta');
        default:
          textValues.add(value);
      }
    }

    final mainText = textValues.isEmpty ? null : textValues.join('  ');
    return _FactFieldSummaryData(
      mainText: mainText,
      compactBadges: badges.toSet().toList(growable: false),
      metaEntries: metaEntries.take(6).toList(growable: false),
      audioUrls: List<String>.unmodifiable(audioUrls),
      imageUrls: List<String>.unmodifiable(imageUrls),
      videoUrls: List<String>.unmodifiable(videoUrls),
    );
  }

  static List<MapEntry<String, String>> _parseMetaEntries(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];

      final entries = <MapEntry<String, String>>[];
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        final value = _stringifyMetaValue(entry.value);
        if (key.isEmpty || value.isEmpty) continue;
        entries.add(MapEntry(_prettifyMetaKey(key), value));
      }
      return entries;
    } catch (_) {
      return const [];
    }
  }

  static String _stringifyMetaValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return '$value';
    if (value is List) {
      return value
          .map(_stringifyMetaValue)
          .where((item) => item.isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      final parts = value.entries
          .map(
            (entry) =>
                '${_prettifyMetaKey(entry.key.toString())}: ${_stringifyMetaValue(entry.value)}',
          )
          .where((item) => !item.endsWith(': '))
          .toList(growable: false);
      return parts.join(' · ');
    }
    return value.toString().trim();
  }

  static String _prettifyMetaKey(String key) {
    final normalized = key.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return key;
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

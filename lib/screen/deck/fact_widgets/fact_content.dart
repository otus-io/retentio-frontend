import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/widget_extension.dart';

import '../../../models/card.dart';
import '../../../models/transcript_sync.dart';
import '../../../widgets/buttons_tab_bar.dart';
import '../card_widgets/card_audio.dart';
import '../card_widgets/card_image.dart';
import '../card_widgets/card_text.dart';
import '../card_widgets/card_transcript_text.dart';
import '../card_widgets/card_video.dart';
import '../providers/audio_player.dart';
import '../providers/transcript_sync_provider.dart';

class FactContent extends ConsumerWidget {
  const FactContent({
    super.key,
    required this.items,
    required this.color,
    this.typographyDeckId,
    this.typographyIsFront = true,
  });

  final List<Item> items;
  final Color color;
  final String? typographyDeckId;
  final bool typographyIsFront;

  static IconData _tabIconForMedia(Item e) => switch (e.type) {
    'video' => LucideIcons.video,
    'image' => LucideIcons.image,
    String() => LucideIcons.fileText,
  };

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
    final mediaTabs = <Item>[];

    for (final e in items) {
      switch (e.type) {
        case 'audio':
          audioItems.add(e);
        case 'json':
          jsonItems.add(e);
        case 'image':
        case 'video':
          mediaTabs.add(e);
        default:
          textLikeItems.add(e);
      }
    }

    final singleAudioScope = audioItems.length == 1;
    final transcriptUrl = singleAudioScope && jsonItems.length == 1
        ? jsonItems.first.value
        : null;

    final showCombinedTab = textLikeItems.isNotEmpty || audioItems.isNotEmpty;

    final tabPages = <Widget>[];
    final tabWidgets = <Tab>[];

    if (showCombinedTab) {
      tabPages.add(
        _CombinedTextPane(
          textItems: textLikeItems,
          color: color,
          transcriptUrl: transcriptUrl,
          typographyDeckId: typographyDeckId,
          typographyIsFront: typographyIsFront,
        ),
      );
      final combinedTrailing = <Widget>[
        _CombinedAudioTrailing(
          audioItems: audioItems,
          color: color,
          singleAudioScope: singleAudioScope,
          transcriptUrl: transcriptUrl,
        ),
      ];
      tabWidgets.add(
        combinedTrailing.isEmpty
            ? const Tab(icon: Icon(LucideIcons.fileText))
            : Tab(
                icon: const Icon(LucideIcons.fileText),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: combinedTrailing,
                ),
              ),
      );
    }

    for (final e in mediaTabs) {
      tabPages.add(switch (e.type) {
        'video' => CardVideo(url: e.value),
        'image' => Center(child: CardImage(url: e.value)),
        String() => const SizedBox.shrink(),
      });
      tabWidgets.add(Tab(icon: Icon(_tabIconForMedia(e))));
    }

    if (tabPages.isEmpty) {
      tabPages.add(
        CardText(
          text: '',
          color: color,
          typographyDeckId: typographyDeckId,
          typographyIsFront: typographyIsFront,
        ),
      );
      tabWidgets.add(const Tab(icon: Icon(LucideIcons.fileText)));
    }

    Widget tree = DefaultTabController(
      key: const ValueKey('field_content_widget'),
      length: tabPages.length,
      child: Column(
        children: [
          TabBarView(children: tabPages).expanded(),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(width: 0.3, color: color)),
            ),
            child: Row(
              children: [
                ButtonsTabBar(
                  backgroundColor: Colors.transparent,
                  unselectedBackgroundColor: Colors.transparent,
                  borderWidth: 1,
                  radius: 10,
                  borderColor: Colors.transparent,
                  unselectedBorderColor: Colors.transparent,
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: tabWidgets,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (singleAudioScope) {
      tree = ProviderScope(
        overrides: [audioUrlProvider.overrideWithValue(audioItems.first.value)],
        child: tree,
      );
    }

    return tree;
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

/// Text for the combined field tab; audio controls live on the tab bar by the note icon.
class _CombinedTextPane extends StatelessWidget {
  const _CombinedTextPane({
    required this.textItems,
    required this.color,
    this.transcriptUrl,
    this.typographyDeckId,
    this.typographyIsFront = true,
  });

  final List<Item> textItems;
  final Color color;
  final String? transcriptUrl;
  final String? typographyDeckId;
  final bool typographyIsFront;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (transcriptUrl != null && transcriptUrl!.isNotEmpty)
                    CardTranscriptText(
                      transcriptUrl: transcriptUrl!,
                      fallbackText: FactContent._fallbackTextFromItems(
                        textItems,
                      ),
                      color: color,
                      typographyDeckId: typographyDeckId,
                      typographyIsFront: typographyIsFront,
                    )
                  else
                    for (final t in textItems)
                      if (t.value.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CardText(
                            text: t.value,
                            color: color,
                            scrollable: false,
                            typographyDeckId: typographyDeckId,
                            typographyIsFront: typographyIsFront,
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

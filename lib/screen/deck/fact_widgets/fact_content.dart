import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/widget_extension.dart';

import '../../../models/card.dart';
import '../../../widgets/buttons_tab_bar.dart';
import '../card_widgets/card_audio.dart';
import '../card_widgets/card_image.dart';
import '../card_widgets/card_text.dart';
import '../card_widgets/card_video.dart';

class FactContent extends ConsumerWidget {
  const FactContent({super.key, required this.items, required this.color});

  final List<Item> items;
  final Color color;

  static IconData _tabIconForMedia(Item e) => switch (e.type) {
    'video' => LucideIcons.video,
    'image' => LucideIcons.image,
    String() => LucideIcons.fileText,
  };

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final textLikeItems = <Item>[];
    final audioItems = <Item>[];
    final mediaTabs = <Item>[];

    for (final e in items) {
      switch (e.type) {
        case 'audio':
          audioItems.add(e);
        case 'image':
        case 'video':
          mediaTabs.add(e);
        default:
          textLikeItems.add(e);
      }
    }

    final showCombinedTab = textLikeItems.isNotEmpty || audioItems.isNotEmpty;

    final tabPages = <Widget>[];
    final tabWidgets = <Tab>[];

    if (showCombinedTab) {
      tabPages.add(_CombinedTextPane(textItems: textLikeItems, color: color));
      final combinedTrailing = <Widget>[
        for (final a in audioItems)
          CardAudio(audioUrl: a.value, color: color, compact: true),
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
      tabPages.add(CardText(text: '', color: color));
      tabWidgets.add(const Tab(icon: Icon(LucideIcons.fileText)));
    }

    return DefaultTabController(
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
  }
}

/// Text for the combined field tab; audio controls live on the tab bar by the note icon.
class _CombinedTextPane extends StatelessWidget {
  const _CombinedTextPane({required this.textItems, required this.color});

  final List<Item> textItems;
  final Color color;

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
                  for (final t in textItems)
                    if (t.value.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CardText(
                          text: t.value,
                          color: color,
                          scrollable: false,
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

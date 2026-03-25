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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      key: const ValueKey('field_content_widget'),
      length: items.length,
      child: Column(
        children: [
          TabBarView(
            children: items.map((e) {
              final type = e.type;
              return switch (type) {
                'audio' => CardAudio(audioUrl: e.value, color: color),
                'video' => CardVideo(url: e.value),
                'image' => Center(child: CardImage(url: e.value)),
                'text' => CardText(text: e.value, color: color),
                String() => Center(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: color,
                    ),
                  ),
                ),
              };
            }).toList(),
          ).expanded(),
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
                  tabs: items.map((e) {
                    return Tab(
                      icon: Icon(switch (e.type) {
                        'audio' => LucideIcons.audioLines,
                        'video' => LucideIcons.video,
                        'image' => LucideIcons.image,
                        _ => LucideIcons.fileText,
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/widget_extension.dart';

import '../../../models/card.dart';
import 'buttons_tabbar/buttons_tab_bar_widget.dart';
import 'card_audio_widget.dart';
import 'card_image_widget.dart';
import 'card_text_widget.dart';
import 'card_video_widget.dart';

class FieldContentWidget extends ConsumerWidget {
  const FieldContentWidget({
    super.key,
    required this.back,
    required this.color,
  });

  final CardSlot back;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      if (back.text?.isNotEmpty == true) {"text": back.text},
      if (back.image?.isNotEmpty == true) {"image": back.image},
      if (back.audio?.isNotEmpty == true) {"audio": back.audio},
      if (back.video?.isNotEmpty == true) {"video": back.video},
    ];
    return DefaultTabController(
      key: const ValueKey('field_content_widget'),
      length: items.length,
      child: Column(
        children: [
          TabBarView(
            children: items.map((e) {
              final type = e.keys.first;
              final value = e[type] ?? '';
              return switch (type) {
                'audio' => CardAudioWidget(audioUrl: value, color: color),
                'video' => CardVideoWidget(url: value),
                'image' => Center(child: CardImageWidget(url: value)),
                'text' => CardTextWidget(text: value, color: color),
                String() => Center(
                  child: Text(
                    value,
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
                  // Add your tabs here
                  tabs: items.map((e) {
                    final type = e.keys.first;
                    return Tab(
                      icon: Icon(switch (type) {
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

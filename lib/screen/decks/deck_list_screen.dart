import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/screen/decks/widgets/deck_screen_body.dart';

import '../../widgets/common_bottom_sheet.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.decks),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.squarePlus),
            onPressed: () {
              showCommonBottomSheet(
                context: context,
                title: loc.createDeck,
                fullScreen: true,
                child: DeckCreate(),
              );
            },
          ),
        ],
      ),
      body: const DeckScreenBody(),
    );
  }
}

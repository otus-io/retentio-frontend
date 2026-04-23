import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_add.dart';
import 'package:retentio/screen/decks/providers/deck_create.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

import 'deck_font_sheet.dart';

class DeckMenu extends ConsumerWidget {
  const DeckMenu({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PullDownButton(
      routeTheme: PullDownMenuRouteTheme(
        width: 200,
        backgroundColor: theme.colorScheme.surface,
      ),
      itemBuilder: (context) => [
        PullDownMenuItem(
          title: loc.font,
          onTap: () {
            showCommonBottomSheet<void>(
              context: ref.context,
              title: loc.deckFontSheetTitle,
              initialChildSize: 0.52,
              minChildSize: 0.35,
              maxChildSize: 0.85,
              child: DeckFontSheet(deckId: deck.id),
            );
          },
          icon: LucideIcons.type,
        ),
        PullDownMenuItem(
          title: loc.addFact,
          onTap: () {
            showCommonBottomSheet<void>(
              context: ref.context,
              title: loc.addFact,
              initialChildSize: 0.88,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              child: FactAdd(
                deck: deck,
                onStudyQueueRefresh: () =>
                    ref.read(cardProvider.notifier).getCardDetail(),
              ),
            );
          },
          icon: LucideIcons.layersPlus,
        ),
        PullDownMenuItem(
          title: loc.editDeck,
          onTap: () {
            showCommonBottomSheet(
              context: ref.context,
              title: loc.editDeck,
              fullScreen: true,
              child: DeckCreate(deck: deck),
            ).then((value) {
              if (value != null && value.isNotEmpty) {
                ref
                    .read(createDeckParamsProvider.notifier)
                    .update((state) => state.copyWith(name: value));
              }
            });
          },
          icon: LucideIcons.squarePen,
        ),
        PullDownMenuItem(
          title: loc.deleteDeck,
          onTap: () async {
            await ref.read(deckListProvider.notifier).deleteDeck(deck);
            if (ref.context.mounted) {
              ref.context.pop();
            }
          },
          icon: LucideIcons.delete,
          iconColor: Colors.red,
          itemTheme: PullDownMenuItemTheme(
            textStyle: TextStyle(color: Colors.red),
          ),
        ),
      ],
      buttonBuilder: (context, showMenu) =>
          IconButton(onPressed: showMenu, icon: Icon(LucideIcons.ellipsis)),
    );
  }
}

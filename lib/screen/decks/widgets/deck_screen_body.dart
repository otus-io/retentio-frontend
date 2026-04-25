import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/widgets/common_refresher.dart';

import 'deck_list_card.dart';

class DeckScreenBody extends ConsumerWidget {
  const DeckScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final deckState = ref.watch(deckListProvider);
    final deckNotifier = ref.watch(deckListProvider.notifier);

    if (deckState.isLoading && deckState.decks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deckState.error != null && deckState.decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error: ${deckState.error}',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(deckListProvider.notifier).onRefresh();
              },
              child: Text(loc.retry),
            ),
          ],
        ),
      );
    }

    return CommonRefresher(
      controller: deckNotifier.refreshController,
      onRefresh: deckNotifier.onRefresh,
      isEmpty: deckState.decks.isEmpty,
      emptyView: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              loc.noDecksAvailable,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        itemCount: deckState.decks.length,
        itemBuilder: (context, index) {
          final deck = deckState.decks[index];
          return DeckListCard(deck: deck);
        },
      ),
    );
  }
}

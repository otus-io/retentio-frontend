import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/screen/learn/providers/deck_provider.dart';
import 'package:wordupx/models/deck.dart';
import 'package:wordupx/screen/deck/deck_detail_screen.dart';
import 'package:wordupx/screen/deck/deck_learn_screen.dart';
import 'package:wordupx/screen/learn/widgets/create_deck_widget.dart';
import 'package:wordupx/widgets/common_refresher.dart';

import '../../widgets/common_bottom_sheet.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final deckState = ref.watch(deckListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.learn),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.squarePlus),
            onPressed: () {
              showCommonBottomSheet(
                context: context,
                title: loc.createDeck,
                child: CreateDeckWidget(),
              );
            },
          ),
        ],
      ),
      body: _buildBody(deckState, loc),
    );
  }

  Widget _buildBody(DeckListState state, AppLocalizations loc) {
    if (state.isLoading && state.decks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
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
      controller: ref.read(deckListProvider.notifier).refreshController,
      onRefresh: ref.read(deckListProvider.notifier).onRefresh,
      isEmpty: state.decks.isEmpty,
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
        padding: const EdgeInsets.all(16),
        itemCount: state.decks.length,
        itemBuilder: (context, index) {
          final deck = state.decks[index];
          return _DeckCard(deck: deck);
        },
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Deck deck;

  const _DeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deck.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deck.totalCards} ${loc.cards}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.auto_awesome,
                  label: loc.newCards,
                  value: deck.stats.unseenCards.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.refresh,
                  label: loc.review,
                  value: deck.reviewCards.toString(),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.library_books,
                  label: loc.facts,
                  value: deck.stats.factsCount.toString(),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.progress,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${deck.learnedCards}/${deck.totalCards} (${deck.progress.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: deck.progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 三个操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeckDetailScreen(deck: deck),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(loc.viewCards),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeckLearnScreen(deck: deck),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school, size: 18),
                    label: Text(loc.learnButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showManageBottomSheet(context, deck, loc);
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(loc.manage),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showManageBottomSheet(
    BuildContext context,
    Deck deck,
    AppLocalizations loc,
  ) {
    showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      title: deck.name,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Deck'),
            subtitle: const Text('Modify deck settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 导航到编辑页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Cards'),
            subtitle: const Text('Add new cards to this deck'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 导航到添加卡片页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Deck',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete this deck'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 显示删除确认对话框
            },
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

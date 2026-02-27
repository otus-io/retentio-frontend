import 'package:flutter/material.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/models/deck.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  // 已移除卡片相关状态和加载逻辑

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.name)),
      body: Column(
        children: [
          // Deck 统计信息
          _buildDeckStats(theme, loc),
        ],
      ),
      // 开始学习按钮
      bottomNavigationBar: _buildStartLearningButton(theme, loc),
    );
  }

  Widget _buildDeckStats(ThemeData theme, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.style,
            label: loc.totalCards,
            value: widget.deck.totalCards.toString(),
            color: Colors.blue,
          ),
          _StatItem(
            icon: Icons.auto_awesome,
            label: loc.newCards,
            value: widget.deck.stats.unseenCards.toString(),
            color: Colors.green,
          ),
          _StatItem(
            icon: Icons.refresh,
            label: loc.dueCards,
            value: widget.deck.reviewCards.toString(),
            color: Colors.orange,
          ),
          _StatItem(
            icon: Icons.check_circle,
            label: loc.learned,
            value: widget.deck.learnedCards.toString(),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  // 已移除卡片列表相关方法

  // ...已移除未使用的 _buildSectionHeader 方法...

  Widget _buildStartLearningButton(ThemeData theme, AppLocalizations loc) {
    final hasCardsToStudy =
        widget.deck.stats.unseenCards > 0 || widget.deck.reviewCards > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: hasCardsToStudy
              ? () {
                  // TODO: 导航到学习页面
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.startLearningDeck(widget.deck.name)),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow, size: 28),
              const SizedBox(width: 8),
              Text(
                hasCardsToStudy ? loc.startLearning : loc.allCaughtUp,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

enum CardType { newCard, due, learned }

// ...已移除未使用的 _CardItem 类...

// ...已移除未使用的 _DetailRow 类...

import 'package:flutter/material.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/models/deck.dart';
import 'package:wordupx/models/card.dart' as model;
import 'package:wordupx/services/card_service.dart';

class DeckLearnScreen extends StatefulWidget {
  final Deck deck;

  const DeckLearnScreen({super.key, required this.deck});

  @override
  State<DeckLearnScreen> createState() => _DeckLearnScreenState();
}

class _DeckLearnScreenState extends State<DeckLearnScreen> {
  model.Card? _currentCard;
  bool _isLoading = true;
  String? _error;
  bool _showAnswer = false;
  int _cardsStudied = 0; // 已学习的卡片数
  int _totalCardsInSession = 0; // 本次学习会话的总卡片数

  @override
  void initState() {
    super.initState();
    // 初始化本次会话的总卡片数（新卡片 + 待复习卡片）
    _totalCardsInSession =
        widget.deck.stats.unseenCards + widget.deck.reviewCards;
    _loadNextCard();
  }

  Future<void> _loadNextCard() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showAnswer = false;
    });

    try {
      final card = await CardService.getNextDueCard(widget.deck.id);
      setState(() {
        _currentCard = card;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.name)),
      body: _buildBody(theme, loc),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations loc) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadNextCard, child: Text(loc.retry)),
          ],
        ),
      );
    }

    if (_currentCard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              loc.allCaughtUp,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.backToDeck),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 进度指示器
        LinearProgressIndicator(
          value: _totalCardsInSession > 0
              ? _cardsStudied / _totalCardsInSession
              : 0.0,
          minHeight: 4,
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[300],
        ),

        // 卡片内容区域
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 问题卡片
                  _buildCardFace(
                    context,
                    _currentCard!.front,
                    'Question',
                    Colors.blue,
                  ),

                  if (_showAnswer) ...[
                    const SizedBox(height: 24),
                    // 答案卡片
                    _buildCardFace(
                      context,
                      _currentCard!.back,
                      'Answer',
                      Colors.green,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 底部按钮区域
        _buildBottomButtons(theme, loc),
      ],
    );
  }

  Widget _buildCardFace(
    BuildContext context,
    String content,
    String label,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: !_showAnswer
            ? ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAnswer = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.visibility),
                    const SizedBox(width: 8),
                    Text(
                      loc.showAnswer,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 提交答案为"困难"
                        setState(() {
                          _cardsStudied++;
                        });
                        _loadNextCard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.close, size: 20),
                          const SizedBox(height: 4),
                          Text(loc.hard, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 提交答案为"一般"
                        setState(() {
                          _cardsStudied++;
                        });
                        _loadNextCard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.remove, size: 20),
                          const SizedBox(height: 4),
                          Text(loc.good, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 提交答案为"简单"
                        setState(() {
                          _cardsStudied++;
                        });
                        _loadNextCard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(height: 4),
                          Text(loc.easy, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

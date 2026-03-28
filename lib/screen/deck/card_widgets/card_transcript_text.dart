import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';
import 'package:retentio/screen/deck/providers/transcript_sync_provider.dart';
import 'package:retentio/screen/deck/card_widgets/card_text.dart';

/// Rich text aligned with [TranscriptSync] and current audio position; tap a word to seek.
///
/// When transcript content is taller than the viewport ([SingleChildScrollView] from the
/// parent overflows), the active word is kept in view via [Scrollable.ensureVisible].
class CardTranscriptText extends ConsumerStatefulWidget {
  const CardTranscriptText({
    super.key,
    required this.transcriptUrl,
    required this.fallbackText,
    required this.color,
  });

  final String transcriptUrl;
  final String fallbackText;
  final Color color;

  @override
  ConsumerState<CardTranscriptText> createState() => _CardTranscriptTextState();
}

class _CardTranscriptTextState extends ConsumerState<CardTranscriptText> {
  List<GlobalKey>? _wordKeys;
  String? _keysBoundUrl;
  int? _lastScrollScheduledForActive;

  /// Only follow the highlight when the parent scroll view actually scrolls (content
  /// extends beyond the card vertically).
  static const double _minScrollExtentForAutoScroll = 12;

  static TextStyle _baseStyle(Color color) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: color,
  );

  void _ensureWordKeys(String url, int n) {
    if (_keysBoundUrl == url && _wordKeys?.length == n) {
      return;
    }
    _wordKeys = List.generate(n, (_) => GlobalKey());
    _keysBoundUrl = url;
    _lastScrollScheduledForActive = null;
  }

  void _clearWordKeys() {
    _wordKeys = null;
    _keysBoundUrl = null;
    _lastScrollScheduledForActive = null;
  }

  void _scrollActiveIntoViewIfNeeded(int active) {
    if (active < 0) return;
    final keys = _wordKeys;
    if (keys == null || active >= keys.length) return;
    final ctx = keys[active].currentContext;
    if (ctx == null) return;

    final position = Scrollable.maybeOf(ctx)?.position;
    if (position == null) return;
    if (position.maxScrollExtent < _minScrollExtentForAutoScroll) {
      return;
    }

    Scrollable.ensureVisible(
      ctx,
      alignment: 0.2,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(CardTranscriptText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transcriptUrl != widget.transcriptUrl) {
      _clearWordKeys();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(transcriptSyncProvider(widget.transcriptUrl));
    return async.when(
      data: (sync) {
        if (sync == null || sync.words.isEmpty) {
          return CardText(
            text: widget.fallbackText,
            color: widget.color,
            scrollable: false,
          );
        }
        _ensureWordKeys(widget.transcriptUrl, sync.words.length);
        final positionMs = ref.watch(
          audioPlayerProvider.select((s) => s.positionMs),
        );
        final t = positionMs / 1000.0;
        final active = sync.wordIndexAt(t);

        if (active >= 0 && active != _lastScrollScheduledForActive) {
          _lastScrollScheduledForActive = active;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollActiveIntoViewIfNeeded(active);
          });
        }

        final base = _baseStyle(widget.color);
        final highlightBg = widget.color.withValues(alpha: 0.22);
        final keys = _wordKeys!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            runSpacing: 4,
            children: [
              for (var i = 0; i < sync.words.length; i++)
                KeyedSubtree(
                  key: keys[i],
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      final w = sync.words[i];
                      ref
                          .read(audioPlayerProvider.notifier)
                          .seekToMs((w.start * 1000).round());
                    },
                    child: Text(
                      sync.words[i].word,
                      style: base.copyWith(
                        backgroundColor: i == active ? highlightBg : null,
                        fontWeight: i == active
                            ? FontWeight.w800
                            : base.fontWeight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => CardText(
        text: widget.fallbackText.isNotEmpty ? widget.fallbackText : '…',
        color: widget.color,
        scrollable: false,
      ),
      error: (e, st) => CardText(
        text: widget.fallbackText,
        color: widget.color,
        scrollable: false,
      ),
    );
  }
}

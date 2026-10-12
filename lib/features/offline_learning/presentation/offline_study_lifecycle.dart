import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/utils/log.dart';

/// Flushes the offline review queue when mounted, when the app is paused or
/// resumed, when the network comes back, and when unmounted. With a [deckId],
/// also refreshes that deck's offline download when mounted.
class OfflineStudyLifecycle extends StatefulWidget {
  const OfflineStudyLifecycle({
    super.key,
    required this.session,
    this.deckId,
    required this.child,
    this.networkRestored,
  });

  final Future<OfflineLearningSession?> session;
  final String? deckId;
  final Widget child;

  /// Defaults to [onNetworkRestored].
  final Stream<void>? networkRestored;

  @override
  State<OfflineStudyLifecycle> createState() => _OfflineStudyLifecycleState();
}

class _OfflineStudyLifecycleState extends State<OfflineStudyLifecycle>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _networkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _networkSub = (widget.networkRestored ?? onNetworkRestored()).listen(
      (_) => _flush(),
      onError: (Object e) => logger.w('offline network watch: $e'),
    );
    _run((s) async {
      await s.sync.flush(force: true);
      if (widget.deckId case final deckId?) await s.downloader.download(deckId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _flush();
    }
  }

  void _flush() => _run((s) => s.sync.flush(force: true));

  void _run(Future<void> Function(OfflineLearningSession s) action) {
    final session = widget.session;
    unawaited(() async {
      try {
        final s = await session;
        if (s != null) await action(s);
      } catch (e) {
        logger.w('offline study sync: $e');
      }
    }());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_networkSub?.cancel());
    _flush();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

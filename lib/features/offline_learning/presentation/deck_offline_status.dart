import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/widgets/progress_ring.dart';

/// Offline state of a deck on the list: a progress ring while it downloads,
/// a check once it is study-ready, a retry alert when its download failed
/// before it ever became ready, nothing otherwise.
class DeckOfflineStatus extends StatefulWidget {
  const DeckOfflineStatus({
    super.key,
    required this.deckId,
    required this.availableOffline,
    this.downloader,
    this.onDownloaded,
  });

  final String deckId;
  final bool availableOffline;
  final OfflinePackageDownloader? downloader;

  /// Called when a download of [deckId] stops running.
  final VoidCallback? onDownloaded;

  @override
  State<DeckOfflineStatus> createState() => _DeckOfflineStatusState();
}

class _DeckOfflineStatusState extends State<DeckOfflineStatus> {
  ValueListenable<double?>? _progress;
  var _running = false;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(DeckOfflineStatus old) {
    super.didUpdateWidget(old);
    if (old.downloader != widget.downloader || old.deckId != widget.deckId) {
      _progress?.removeListener(_onProgress);
      _watch();
    }
  }

  void _watch() {
    _progress = widget.downloader?.progressOf(widget.deckId)
      ?..addListener(_onProgress);
    _running = _progress?.value != null;
  }

  void _onProgress() {
    final running = _progress!.value != null;
    if (_running && !running) widget.onDownloaded?.call();
    _running = running;
  }

  @override
  void dispose() {
    _progress?.removeListener(_onProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloader = widget.downloader;
    final failed = downloader?.failedOf(widget.deckId);
    return ListenableBuilder(
      listenable: Listenable.merge([?_progress, ?failed]),
      builder: (context, _) {
        final loc = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final Widget icon;
        if (_progress?.value case final value?) {
          icon = Tooltip(
            message: loc.offlineDownloading,
            child: ProgressRing(value: value, size: 16, showPercent: false),
          );
        } else if (widget.availableOffline) {
          icon = Tooltip(
            message: loc.deckAvailableOffline,
            child: Icon(
              LucideIcons.circleCheck,
              size: 16,
              color: scheme.secondary,
            ),
          );
        } else if (failed?.value ?? false) {
          icon = Tooltip(
            message: loc.offlineDownloadFailed,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(downloader!.download(widget.deckId)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.cloudAlert,
                  size: 16,
                  color: scheme.error,
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
        return Padding(padding: const EdgeInsets.only(left: 4), child: icon);
      },
    );
  }
}

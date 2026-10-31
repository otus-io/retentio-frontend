import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/widgets/progress_ring.dart';

/// Offline download state of a deck on the list: a progress ring while it
/// downloads, a tap-to-retry alert after its last download failed, nothing
/// otherwise (a downloaded deck needs no marker).
class DeckOfflineStatus extends StatelessWidget {
  const DeckOfflineStatus({super.key, required this.deckId, this.downloader});

  final String deckId;
  final OfflinePackageDownloader? downloader;

  @override
  Widget build(BuildContext context) {
    final downloader = this.downloader;
    if (downloader == null) return const SizedBox.shrink();
    final progress = downloader.progressOf(deckId);
    final failed = downloader.failedOf(deckId);
    return ListenableBuilder(
      listenable: Listenable.merge([progress, failed]),
      builder: (context, _) {
        final loc = AppLocalizations.of(context)!;
        final Widget icon;
        if (progress.value case final value?) {
          icon = Tooltip(
            message: loc.offlineDownloading,
            child: ProgressRing(value: value, size: 16, showPercent: false),
          );
        } else if (failed.value) {
          icon = Tooltip(
            message: loc.offlineDownloadFailed,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(downloader.download(deckId)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.cloudAlert,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
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

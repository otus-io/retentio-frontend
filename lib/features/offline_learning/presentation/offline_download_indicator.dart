import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/progress_ring.dart';

/// Offline download of [deckId]: a progress ring while it runs, a retry
/// button after it failed, nothing otherwise.
class OfflineDownloadIndicator extends StatelessWidget {
  const OfflineDownloadIndicator({
    super.key,
    required this.session,
    required this.deckId,
  });

  final Future<OfflineLearningSession?> session;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OfflineLearningSession?>(
      future: session,
      builder: (context, snapshot) {
        final downloader = snapshot.data?.downloader;
        if (downloader == null) return const SizedBox.shrink();
        final progress = downloader.progressOf(deckId);
        final failed = downloader.failedOf(deckId);
        return ListenableBuilder(
          listenable: Listenable.merge([progress, failed]),
          builder: (context, _) {
            final loc = AppLocalizations.of(context)!;
            if (progress.value case final value?) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppThemeTokens.spaceMd,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    ProgressRing(value: value, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.offlineDownloading,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!failed.value) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                onPressed: () => unawaited(downloader.download(deckId)),
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                leading: const Icon(LucideIcons.cloudAlert, size: 18),
                label: loc.offlineDownloadFailed,
              ),
            );
          },
        );
      },
    );
  }
}

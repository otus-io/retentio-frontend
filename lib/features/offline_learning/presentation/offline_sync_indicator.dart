import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/utils/log.dart';
import 'package:retentio/widgets/app_button.dart';

/// Upload queue status; tapping retries immediately. Hidden once synced.
class OfflineSyncIndicator extends StatelessWidget {
  const OfflineSyncIndicator({super.key, required this.session});

  final Future<OfflineLearningSession?> session;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OfflineLearningSession?>(
      future: session,
      builder: (context, snapshot) {
        final sync = snapshot.data?.sync;
        if (sync == null) return const SizedBox.shrink();
        return ValueListenableBuilder<OfflineSyncPhase>(
          valueListenable: sync.phase,
          builder: (context, phase, _) => _button(context, sync, phase),
        );
      },
    );
  }

  Widget _button(
    BuildContext context,
    OfflineSyncService sync,
    OfflineSyncPhase phase,
  ) {
    final loc = AppLocalizations.of(context)!;
    final (IconData icon, String label) = switch (phase) {
      OfflineSyncPhase.synced => (LucideIcons.cloudCheck, ''),
      OfflineSyncPhase.offline => (LucideIcons.wifiOff, loc.offlineSyncOffline),
      OfflineSyncPhase.pending => (
        LucideIcons.cloudUpload,
        loc.offlineSyncPending,
      ),
      OfflineSyncPhase.syncing => (
        LucideIcons.refreshCw,
        loc.offlineSyncSyncing,
      ),
      OfflineSyncPhase.failed => (
        LucideIcons.cloudAlert,
        loc.offlineSyncFailed,
      ),
      OfflineSyncPhase.needsLogin => (
        LucideIcons.logIn,
        loc.offlineSyncNeedsLogin,
      ),
    };
    if (phase == OfflineSyncPhase.synced) return const SizedBox.shrink();
    return Tooltip(
      message: loc.offlineSyncNow,
      child: AppButton(
        onPressed: phase == OfflineSyncPhase.syncing
            ? null
            : () => sync
                  .flush(retryNow: true)
                  .then<void>(
                    (_) {},
                    onError: (Object e) => logger.w('manual sync: $e'),
                  ),
        variant: AppButtonVariant.ghost,
        size: AppButtonSize.sm,
        leading: Icon(icon, size: 18),
        label: label,
      ),
    );
  }
}

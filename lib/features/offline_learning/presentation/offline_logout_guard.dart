import 'package:flutter/material.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/utils/log.dart';

enum _LogoutChoice { sync, keep, discard }

/// Settles the offline data of the logged-in account before logout. Returns
/// false when the user cancels. Offline data is deleted once nothing is left
/// to upload or the user discards it; kept reviews upload after re-login.
Future<bool> settleOfflineDataBeforeLogout(
  BuildContext context, {
  Future<OfflineLearningSession?>? session,
}) async {
  final OfflineLearningSession? s;
  try {
    s = await (session ?? OfflineLearningSessions.instance.current());
  } catch (e) {
    logger.w('offline logout: $e');
    return true;
  }
  if (s == null) return true;
  if ((await s.store.getOperations()).isEmpty) {
    await s.clear();
    return true;
  }
  if (!context.mounted) return false;
  final loc = AppLocalizations.of(context)!;
  var choice = await _ask(context, loc.logoutPendingSyncMessage, [
    (_LogoutChoice.sync, loc.logoutSyncAndLogout),
    (_LogoutChoice.keep, loc.logoutKeepAndLogout),
    (_LogoutChoice.discard, loc.logoutDiscardAndLogout),
  ]);
  if (choice == _LogoutChoice.sync) {
    await s.sync.flush(retryNow: true);
    if ((await s.store.getOperations()).isEmpty) {
      await s.clear();
      return true;
    }
    if (!context.mounted) return false;
    choice = await _ask(context, loc.logoutSyncIncomplete, [
      (_LogoutChoice.keep, loc.logoutKeepAndLogout),
      (_LogoutChoice.discard, loc.logoutDiscardAndLogout),
    ]);
  }
  if (choice == _LogoutChoice.discard) await s.clear();
  return choice != null;
}

Future<_LogoutChoice?> _ask(
  BuildContext context,
  String message,
  List<(_LogoutChoice, String)> options,
) {
  final loc = AppLocalizations.of(context)!;
  return showDialog<_LogoutChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(loc.logoutConfirmTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(loc.cancel),
        ),
        for (final (choice, label) in options)
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(choice),
            child: Text(label),
          ),
      ],
    ),
  );
}

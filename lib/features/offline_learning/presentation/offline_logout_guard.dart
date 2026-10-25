import 'dart:async';

import 'package:flutter/material.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/utils/log.dart';
import 'package:retentio/widgets/app_button.dart';

enum _LogoutChoice { sync, keep, discard }

/// Settles the offline data of the logged-in account before logout. Returns
/// false when the user cancels. Offline data is deleted once nothing is left
/// to upload or the user discards it; kept reviews upload after re-login.
/// Offline storage errors never block logout.
Future<bool> settleOfflineDataBeforeLogout(
  BuildContext context, {
  Future<OfflineLearningSession?>? session,
}) async {
  try {
    return await _settle(
      context,
      session ??
          OfflineLearningSessions.instance.current(fetchMissingUsername: false),
    );
  } catch (e) {
    logger.w('offline logout: $e');
    return true;
  }
}

Future<bool> _settle(
  BuildContext context,
  Future<OfflineLearningSession?> session,
) async {
  final s = await session;
  if (s == null) return true;
  if ((await s.store.getOperations()).isEmpty) {
    await s.clear();
    return true;
  }
  if (!context.mounted) return false;
  final loc = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context, rootNavigator: true);
  var choice = await _ask(context, loc.logoutPendingSyncMessage, [
    (_LogoutChoice.sync, loc.logoutSyncAndLogout),
    (_LogoutChoice.keep, loc.logoutKeepAndLogout),
    (_LogoutChoice.discard, loc.logoutDiscardAndLogout),
  ]);
  if (choice == _LogoutChoice.sync) {
    await _withProgress(
      navigator,
      loc.logoutSyncInProgress,
      () => s.sync.flush(retryNow: true),
    );
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
        AppButton(
          label: loc.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        for (final (choice, label) in options)
          AppButton(
            label: label,
            variant: switch (choice) {
              _LogoutChoice.sync => AppButtonVariant.primary,
              _LogoutChoice.keep => AppButtonVariant.secondary,
              _LogoutChoice.discard => AppButtonVariant.danger,
            },
            onPressed: () => Navigator.of(dialogContext).pop(choice),
          ),
      ],
    ),
  );
}

/// Runs [task] behind a progress dialog the user cannot dismiss.
Future<T> _withProgress<T>(
  NavigatorState navigator,
  String message,
  Future<T> Function() task,
) async {
  unawaited(
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppThemeTokens.spaceMd),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

import 'package:flutter/material.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

class ImportUpdatesSheet extends StatefulWidget {
  const ImportUpdatesSheet({
    super.key,
    required this.deckId,
    required this.onSynced,
  });

  final String deckId;
  final Future<void> Function() onSynced;

  @override
  State<ImportUpdatesSheet> createState() => _ImportUpdatesSheetState();
}

class _ImportUpdatesSheetState extends State<ImportUpdatesSheet> {
  DeckUpdatesResult? _updates;
  String? _error;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updates = await DeckCatalogService.of.getDeckUpdates(widget.deckId);
      if (!mounted) return;
      setState(() => _updates = updates);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = rawApiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _syncNow() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    try {
      await DeckCatalogService.of.syncDeck(widget.deckId);
      await widget.onSynced();
      await _loadUpdates();
      if (!mounted) return;
      AppToast.success(context, loc.deckSyncSuccess);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final updates = _updates;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ApiErrorMessages.resolve(_error!, loc),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(label: loc.discoveryRetry, onPressed: _loadUpdates),
        ],
      );
    }
    if (updates == null) {
      return AppButton(label: loc.discoveryRetry, onPressed: _loadUpdates);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.deckUpdatesVersion(updates.sourceVersion, updates.latestVersion),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Text(
          loc.deckUpdatesCounts(
            updates.addedFacts,
            updates.editedFacts,
            updates.removedFacts,
            updates.mediaChanges,
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        AppButton(
          label: updates.hasUpdates ? loc.deckSyncNow : loc.deckUpToDate,
          onPressed: updates.hasUpdates && !_syncing ? _syncNow : null,
          isLoading: _syncing,
          fullWidth: true,
        ),
      ],
    );
  }
}

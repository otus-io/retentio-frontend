import 'dart:math';

import 'package:retentio/features/offline_learning/data/datasources/study_sync_remote_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';

enum OfflineSyncStatus { skipped, synced, partial, needsLogin }

class OfflineSyncResult {
  const OfflineSyncResult(this.status, {this.sent = 0, this.failed = 0});

  final OfflineSyncStatus status;
  final int sent;
  final int failed;
}

enum _OpOutcome { sent, failed, removed, retry, unauthorized }

/// Uploads the local study queue FIFO, then refreshes server review counters.
class OfflineSyncService {
  OfflineSyncService({
    required OfflineLearningStore store,
    required StudySyncRemoteDataSource remote,
    required Future<bool> Function() isOnline,
    required int Function() nowSec,
    this.threshold = 100,
  }) : _store = store,
       _remote = remote,
       _isOnline = isOnline,
       _nowSec = nowSec;

  static const backoffSeconds = [30, 120, 600, 1800, 7200];

  final OfflineLearningStore _store;
  final StudySyncRemoteDataSource _remote;
  final Future<bool> Function() _isOnline;
  final int Function() _nowSec;
  final int threshold;

  Future<OfflineSyncResult>? _inFlight;

  Future<OfflineSyncResult> flush({bool force = false}) =>
      _inFlight ??= _flush(force).whenComplete(() => _inFlight = null);

  Future<OfflineSyncResult> _flush(bool force) async {
    if (!await _isOnline()) {
      return const OfflineSyncResult(OfflineSyncStatus.skipped);
    }
    final queue = await _store.getOperations();
    final pending = queue.where((op) => op.status == StudySyncStatus.pending);
    if (!force && pending.length < threshold) {
      return const OfflineSyncResult(OfflineSyncStatus.skipped);
    }
    final now = _nowSec();
    final due = pending.where((op) => op.nextRetryAt <= now).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final remaining = [...queue];
    final syncedDecks = <String>{};
    var sent = 0;
    var failed = 0;
    var retry = false;
    for (final op in due) {
      final outcome = await _process(op, remaining, now);
      if (outcome == _OpOutcome.unauthorized) {
        return OfflineSyncResult(
          OfflineSyncStatus.needsLogin,
          sent: sent,
          failed: failed,
        );
      }
      if (outcome == _OpOutcome.sent) {
        sent++;
        syncedDecks.add(op.deckId);
      }
      if (outcome == _OpOutcome.failed) failed++;
      if (outcome == _OpOutcome.retry) {
        retry = true;
        break;
      }
    }
    for (final deckId in syncedDecks) {
      await _refreshDeckCounts(deckId, now);
    }
    final status = retry || failed > 0
        ? OfflineSyncStatus.partial
        : OfflineSyncStatus.synced;
    return OfflineSyncResult(status, sent: sent, failed: failed);
  }

  Future<_OpOutcome> _process(
    StudySyncOperation op,
    List<StudySyncOperation> remaining,
    int now,
  ) async {
    final result = await _remote.patchCard(
      op.deckId,
      op.toPatchBody(),
      operationId: op.operationId,
    );
    if (result.isSuccess) {
      remaining.removeWhere((o) => o.operationId == op.operationId);
      await _confirmCard(op, result.data ?? const {}, remaining);
      await _store.removeOperation(op.operationId);
      return _OpOutcome.sent;
    }
    switch (result.httpStatus) {
      case 401:
        return _OpOutcome.unauthorized;
      case 400:
        await _store.updateOperation(
          op.copyWith(
            status: StudySyncStatus.failed,
            lastError: result.message ?? 'HTTP 400',
          ),
        );
        return _OpOutcome.failed;
      case 404:
        remaining.removeWhere((o) => o.operationId == op.operationId);
        await _store.removeOperation(op.operationId);
        await _store.deleteCard(op.deckId, op.cardId);
        return _OpOutcome.removed;
    }
    final attempts = op.attempts + 1;
    await _store.updateOperation(
      op.copyWith(
        attempts: attempts,
        nextRetryAt:
            now + backoffSeconds[min(attempts - 1, backoffSeconds.length - 1)],
        lastError:
            result.message ??
            (result.httpStatus == null
                ? 'network error'
                : 'HTTP ${result.httpStatus}'),
      ),
    );
    return _OpOutcome.retry;
  }

  Future<void> _confirmCard(
    StudySyncOperation op,
    Map<String, dynamic> data,
    List<StudySyncOperation> remaining,
  ) async {
    final cards = await _store.getCards(op.deckId);
    final card = cards.where((c) => c.id == op.cardId).firstOrNull;
    if (card == null) return;
    final stillQueued = remaining.any(
      (o) => o.deckId == op.deckId && o.cardId == op.cardId,
    );
    final OfflineCard confirmed;
    if (op.type == StudySyncType.review) {
      confirmed = card.copyWith(
        lastReview: (data['last_review'] as num?)?.toInt(),
        dueDate: (data['due_date'] as num?)?.toInt(),
        dirty: stillQueued,
      );
    } else {
      confirmed = card.copyWith(
        hidden: data['hidden_status'] as bool? ?? op.hidden,
        dirty: stillQueued,
      );
    }
    await _store.putCards([confirmed]);
  }

  Future<void> _refreshDeckCounts(String deckId, int now) async {
    final counts = await _remote.fetchDeckCounts(deckId);
    if (counts == null) return;
    final deck = await _store.getDeck(deckId);
    if (deck == null) return;
    await _store.putDeck(
      deck.copyWith(
        totalReviews: counts.totalReviews,
        totalReviewsToday: counts.totalReviewsToday,
        lastSyncedAt: now,
      ),
    );
  }
}

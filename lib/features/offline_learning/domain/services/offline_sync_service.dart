import 'dart:math';

import 'package:flutter/foundation.dart';
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

/// What the study UI shows about the upload queue.
enum OfflineSyncPhase { synced, offline, pending, syncing, failed, needsLogin }

enum _OpOutcome { sent, failed, removed, retry, offline, unauthorized }

/// Uploads the local study queue FIFO per card, then refreshes server review
/// counters.
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

  /// HTTP errors (not network errors) after which an op is marked failed.
  static const maxHttpAttempts = 8;

  final OfflineLearningStore _store;
  final StudySyncRemoteDataSource _remote;
  final Future<bool> Function() _isOnline;
  final int Function() _nowSec;
  final int threshold;

  final ValueNotifier<OfflineSyncPhase> phase = ValueNotifier(
    OfflineSyncPhase.synced,
  );

  Future<OfflineSyncResult>? _inFlight;
  var _inFlightForce = false;
  var _inFlightRetryNow = false;

  /// Uploads when [force] or the queue reached [threshold]. [retryNow] also
  /// sends operations still waiting out their backoff (manual retry). A
  /// stronger request arriving during a weaker flush runs after it.
  Future<OfflineSyncResult> flush({bool force = false, bool retryNow = false}) {
    final forced = force || retryNow;
    final running = _inFlight;
    if (running != null) {
      if ((!forced || _inFlightForce) && (!retryNow || _inFlightRetryNow)) {
        return running;
      }
      Future<OfflineSyncResult> again() =>
          flush(force: forced, retryNow: retryNow);
      return running.then((_) => again(), onError: (Object _) => again());
    }
    _inFlightForce = forced;
    _inFlightRetryNow = retryNow;
    return _inFlight = _flushAndReport(
      forced,
      retryNow,
    ).whenComplete(() => _inFlight = null);
  }

  Future<OfflineSyncResult> _flushAndReport(bool force, bool retryNow) async {
    try {
      final online = await _isOnline();
      final result = online
          ? await _flush(force, retryNow)
          : const OfflineSyncResult(OfflineSyncStatus.skipped);
      phase.value = await _phaseAfter(result, online);
      return result;
    } catch (_) {
      phase.value = OfflineSyncPhase.failed;
      rethrow;
    }
  }

  Future<OfflineSyncPhase> _phaseAfter(
    OfflineSyncResult result,
    bool online,
  ) async {
    if (result.status == OfflineSyncStatus.needsLogin) {
      return OfflineSyncPhase.needsLogin;
    }
    final queue = await _store.getOperations();
    if (queue.any((op) => op.status == StudySyncStatus.failed)) {
      return OfflineSyncPhase.failed;
    }
    if (!online) return OfflineSyncPhase.offline;
    return queue.isEmpty ? OfflineSyncPhase.synced : OfflineSyncPhase.pending;
  }

  Future<OfflineSyncResult> _flush(bool force, bool retryNow) async {
    final queue = await _store.getOperations();
    final pending = queue.where((op) => op.status == StudySyncStatus.pending);
    if (!force && pending.length < threshold) {
      return const OfflineSyncResult(OfflineSyncStatus.skipped);
    }
    final now = _nowSec();
    bool isDue(StudySyncOperation op) => retryNow || op.nextRetryAt <= now;
    final ordered = pending.toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (ordered.any(isDue)) phase.value = OfflineSyncPhase.syncing;
    // FIFO per card: an op in backoff or failing now holds back later ops of
    // the same card only.
    final heldCards = <(String, String)>{};
    final syncedDecks = <String>{};
    var sent = 0;
    var failed = 0;
    var retry = false;
    for (final op in ordered) {
      final card = (op.deckId, op.cardId);
      if (heldCards.contains(card)) continue;
      if (!isDue(op)) {
        heldCards.add(card);
        continue;
      }
      final outcome = await _process(op, now);
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
        heldCards.add(card);
      }
      if (outcome == _OpOutcome.offline) {
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

  Future<_OpOutcome> _process(StudySyncOperation op, int now) async {
    final result = await _remote.patchCard(
      op.deckId,
      op.toPatchBody(),
      operationId: op.operationId,
    );
    if (result.isSuccess) {
      await _confirmCard(op, result.data ?? const {});
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
      case 404 when result.isApiError:
        await _store.removeOperation(op.operationId);
        await _store.deleteCard(op.deckId, op.cardId);
        return _OpOutcome.removed;
    }
    final offline = result.httpStatus == null;
    final attempts = op.attempts + 1;
    final httpAttempts = op.httpAttempts + (offline ? 0 : 1);
    final lastError =
        result.message ??
        (offline ? 'network error' : 'HTTP ${result.httpStatus}');
    if (httpAttempts >= maxHttpAttempts) {
      await _store.updateOperation(
        op.copyWith(
          attempts: attempts,
          httpAttempts: httpAttempts,
          status: StudySyncStatus.failed,
          lastError: lastError,
        ),
      );
      return _OpOutcome.failed;
    }
    await _store.updateOperation(
      op.copyWith(
        attempts: attempts,
        httpAttempts: httpAttempts,
        nextRetryAt:
            now + backoffSeconds[min(attempts - 1, backoffSeconds.length - 1)],
        lastError: lastError,
      ),
    );
    return offline ? _OpOutcome.offline : _OpOutcome.retry;
  }

  Future<void> _confirmCard(
    StudySyncOperation op,
    Map<String, dynamic> data,
  ) async {
    final cards = await _store.getCards(op.deckId);
    final card = cards.where((c) => c.id == op.cardId).firstOrNull;
    if (card == null) return;
    // Newer local changes to this card are still queued (possibly added
    // during this flush); keep them.
    final newer = (await _store.getOperations()).any(
      (o) =>
          o.operationId != op.operationId &&
          o.deckId == op.deckId &&
          o.cardId == op.cardId,
    );
    if (newer) return;
    final OfflineCard confirmed;
    if (op.type == StudySyncType.review) {
      confirmed = card.copyWith(
        lastReview: (data['last_review'] as num?)?.toInt(),
        dueDate: (data['due_date'] as num?)?.toInt(),
        dirty: false,
      );
    } else {
      confirmed = card.copyWith(
        hidden: data['hidden_status'] as bool? ?? op.hidden,
        dirty: false,
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

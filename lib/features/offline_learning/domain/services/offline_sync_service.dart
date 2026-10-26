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

  /// Proxy errors that can follow a request the backend already applied.
  static const _gatewayStatuses = {502, 503, 504};

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
  var _halts = 0;

  /// Decks whose server counters failed to load after an upload.
  final Set<String> _staleCountDecks = {};

  /// Uploads when [force] or the queue reached [threshold]. [retryNow] also
  /// sends operations still waiting out their backoff (manual retry). A
  /// stronger request arriving during a weaker flush runs after it.
  Future<OfflineSyncResult> flush({bool force = false, bool retryNow = false}) {
    if (_halts > 0) {
      return Future.value(const OfflineSyncResult(OfflineSyncStatus.skipped));
    }
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

  /// Stops uploading after the op being sent, waits for the running flush,
  /// then runs [action] before any new flush can start. Used before deleting
  /// queued ops, which a running flush would otherwise write back.
  Future<T> whilePaused<T>(Future<T> Function() action) async {
    _halts++;
    try {
      for (var running = _inFlight; running != null; running = _inFlight) {
        await running.then<void>((_) {}, onError: (Object _) {});
      }
      return await action();
    } finally {
      _halts--;
    }
  }

  /// Ops the server rejected for good (400 or [maxHttpAttempts]).
  Future<int> failedCount() async => (await _failedOperations()).length;

  /// Puts rejected ops back in the queue and uploads immediately.
  Future<OfflineSyncResult> retryFailed() async {
    for (final op in await _failedOperations()) {
      await _store.updateOperation(
        op.copyWith(
          status: StudySyncStatus.pending,
          attempts: 0,
          httpAttempts: 0,
          nextRetryAt: 0,
          clearLastError: true,
        ),
      );
    }
    return flush(retryNow: true);
  }

  /// Drops rejected ops. Their local card changes stay until the next
  /// download replaces them with the server schedule.
  Future<void> discardFailed() async {
    final discarded = await _failedOperations();
    for (final op in discarded) {
      await _store.removeOperation(op.operationId);
    }
    final queued = {
      for (final op in await _store.getOperations()) (op.deckId, op.cardId),
    };
    for (final deckId in {for (final op in discarded) op.deckId}) {
      final cardIds = {
        for (final op in discarded)
          if (op.deckId == deckId) op.cardId,
      };
      final released = [
        for (final c in await _store.getCards(deckId))
          if (c.dirty &&
              cardIds.contains(c.id) &&
              !queued.contains((deckId, c.id)))
            c.copyWith(dirty: false),
      ];
      if (released.isNotEmpty) await _store.putCards(released);
    }
    phase.value = await _phaseAfter(
      const OfflineSyncResult(OfflineSyncStatus.skipped),
      await _isOnline(),
    );
  }

  Future<List<StudySyncOperation>> _failedOperations() async =>
      (await _store.getOperations())
          .where((op) => op.status == StudySyncStatus.failed)
          .toList();

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
    if (pending.any(isDue)) phase.value = OfflineSyncPhase.syncing;
    final ordered = queue.toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    // FIFO per card: a failed op, or one in backoff or failing now, holds
    // back later ops of the same card only. Sending them first would let a
    // retried failed op overwrite the newer schedule.
    final heldCards = <(String, String)>{};
    final syncedDecks = <String>{};
    final serverCards = <String, Future<List<OfflineCard>?>>{};
    var sent = 0;
    var failed = 0;
    var retry = false;
    for (final op in ordered) {
      if (_halts > 0) {
        retry = true;
        break;
      }
      final card = (op.deckId, op.cardId);
      if (heldCards.contains(card)) continue;
      if (op.status == StudySyncStatus.failed || !isDue(op)) {
        heldCards.add(card);
        continue;
      }
      final outcome = await _process(op, now, serverCards);
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
      if (outcome == _OpOutcome.failed) {
        failed++;
        heldCards.add(card);
      }
      if (outcome == _OpOutcome.retry) {
        retry = true;
        heldCards.add(card);
      }
      if (outcome == _OpOutcome.offline) {
        retry = true;
        break;
      }
    }
    for (final deckId in {...syncedDecks, ..._staleCountDecks}) {
      if (_halts > 0) break;
      if (await _refreshDeckCounts(deckId, now)) {
        _staleCountDecks.remove(deckId);
      } else {
        _staleCountDecks.add(deckId);
      }
    }
    final status = retry || failed > 0
        ? OfflineSyncStatus.partial
        : OfflineSyncStatus.synced;
    return OfflineSyncResult(status, sent: sent, failed: failed);
  }

  Future<_OpOutcome> _process(
    StudySyncOperation op,
    int now,
    Map<String, Future<List<OfflineCard>?>> serverCards,
  ) async {
    if (op.maybeApplied) {
      // Resending without knowing the server state could count it twice.
      final applied = await _appliedOnServer(op, serverCards);
      if (applied == null) return _OpOutcome.retry;
      if (applied) return _OpOutcome.sent;
    }
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
      // 400 (rejected body) and 403 (not the deck's owner any more) are
      // permanent; retrying cannot succeed.
      case 400 || 403:
        await _store.updateOperation(
          op.copyWith(
            status: StudySyncStatus.failed,
            lastError: result.message ?? 'HTTP ${result.httpStatus}',
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
        maybeApplied:
            (offline || _gatewayStatuses.contains(result.httpStatus)) &&
                op.type == StudySyncType.review
            ? true
            : null,
      ),
    );
    return offline ? _OpOutcome.offline : _OpOutcome.retry;
  }

  /// The server ignores `Idempotency-Key`, so resending a review it already
  /// applied would count it twice. Confirms the op from the server card when
  /// its schedule is exactly the reviewed one. Null when the server cards
  /// could not be read, so the state is unknown.
  Future<bool?> _appliedOnServer(
    StudySyncOperation op,
    Map<String, Future<List<OfflineCard>?>> serverCards,
  ) async {
    final cards = await (serverCards[op.deckId] ??= _remote.fetchCards(
      op.deckId,
    ));
    if (cards == null) return null;
    final server = cards.where((c) => c.id == op.cardId).firstOrNull;
    final lastReview = op.lastReview;
    if (server == null ||
        lastReview == null ||
        server.lastReview != lastReview ||
        server.dueDate != lastReview + (op.interval ?? 0)) {
      return false;
    }
    await _confirmCard(op, {
      'last_review': server.lastReview,
      'due_date': server.dueDate,
    });
    await _store.removeOperation(op.operationId);
    return true;
  }

  Future<void> _confirmCard(
    StudySyncOperation op,
    Map<String, dynamic> data,
  ) async {
    final card = await _store.getCard(op.deckId, op.cardId);
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

  /// Returns false when the counters could not be read (retried next flush).
  Future<bool> _refreshDeckCounts(String deckId, int now) async {
    final counts = await _remote.fetchDeckCounts(deckId);
    if (counts == null) return false;
    final deck = await _store.getDeck(deckId);
    if (deck == null) return true;
    await _store.putDeck(
      deck.copyWith(
        totalReviews: counts.totalReviews,
        totalReviewsToday: counts.totalReviewsToday,
        lastSyncedAt: now,
      ),
    );
    return true;
  }
}

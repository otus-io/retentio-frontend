import 'dart:io';

import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_card_detail_builder.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_scheduler.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/utils/media_client_id.dart';

/// Deals and records cards from the local store for downloaded decks and falls
/// back to [remote] otherwise. Whether a deck is local is decided once per
/// deck, so a download finishing mid-session does not switch sources while
/// online; offline, a deck downloaded meanwhile switches to local.
/// [remoteMediaUrl] receives an [OfflineFact.mediaKey] (`id` or `id?v=N`).
class OfflineFirstDeckStudyRepository implements DeckStudyRepository {
  OfflineFirstDeckStudyRepository({
    required Future<OfflineLearningStore?> store,
    required DeckStudyRepository remote,
    required String Function(String mediaId) remoteMediaUrl,
    void Function()? onLocalChange,
    Future<void> Function(String deckId)? refreshLocalCopy,
    Future<bool> Function()? isOnline,
    int Function()? nowSec,
    String Function()? newOperationId,
  }) : _store = store,
       _remote = remote,
       _remoteMediaUrl = remoteMediaUrl,
       _onLocalChange = onLocalChange,
       _refreshLocalCopy = refreshLocalCopy,
       _isOnline = isOnline ?? hasNetworkConnection,
       _nowSec = nowSec ?? _unixNow,
       _newOperationId = newOperationId ?? (() => 'op-${newMediaClientId()}');

  final Future<OfflineLearningStore?> _store;
  final DeckStudyRepository _remote;
  final String Function(String mediaId) _remoteMediaUrl;
  final void Function()? _onLocalChange;
  final Future<void> Function(String deckId)? _refreshLocalCopy;
  final Future<bool> Function() _isOnline;
  final int Function() _nowSec;
  final String Function() _newOperationId;
  final Map<String, Future<OfflineDeck?>> _localDecks = {};

  static int _unixNow() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Future<OfflineDeck?> _localDeck(String deckId) =>
      _localDecks[deckId] ??= _store.then((store) async {
        final deck = await store?.getDeck(deckId);
        return deck != null && deck.isReady ? deck : null;
      });

  /// Re-syncs a downloaded deck whose facts just changed online. Re-reads the
  /// deck row afterwards (name and fields may have changed); a deck served
  /// remotely stays remote.
  @override
  Future<bool> resyncLocalCopy(String deckId) async {
    final refresh = _refreshLocalCopy;
    if (refresh == null || await _localDeck(deckId) == null) return false;
    if (!await _isOnline()) return false;
    await refresh(deckId);
    _localDecks.remove(deckId);
    return true;
  }

  @override
  Future<DeckStudyLoadResult> loadNextDueCard({
    required String deckId,
    String? tagId,
  }) async {
    var deck = await _localDeck(deckId);
    if (deck == null) {
      if (await _isOnline()) {
        return _remote.loadNextDueCard(deckId: deckId, tagId: tagId);
      }
      _localDecks.remove(deckId);
      deck = await _localDeck(deckId);
      if (deck == null) {
        return const DeckStudyLoadResult(cardDetail: null, needsDownload: true);
      }
    }
    final store = (await _store)!;
    final now = _nowSec();
    final facts = {for (final f in await store.getFacts(deckId)) f.id: f};
    final scoped = [
      for (final c in await store.getCards(deckId))
        if (facts[c.factId] case final fact?)
          if (tagId == null || fact.tagIds.contains(tagId)) c,
    ];
    final selection = selectNextCards(scoped, nowSec: now);
    var card = selection.card;
    if (card != null) {
      final clamped = clampFutureLastReview(card, now);
      if (!identical(clamped, card)) await store.putCards([clamped]);
      card = clamped;
    }
    final detail = await _detail(store, deck, facts, card, selection.urgency);
    final next = await _detail(
      store,
      deck,
      facts,
      selection.nextCard,
      selection.nextUrgency,
    );
    return DeckStudyLoadResult(
      cardDetail: detail,
      nextCardDetail: next,
      refreshedCardsCount: tagId != null || detail == null
          ? scoped.length
          : null,
      refreshedDueCardsCount: scoped
          .where((c) => !c.hidden && c.dueDate <= now)
          .length,
    );
  }

  Future<CardDetail?> _detail(
    OfflineLearningStore store,
    OfflineDeck deck,
    Map<String, OfflineFact> facts,
    OfflineCard? card,
    double urgency,
  ) async {
    if (card == null) return null;
    final fact = facts[card.factId]!;
    final paths = <String, String>{};
    for (final e in fact.entries) {
      for (final id in [e.audio, e.image, e.video, e.json]) {
        final path = id.isEmpty
            ? null
            : await store.getMediaPath(fact.mediaKey(id));
        if (path != null && await File(path).exists()) paths[id] = path;
      }
    }
    return buildOfflineCardDetail(
      card: card,
      fact: fact,
      deckFields: deck.fields,
      urgency: urgency,
      resolveMedia: (id) => paths[id] ?? _remoteMediaUrl(fact.mediaKey(id)),
    );
  }

  @override
  Future<bool> submitCard(DeckStudySubmitRequest request) async {
    var deck = await _localDeck(request.deckId);
    if (deck == null && !await _isOnline()) {
      // Went offline while the deck was served remotely: a download that
      // finished meanwhile lets the review be queued instead of lost.
      _localDecks.remove(request.deckId);
      deck = await _localDeck(request.deckId);
    }
    if (deck == null) return _remote.submitCard(request);
    final store = (await _store)!;
    final card = await store.getCard(request.deckId, request.cardId);
    if (card == null) return false;
    final now = _nowSec();
    final isReview = request.type == DeckStudySubmitType.review;
    final updated = isReview
        ? applyReview(
            card,
            intervalSec: request.intervalSeconds ?? 0,
            lastReviewSec: request.lastReviewSeconds ?? now,
            nowSec: now,
          )
        : applyHide(card);
    final op = StudySyncOperation(
      operationId: _newOperationId(),
      sequence: await store.nextSequence(),
      deckId: request.deckId,
      cardId: card.id,
      type: isReview ? StudySyncType.review : StudySyncType.hide,
      createdAt: now,
      interval: isReview ? request.intervalSeconds : null,
      lastReview: isReview ? updated.lastReview : null,
      hidden: isReview ? null : true,
    );
    await store.applyLocalChange(updated, op);
    _onLocalChange?.call();
    return true;
  }

  /// Downloaded decks cache the tags loaded online and serve them offline. An
  /// empty online result keeps the cache (the remote returns [] on errors).
  @override
  Future<List<Tag>> loadDeckTags({required String deckId}) async {
    if (await _localDeck(deckId) == null) {
      return _remote.loadDeckTags(deckId: deckId);
    }
    final store = (await _store)!;
    if (!await _isOnline()) {
      return (await store.getDeck(deckId))?.tags ?? const [];
    }
    final tags = await _remote.loadDeckTags(deckId: deckId);
    final latest = await store.getDeck(deckId);
    if (latest != null && tags.isNotEmpty) {
      await store.putDeck(latest.copyWith(tags: tags));
    }
    return tags;
  }

  @override
  Future<bool> deleteCard({
    required String deckId,
    required String cardId,
  }) async {
    final deleted = await _remote.deleteCard(deckId: deckId, cardId: cardId);
    if (deleted) await (await _store)?.deleteCard(deckId, cardId);
    return deleted;
  }
}

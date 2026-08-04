import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/services/apis/tag_service.dart';
import 'package:retentio/utils/log.dart';

typedef LoadNextDueCardFn =
    Future<NextDueCardResult> Function(String deckId, {String? tagId});
typedef LoadDeckTagsFn = Future<List<Tag>> Function({required String deckId});
typedef GetDeckDetailFn = Future<Deck> Function(String deckId);
typedef GetCardsStatsFn =
    Future<DeckCardsStats?> Function(String deckId, {String? tagId});

Future<List<Tag>> _defaultLoadDeckTags({required String deckId}) =>
    TagService.of.getTags(usedOn: 'fact', deckId: deckId, unused: 'exclude');

/// Adapter repository that bridges DeckStudy domain to existing legacy services.
/// Keeps old provider stack untouched while enabling feature-level BLoC wiring.
class DeckStudyLegacyServiceRepository implements DeckStudyRepository {
  DeckStudyLegacyServiceRepository({
    DeckService? deckService,
    LoadNextDueCardFn? loadNextDueCardFn,
    LoadDeckTagsFn? loadDeckTagsFn,
    GetDeckDetailFn? getDeckDetailFn,
    GetCardsStatsFn? getCardsStatsFn,
  }) : _deckService = deckService ?? DeckService.of,
       _loadNextDueCardFn = loadNextDueCardFn ?? CardService.getNextDueCard,
       _loadDeckTagsFn = loadDeckTagsFn ?? _defaultLoadDeckTags,
       _getDeckDetailFn = getDeckDetailFn,
       _getCardsStatsFn = getCardsStatsFn ?? CardService.getCardsStats;

  final DeckService _deckService;
  final LoadNextDueCardFn _loadNextDueCardFn;
  final LoadDeckTagsFn _loadDeckTagsFn;
  final GetDeckDetailFn? _getDeckDetailFn;
  final GetCardsStatsFn _getCardsStatsFn;

  @override
  Future<DeckStudyLoadResult> loadNextDueCard({
    required String deckId,
    String? tagId,
  }) async {
    NextDueCardResult response;
    try {
      response = await _loadNextDueCardFn(deckId, tagId: tagId);
    } catch (e, s) {
      logger.e(
        'loadNextDueCard failed for deck=$deckId, error=$e',
        stackTrace: s,
      );
      return const DeckStudyLoadResult(cardDetail: null);
    }

    var cardDetail = response.cardDetail;
    if (_shouldIgnoreCardDetailForStudy(cardDetail)) {
      logger.w('Ignoring hidden card in deck study: ${cardDetail!.card.id}');
      cardDetail = null;
    }

    var nextCardDetail = response.nextCardDetail;
    if (cardDetail == null ||
        _shouldIgnoreCardDetailForStudy(nextCardDetail) ||
        nextCardDetail?.card.id == cardDetail.card.id) {
      nextCardDetail = null;
    }

    // Always load stats so study UI can track live due (deck-wide or tag-scoped).
    final cardsStats = await _loadCardsStats(deckId, tagId);

    if (cardDetail != null) {
      return DeckStudyLoadResult(
        cardDetail: cardDetail,
        nextCardDetail: nextCardDetail,
        refreshedCardsCount: tagId != null ? cardsStats?.totalCards : null,
        refreshedDueCardsCount: cardsStats?.dueCards,
      );
    }

    if (tagId != null) {
      return DeckStudyLoadResult(
        cardDetail: null,
        refreshedCardsCount: cardsStats?.totalCards,
        refreshedDueCardsCount: cardsStats?.dueCards,
      );
    }

    return _emptyDeckWideResult(deckId, cardsStats);
  }

  /// Deck-wide empty state: fills the counts card stats could not provide from
  /// deck detail so the study screen still shows real numbers.
  Future<DeckStudyLoadResult> _emptyDeckWideResult(
    String deckId,
    DeckCardsStats? cardsStats,
  ) async {
    int? refreshedCardsCount = cardsStats?.totalCards;
    int? refreshedDueCardsCount = cardsStats?.dueCards;
    if (refreshedCardsCount == null || refreshedDueCardsCount == null) {
      try {
        final deck = await (_getDeckDetailFn ?? _deckService.getDeckDetail)(
          deckId,
        );
        refreshedCardsCount ??= deck.stats.cardsCount;
        refreshedDueCardsCount ??= deck.stats.dueCards;
      } catch (e, s) {
        logger.w(
          'Failed to refresh deck detail for empty-study state, deck=$deckId',
        );
        logger.e('deck detail refresh error: $e', stackTrace: s);
      }
    }

    return DeckStudyLoadResult(
      cardDetail: null,
      refreshedCardsCount: refreshedCardsCount,
      refreshedDueCardsCount: refreshedDueCardsCount,
    );
  }

  Future<DeckCardsStats?> _loadCardsStats(String deckId, String? tagId) async {
    try {
      return await _getCardsStatsFn(deckId, tagId: tagId);
    } catch (e, s) {
      logger.w(
        'Failed to load card stats deck=$deckId tag=${tagId ?? '(none)'}',
      );
      logger.e('card stats error: $e', stackTrace: s);
      return null;
    }
  }

  @override
  Future<List<Tag>> loadDeckTags({required String deckId}) async {
    try {
      return await _loadDeckTagsFn(deckId: deckId);
    } catch (e, s) {
      logger.e('loadDeckTags failed for deck=$deckId', stackTrace: s);
      return [];
    }
  }

  @override
  Future<bool> submitCard(DeckStudySubmitRequest request) async {
    final body = <String, dynamic>{'card_id': request.cardId};
    if (request.type == DeckStudySubmitType.hide) {
      body['hidden'] = request.hidden ?? true;
    } else {
      body['interval'] = request.intervalSeconds;
      body['last_review'] = request.lastReviewSeconds;
    }

    final result = await CardService.updateCard(request.deckId, body);
    return result == true;
  }

  @override
  Future<bool> deleteCard({
    required String deckId,
    required String cardId,
  }) async {
    final response = await CardService.deleteCard(deckId, cardId);
    return response?.isSuccess == true;
  }
}

bool _shouldIgnoreCardDetailForStudy(CardDetail? response) =>
    response != null && response.card.hidden;

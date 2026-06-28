import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/services/apis/tag_service.dart';
import 'package:retentio/utils/log.dart';

typedef LoadNextDueCardFn =
    Future<CardDetail?> Function(String deckId, {String? tagId});
typedef LoadDeckTagsFn = Future<List<Tag>> Function({required String deckId});
typedef GetDeckDetailFn = Future<Deck> Function(String deckId);
typedef GetCardsCountFn = Future<int?> Function(String deckId, {String? tagId});

Future<List<Tag>> _defaultLoadDeckTags({required String deckId}) =>
    TagService.of.getTags(usedOn: 'fact', deckId: deckId);

/// Adapter repository that bridges DeckStudy domain to existing legacy services.
/// Keeps old provider stack untouched while enabling feature-level BLoC wiring.
class DeckStudyLegacyServiceRepository implements DeckStudyRepository {
  DeckStudyLegacyServiceRepository({
    DeckService? deckService,
    LoadNextDueCardFn? loadNextDueCardFn,
    LoadDeckTagsFn? loadDeckTagsFn,
    GetDeckDetailFn? getDeckDetailFn,
    GetCardsCountFn? getCardsCountFn,
  }) : _deckService = deckService ?? DeckService.of,
       _loadNextDueCardFn = loadNextDueCardFn ?? CardService.getNextDueCard,
       _loadDeckTagsFn = loadDeckTagsFn ?? _defaultLoadDeckTags,
       _getDeckDetailFn = getDeckDetailFn,
       _getCardsCountFn = getCardsCountFn ?? CardService.getCardsCount;

  final DeckService _deckService;
  final LoadNextDueCardFn _loadNextDueCardFn;
  final LoadDeckTagsFn _loadDeckTagsFn;
  final GetDeckDetailFn? _getDeckDetailFn;
  final GetCardsCountFn _getCardsCountFn;

  @override
  Future<DeckStudyLoadResult> loadNextDueCard({
    required String deckId,
    String? tagId,
  }) async {
    CardDetail? response;
    try {
      response = await _loadNextDueCardFn(deckId, tagId: tagId);
    } catch (e, s) {
      logger.e(
        'loadNextDueCard failed for deck=$deckId, error=$e',
        stackTrace: s,
      );
      return const DeckStudyLoadResult(cardDetail: null);
    }

    if (_shouldIgnoreCardDetailForStudy(response)) {
      logger.w('Ignoring hidden card in deck study: ${response!.card.id}');
      response = null;
    }

    final tagCardsCount = tagId != null
        ? await _loadTagCardsCount(deckId, tagId)
        : null;

    if (response != null) {
      return DeckStudyLoadResult(
        cardDetail: response,
        refreshedCardsCount: tagCardsCount,
      );
    }

    if (tagId != null) {
      return DeckStudyLoadResult(
        cardDetail: null,
        refreshedCardsCount: tagCardsCount,
      );
    }

    int? refreshedCardsCount;
    try {
      final deck = await (_getDeckDetailFn ?? _deckService.getDeckDetail)(
        deckId,
      );
      refreshedCardsCount = deck.stats.cardsCount;
    } catch (e, s) {
      logger.w(
        'Failed to refresh deck detail for empty-study state, deck=$deckId',
      );
      logger.e('deck detail refresh error: $e', stackTrace: s);
    }

    return DeckStudyLoadResult(
      cardDetail: null,
      refreshedCardsCount: refreshedCardsCount,
    );
  }

  Future<int?> _loadTagCardsCount(String deckId, String tagId) async {
    try {
      return await _getCardsCountFn(deckId, tagId: tagId);
    } catch (e, s) {
      logger.w('Failed to load tag card stats deck=$deckId tag=$tagId');
      logger.e('tag card stats error: $e', stackTrace: s);
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

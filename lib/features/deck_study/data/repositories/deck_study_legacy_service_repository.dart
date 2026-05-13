import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/utils/log.dart';

/// Adapter repository that bridges DeckStudy domain to existing legacy services.
/// Keeps old provider stack untouched while enabling feature-level BLoC wiring.
class DeckStudyLegacyServiceRepository implements DeckStudyRepository {
  DeckStudyLegacyServiceRepository({DeckService? deckService})
    : _deckService = deckService ?? DeckService.of;

  final DeckService _deckService;

  @override
  Future<DeckStudyLoadResult> loadNextDueCard({required String deckId}) async {
    CardDetail? response;
    try {
      response = await CardService.getNextDueCard(deckId);
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

    if (response != null) {
      return DeckStudyLoadResult(cardDetail: response);
    }

    int? refreshedCardsCount;
    try {
      final deck = await _deckService.getDeckDetail(deckId);
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

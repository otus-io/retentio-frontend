import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';

/// Account-scoped local storage for offline study. All methods act on the
/// account the store was opened for.
abstract class OfflineLearningStore {
  Future<OfflineDeck?> getDeck(String deckId);
  Future<List<OfflineDeck>> getDecks();
  Future<void> putDeck(OfflineDeck deck);

  Future<List<OfflineCard>> getCards(String deckId);

  /// Upserts by card id.
  Future<void> putCards(List<OfflineCard> cards);
  Future<void> deleteCard(String deckId, String cardId);

  Future<List<OfflineFact>> getFacts(String deckId);

  /// Upserts by fact id.
  Future<void> putFacts(List<OfflineFact> facts);

  /// Absolute path of a downloaded media file, or null when not cached.
  Future<String?> getMediaPath(String mediaId);
  Future<void> putMediaPath(String mediaId, String localPath);

  /// Writes the updated card and its queued operation together, so a killed
  /// process never keeps one without the other.
  Future<void> applyLocalChange(OfflineCard card, StudySyncOperation op);

  /// Next value for [StudySyncOperation.sequence].
  Future<int> nextSequence();

  /// All queued operations ordered by [StudySyncOperation.sequence].
  Future<List<StudySyncOperation>> getOperations();
  Future<void> updateOperation(StudySyncOperation op);
  Future<void> removeOperation(String operationId);

  /// Deletes every row of this account, including queued operations.
  Future<void> clear();
}

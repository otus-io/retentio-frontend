import 'package:hive_ce/hive.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';

/// Hive-backed [OfflineLearningStore] storing plain JSON maps, with every key
/// prefixed by `'$accountId:'`.
///
/// Cards and sync operations share the `offline_study` box (instead of
/// separate `offline_cards` / `offline_sync_queue` boxes) because Hive has no
/// cross-box transaction: [applyLocalChange] writes both rows in one `putAll`.
class HiveOfflineLearningStore implements OfflineLearningStore {
  HiveOfflineLearningStore({
    required this.accountId,
    required Box<dynamic> decks,
    required Box<dynamic> facts,
    required Box<dynamic> media,
    required Box<dynamic> study,
    required Box<dynamic> meta,
  }) : _decks = decks,
       _facts = facts,
       _media = media,
       _study = study,
       _meta = meta;

  static const decksBox = 'offline_decks';
  static const factsBox = 'offline_facts';
  static const mediaBox = 'offline_media';
  static const studyBox = 'offline_study';
  static const metaBox = 'offline_sync_meta';

  final String accountId;
  final Box<dynamic> _decks;
  final Box<dynamic> _facts;
  final Box<dynamic> _media;
  final Box<dynamic> _study;
  final Box<dynamic> _meta;

  static Future<HiveOfflineLearningStore> open({
    required String accountId,
    HiveCipher? cipher,
  }) async {
    Future<Box<dynamic>> openBox(String name) async => Hive.isBoxOpen(name)
        ? Hive.box<dynamic>(name)
        : Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    return HiveOfflineLearningStore(
      accountId: accountId,
      decks: await openBox(decksBox),
      facts: await openBox(factsBox),
      media: await openBox(mediaBox),
      study: await openBox(studyBox),
      meta: await openBox(metaBox),
    );
  }

  String get _seqKey => '$accountId:seq';
  String _deckKey(String deckId) => '$accountId:deck:$deckId';
  String _factPrefix(String deckId) => '$accountId:fact:$deckId:';
  String _cardPrefix(String deckId) => '$accountId:card:$deckId:';
  String _cardKey(OfflineCard c) => '${_cardPrefix(c.deckId)}${c.id}';
  String get _syncPrefix => '$accountId:sync:';
  String _syncKey(String operationId) => '$_syncPrefix$operationId';
  String _mediaKey(String mediaId) => '$accountId:media:$mediaId';

  static Map<String, dynamic> _json(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  static Iterable<Map<String, dynamic>> _rows(
    Box<dynamic> box,
    String prefix,
  ) => box.keys
      .whereType<String>()
      .where((k) => k.startsWith(prefix))
      .map((k) => _json(box.get(k)));

  @override
  Future<OfflineDeck?> getDeck(String deckId) async {
    final value = _decks.get(_deckKey(deckId));
    return value == null ? null : OfflineDeck.fromJson(_json(value));
  }

  @override
  Future<void> putDeck(OfflineDeck deck) =>
      _decks.put(_deckKey(deck.id), deck.toJson());

  @override
  Future<List<OfflineCard>> getCards(String deckId) async =>
      _rows(_study, _cardPrefix(deckId)).map(OfflineCard.fromJson).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  @override
  Future<void> putCards(List<OfflineCard> cards) =>
      _study.putAll({for (final c in cards) _cardKey(c): c.toJson()});

  @override
  Future<void> deleteCard(String deckId, String cardId) =>
      _study.delete('${_cardPrefix(deckId)}$cardId');

  @override
  Future<List<OfflineFact>> getFacts(String deckId) async =>
      _rows(_facts, _factPrefix(deckId)).map(OfflineFact.fromJson).toList();

  @override
  Future<void> putFacts(List<OfflineFact> facts) => _facts.putAll({
    for (final f in facts) '${_factPrefix(f.deckId)}${f.id}': f.toJson(),
  });

  @override
  Future<String?> getMediaPath(String mediaId) async =>
      _media.get(_mediaKey(mediaId)) as String?;

  @override
  Future<void> putMediaPath(String mediaId, String localPath) =>
      _media.put(_mediaKey(mediaId), localPath);

  @override
  Future<void> applyLocalChange(OfflineCard card, StudySyncOperation op) =>
      _study.putAll({
        _cardKey(card): card.toJson(),
        _syncKey(op.operationId): op.toJson(),
      });

  @override
  Future<int> nextSequence() async {
    final next = ((_meta.get(_seqKey) as int?) ?? 0) + 1;
    await _meta.put(_seqKey, next);
    return next;
  }

  @override
  Future<List<StudySyncOperation>> getOperations() async =>
      _rows(_study, _syncPrefix).map(StudySyncOperation.fromJson).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

  @override
  Future<void> updateOperation(StudySyncOperation op) =>
      _study.put(_syncKey(op.operationId), op.toJson());

  @override
  Future<void> removeOperation(String operationId) =>
      _study.delete(_syncKey(operationId));
}

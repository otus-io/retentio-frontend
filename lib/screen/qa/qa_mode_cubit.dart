import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/fact_quality.dart';
import 'package:retentio/screen/qa/qa_column_prefs.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/services/apis/fact_quality_service.dart';

/// Note attached to `fact_edit` contributions sent from QA mode.
const String kQaEditMessage = 'QA edit';

class QaModeState {
  const QaModeState({
    this.loading = false,
    this.pickingColumns = true,
    this.factIds = const [],
    this.index = 0,
    this.fact,
    this.quality,
    this.mediaVersions = const {},
    this.activeColumnIndexes = const {},
    this.checkedIndexes = const {},
    this.stats,
    this.editedCount = 0,
    this.busy = false,
  });

  final bool loading;

  /// Column picker shown before the walk starts.
  final bool pickingColumns;
  final List<String> factIds;
  final int index;
  final Fact? fact;
  final FactQuality? quality;

  /// Snapshot pin versions for media ids on the current fact (import decks).
  final Map<String, int> mediaVersions;

  /// Deck columns included in this QA walk (entry indexes).
  final Set<int> activeColumnIndexes;

  /// Columns signed off when advancing to the next fact.
  final Set<int> checkedIndexes;

  /// Deck-wide human verification counters; `null` when unavailable.
  final FactQualityStats? stats;
  final int editedCount;
  final bool busy;

  String? get factId =>
      index >= 0 && index < factIds.length ? factIds[index] : null;

  List<FactEntry> get entries => fact?.entries ?? const [];

  bool get hasPrev => index > 0;

  bool get hasNext => index + 1 < factIds.length;

  /// Active columns with something to sign off on (text and/or audio present).
  Set<int> get scoreableIndexes {
    final scoreable = <int>{};
    for (var i = 0; i < entries.length; i++) {
      if (!activeColumnIndexes.contains(i)) continue;
      if (qaScoreableAspects(entries[i]).isNotEmpty) scoreable.add(i);
    }
    return scoreable;
  }

  bool get canVerify {
    if (fact == null || busy) return false;
    final scoreable = scoreableIndexes;
    return scoreable.isNotEmpty && checkedIndexes.containsAll(scoreable);
  }

  bool get factLoadFailed =>
      !loading && !pickingColumns && factIds.isNotEmpty && fact == null;

  QaModeState copyWith({
    bool? loading,
    bool? pickingColumns,
    List<String>? factIds,
    int? index,
    Fact? fact,
    FactQuality? quality,
    Map<String, int>? mediaVersions,
    Set<int>? activeColumnIndexes,
    Set<int>? checkedIndexes,
    FactQualityStats? stats,
    int? editedCount,
    bool? busy,
  }) => QaModeState(
    loading: loading ?? this.loading,
    pickingColumns: pickingColumns ?? this.pickingColumns,
    factIds: factIds ?? this.factIds,
    index: index ?? this.index,
    fact: fact ?? this.fact,
    quality: quality ?? this.quality,
    mediaVersions: mediaVersions ?? this.mediaVersions,
    activeColumnIndexes: activeColumnIndexes ?? this.activeColumnIndexes,
    checkedIndexes: checkedIndexes ?? this.checkedIndexes,
    stats: stats ?? this.stats,
    editedCount: editedCount ?? this.editedCount,
    busy: busy ?? this.busy,
  );
}

/// Linear QA walk over an imported deck: per-column sign-off plus immediate
/// `fact_edit` submission. Kept out of the study bloc so a broken quality API
/// only affects this screen.
class QaModeCubit extends Cubit<QaModeState> {
  QaModeCubit({required this.deckId, required this.deckFieldCount})
    : super(const QaModeState());

  final String deckId;
  final int deckFieldCount;

  /// Loads a saved column pick, or every deck field when none is stored.
  Future<Set<int>> initialColumnSelection() async {
    final saved = await QaColumnPrefs.load(deckId);
    final count = deckFieldCount > 0 ? deckFieldCount : 1;
    final all = {for (var i = 0; i < count; i++) i};
    if (saved == null || saved.isEmpty) return all;
    return saved.where((i) => i >= 0 && i < count).toSet().isEmpty
        ? all
        : saved.where((i) => i >= 0 && i < count).toSet();
  }

  /// Locks the column filter for this walk and loads facts.
  Future<void> startWalk(Set<int> activeColumnIndexes) async {
    if (activeColumnIndexes.isEmpty || state.busy) return;
    await QaColumnPrefs.save(deckId, activeColumnIndexes);
    final resumeWalk = state.factIds.isNotEmpty;
    emit(
      QaModeState(
        pickingColumns: false,
        loading: true,
        activeColumnIndexes: Set<int>.of(activeColumnIndexes),
        factIds: resumeWalk ? state.factIds : const [],
        index: resumeWalk ? state.index : 0,
        stats: state.stats,
        editedCount: state.editedCount,
      ),
    );
    if (resumeWalk) {
      await _loadCurrentFact();
      await _refreshHeader();
    } else {
      await _loadFacts();
    }
  }

  /// Re-opens the column picker without losing walk progress counters.
  void reopenColumnPicker() {
    if (state.busy) return;
    emit(
      QaModeState(
        pickingColumns: true,
        activeColumnIndexes: state.activeColumnIndexes,
        factIds: state.factIds,
        index: state.index,
        stats: state.stats,
        editedCount: state.editedCount,
      ),
    );
  }

  /// Loads deck quality stats for the column picker and walk header.
  Future<void> refreshStats() async {
    final stats = await FactQualityService.of.getDeckQualityStats(deckId);
    if (isClosed) return;
    emit(state.copyWith(stats: stats));
  }

  Future<void> _loadFacts() async {
    final resumeId = (await FactQualityService.of.getDeckQualityStats(
      deckId,
    ))?.lastFactId;
    if (isClosed) return;
    final ids = await CardService.listFactIds(deckId);
    if (isClosed) return;
    final verifiedIndex = resumeId == null ? -1 : ids.indexOf(resumeId);
    final startIndex = verifiedIndex >= 0
        ? (verifiedIndex + 1).clamp(0, ids.length - 1)
        : 0;
    emit(
      state.copyWith(loading: ids.isNotEmpty, factIds: ids, index: startIndex),
    );
    if (ids.isEmpty) {
      emit(state.copyWith(loading: false));
      return;
    }
    await _loadCurrentFact();
    await _refreshHeader();
  }

  Future<void> goTo(int index) async {
    if (state.busy || index < 0 || index >= state.factIds.length) return;
    emit(
      state.copyWith(
        index: index,
        fact: null,
        quality: null,
        mediaVersions: const {},
        checkedIndexes: const {},
        loading: true,
      ),
    );
    await _loadCurrentFact();
  }

  Future<String?> next() async {
    if (state.checkedIndexes.isNotEmpty) {
      final error = await verify();
      if (error != null) return error;
    }
    await goTo(state.index + 1);
    return null;
  }

  Future<void> prev() => goTo(state.index - 1);

  void toggleColumn(int entryIndex) {
    if (state.busy || !state.activeColumnIndexes.contains(entryIndex)) return;
    final checked = Set<int>.of(state.checkedIndexes);
    if (!checked.remove(entryIndex)) {
      checked.add(entryIndex);
    }
    emit(state.copyWith(checkedIndexes: checked));
  }

  Map<String, dynamic> pendingPutEntries() => qaMergedQualityEntries(
    quality: state.quality,
    entries: state.entries,
    checkedIndexes: state.checkedIndexes,
    activeColumnIndexes: state.activeColumnIndexes,
  );

  Future<String?> verify() async {
    final factId = state.factId;
    if (factId == null || state.checkedIndexes.isEmpty) return null;
    emit(state.copyWith(busy: true));
    try {
      await FactQualityService.of.putFactQuality(
        deckId: deckId,
        factId: factId,
        entries: pendingPutEntries(),
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return rawApiErrorMessage(e);
    }
    final quality = await FactQualityService.of.getFactQuality(
      deckId: deckId,
      factId: factId,
    );
    if (isClosed) return null;
    if (quality == null) {
      emit(state.copyWith(busy: false));
    } else {
      emit(
        state.copyWith(busy: false, quality: quality, checkedIndexes: const {}),
      );
    }
    await _refreshHeader();
    return null;
  }

  Future<String?> submitEdit({int? entryIndex}) async {
    final factId = state.factId;
    if (factId == null) return null;
    emit(state.copyWith(busy: true));
    String? error;
    try {
      final contributionId = await DeckCatalogService.of
          .submitFactEditContribution(
            importDeckId: deckId,
            factId: factId,
            message: kQaEditMessage,
            entryIndex: entryIndex,
          );
      await PendingContributionsStore.of.markAsSent(
        deckId,
        PendingContributionsStore.of.itemId(
          PendingContributionKind.edit,
          factId: factId,
        ),
        contributionId: contributionId,
        message: kQaEditMessage,
      );
    } catch (e) {
      error = rawApiErrorMessage(e);
    }
    if (isClosed) return error;
    emit(state.copyWith(busy: false));
    await goTo(state.index);
    await _refreshHeader();
    return error;
  }

  Future<void> _loadCurrentFact() async {
    final factId = state.factId;
    if (factId == null) {
      emit(state.copyWith(loading: false));
      return;
    }
    final detail = await CardService.getFactDetail(deckId, factId);
    final fact = detail?.fact;
    final mediaVersions = detail?.mediaVersions ?? const <String, int>{};
    final quality = fact == null
        ? null
        : await FactQualityService.of.getFactQuality(
            deckId: deckId,
            factId: factId,
          );
    if (isClosed) return;
    emit(
      state.copyWith(
        loading: false,
        fact: fact,
        quality: quality,
        mediaVersions: mediaVersions,
        checkedIndexes: const {},
      ),
    );
  }

  Future<void> _refreshHeader() async {
    final stats = await FactQualityService.of.getDeckQualityStats(deckId);
    final sent = await PendingContributionsStore.of.listSent(deckId);
    if (isClosed) return;
    emit(
      state.copyWith(
        stats: stats,
        editedCount: sent
            .where((row) => row.kind == PendingContributionKind.edit)
            .length,
      ),
    );
  }
}

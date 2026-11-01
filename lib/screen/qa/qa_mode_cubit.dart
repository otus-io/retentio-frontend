import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/fact_quality.dart';
import 'package:retentio/screen/qa/qa_column_prefs.dart';
import 'package:retentio/services/apis/card_service.dart';
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
    this.walkComplete = false,
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

  /// Set after Next signs off the last fact of this column set.
  final bool walkComplete;

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

  /// Whether the walk may advance: every scoreable column is checked, or none
  /// need verification on this fact.
  bool get canAdvance {
    if (fact == null || busy) return false;
    final scoreable = scoreableIndexes;
    if (scoreable.isEmpty) return true;
    return checkedIndexes.containsAll(scoreable);
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
    bool? walkComplete,
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
    walkComplete: walkComplete ?? this.walkComplete,
  );
}

/// Linear QA walk over an imported deck: per-column sign-off plus immediate
/// `fact_edit` submission. Kept out of the study bloc so a broken quality API
/// only affects this screen.
class QaModeCubit extends Cubit<QaModeState> {
  QaModeCubit({
    required this.deckId,
    required this.deckFieldCount,
    Future<bool> Function()? isOnline,
  }) : _isOnline = isOnline ?? hasNetworkConnection,
       super(const QaModeState());

  final String deckId;
  final int deckFieldCount;
  final Future<bool> Function() _isOnline;

  /// When true, the next [_refreshHeader] throws (cleared after throw).
  @visibleForTesting
  bool debugFailNextRefreshHeader = false;

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
  ///
  /// A different selection opens at the earliest per-column server cursor (the
  /// first fact when any selected column has not been walked). Same columns
  /// stay on the current fact unless every selected cursor is already on the
  /// last fact — then [QaModeState.walkComplete] is set immediately.
  Future<void> startWalk(Set<int> activeColumnIndexes) async {
    if (activeColumnIndexes.isEmpty || state.busy) return;
    final columns = Set<int>.of(activeColumnIndexes);
    await QaColumnPrefs.save(deckId, columns);
    if (isClosed) return;
    final factsLoaded = state.factIds.isNotEmpty;
    final sameColumns =
        factsLoaded && setEquals(state.activeColumnIndexes, columns);
    var index = state.index;
    var stats = state.stats;
    if (factsLoaded) {
      // Always refetch: another device may have advanced cursors since load.
      // A failed read keeps the stats already on screen.
      final fetched = await FactQualityService.of.getDeckQualityStats(deckId);
      if (isClosed) return;
      if (fetched != null) stats = fetched;
      final cursors = stats?.cursors ?? const {};
      if (qaColumnsWalkComplete(
        columns: columns,
        cursors: cursors,
        factIds: state.factIds,
      )) {
        emit(
          QaModeState(
            pickingColumns: false,
            walkComplete: true,
            activeColumnIndexes: columns,
            factIds: state.factIds,
            index: state.factIds.length - 1,
            stats: stats,
            editedCount: stats?.editedCount ?? 0,
          ),
        );
        return;
      }
      if (!sameColumns) {
        final resumeId = qaResumeFactId(
          columns: columns,
          cursors: cursors,
          factIds: state.factIds,
        );
        index = _resumeIndex(state.factIds, resumeId);
      }
    }
    emit(
      QaModeState(
        pickingColumns: false,
        loading: true,
        activeColumnIndexes: columns,
        factIds: factsLoaded ? state.factIds : const [],
        index: factsLoaded ? index : 0,
        stats: stats,
        editedCount: stats?.editedCount ?? state.editedCount,
      ),
    );
    if (factsLoaded) {
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
    emit(
      state.copyWith(
        stats: stats,
        editedCount: stats?.editedCount ?? state.editedCount,
      ),
    );
  }

  Future<void> _loadFacts() async {
    final ids = await CardService.listFactIds(deckId);
    if (isClosed) return;
    final stats = await FactQualityService.of.getDeckQualityStats(deckId);
    if (isClosed) return;
    final cursors = stats?.cursors ?? const {};
    final editedCount = stats?.editedCount ?? 0;
    if (qaColumnsWalkComplete(
      columns: state.activeColumnIndexes,
      cursors: cursors,
      factIds: ids,
    )) {
      emit(
        state.copyWith(
          loading: false,
          factIds: ids,
          index: ids.length - 1,
          stats: stats,
          editedCount: editedCount,
          walkComplete: true,
        ),
      );
      return;
    }
    final resumeId = qaResumeFactId(
      columns: state.activeColumnIndexes,
      cursors: cursors,
      factIds: ids,
    );
    final startIndex = _resumeIndex(ids, resumeId);
    emit(
      state.copyWith(
        loading: ids.isNotEmpty,
        factIds: ids,
        index: startIndex,
        stats: stats,
        editedCount: editedCount,
      ),
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
        walkComplete: false,
      ),
    );
    await _loadCurrentFact();
  }

  Future<String?> next() async {
    if (!state.canAdvance) return null;
    final finishing = !state.hasNext;
    if (state.canVerify) {
      final error = await verify();
      if (error != null) return error;
    }
    await goTo(state.index + 1);
    if (finishing && !state.walkComplete && !isClosed) {
      emit(state.copyWith(walkComplete: true));
    }
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
    if (!await _isOnline().catchError((Object _) => true)) {
      return 'Connect error';
    }
    emit(state.copyWith(busy: true));
    try {
      await FactQualityService.of.putFactQuality(
        deckId: deckId,
        factId: factId,
        entries: pendingPutEntries(),
        // In-range active columns only (incl. empty); out-of-range deck
        // fields would 400 on the server.
        columns:
            (state.activeColumnIndexes
                .where((i) => i >= 0 && i < state.entries.length)
                .toList()
              ..sort()),
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return rawApiErrorMessage(e);
    }
    FactQuality? quality;
    try {
      quality = await FactQualityService.of.getFactQuality(
        deckId: deckId,
        factId: factId,
      );
      if (isClosed) return null;
      await _refreshHeader();
    } catch (_) {
      // Put already succeeded; busy/checks cleared in finally.
    } finally {
      if (!isClosed) {
        if (quality != null) {
          emit(
            state.copyWith(
              busy: false,
              quality: quality,
              checkedIndexes: const {},
            ),
          );
        } else {
          emit(state.copyWith(busy: false, checkedIndexes: const {}));
        }
      }
    }
    return null;
  }

  /// Reloads the current fact after [FactEdit] auto-submits the contribution.
  ///
  /// Does not use [goTo] — that method no-ops while [QaModeState.busy] is true.
  /// [entryIndex] is kept for call-site compatibility; FactEdit sends it.
  // ignore: avoid_unused_parameter
  Future<String?> submitEdit({int? entryIndex}) async {
    final factId = state.factId;
    if (factId == null) return null;
    if (isClosed) return null;
    emit(state.copyWith(busy: true, loading: true));
    try {
      await _loadCurrentFact();
      await _refreshHeader();
    } catch (_) {
      // Reload failed; busy/loading cleared in finally so QA isn't stuck.
    } finally {
      if (!isClosed) {
        emit(state.copyWith(busy: false, loading: false));
      }
    }
    return null;
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

  /// Index of the fact after [resumeId], or 0 when there is nothing to resume.
  ///
  /// The last fact stays put: signing it off has no later fact to open.
  static int _resumeIndex(List<String> ids, String? resumeId) {
    if (ids.isEmpty || resumeId == null) return 0;
    final verifiedIndex = ids.indexOf(resumeId);
    if (verifiedIndex < 0) return 0;
    final next = verifiedIndex + 1;
    if (next >= ids.length) return ids.length - 1;
    return next;
  }

  Future<void> _refreshHeader() async {
    if (debugFailNextRefreshHeader) {
      debugFailNextRefreshHeader = false;
      throw StateError('qa header refresh failed');
    }
    final stats = await FactQualityService.of.getDeckQualityStats(deckId);
    if (isClosed) return;
    emit(
      state.copyWith(
        stats: stats,
        editedCount: stats?.editedCount ?? state.editedCount,
      ),
    );
  }
}

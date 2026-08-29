import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/fact_quality.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/services/apis/fact_quality_service.dart';

/// Note attached to `fact_edit` contributions sent from QA mode.
const String kQaEditMessage = 'QA edit';

class QaModeState {
  const QaModeState({
    this.loading = true,
    this.factIds = const [],
    this.index = 0,
    this.fact,
    this.quality,
    this.mediaVersions = const {},
    this.checkedIndexes = const {},
    this.stats,
    this.editedCount = 0,
    this.busy = false,
  });

  final bool loading;
  final List<String> factIds;
  final int index;
  final Fact? fact;
  final FactQuality? quality;

  /// Snapshot pin versions for media ids on the current fact (import decks).
  final Map<String, int> mediaVersions;

  /// Columns the reviewer signs off on with the next Verified.
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

  /// Columns with something to sign off on (text and/or audio present).
  Set<int> get scoreableIndexes {
    final scoreable = <int>{};
    for (var i = 0; i < entries.length; i++) {
      if (qaScoreableAspects(entries[i]).isNotEmpty) scoreable.add(i);
    }
    return scoreable;
  }

  bool get canVerify {
    if (fact == null || busy) return false;
    final scoreable = scoreableIndexes;
    return scoreable.isNotEmpty && checkedIndexes.containsAll(scoreable);
  }

  bool get factLoadFailed => !loading && factIds.isNotEmpty && fact == null;

  QaModeState copyWith({
    bool? loading,
    List<String>? factIds,
    Fact? fact,
    FactQuality? quality,
    Map<String, int>? mediaVersions,
    Set<int>? checkedIndexes,
    FactQualityStats? stats,
    int? editedCount,
    bool? busy,
  }) => QaModeState(
    loading: loading ?? this.loading,
    factIds: factIds ?? this.factIds,
    index: index,
    fact: fact ?? this.fact,
    quality: quality ?? this.quality,
    mediaVersions: mediaVersions ?? this.mediaVersions,
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
  QaModeCubit({required this.deckId}) : super(const QaModeState());

  final String deckId;

  /// Shows the first fact after one page of ids; the rest stream in behind it,
  /// because a whole-deck id walk costs one request per 50 facts.
  Future<void> load() async {
    emit(QaModeState(editedCount: state.editedCount));
    final resumeId = (await FactQualityService.of.getDeckQualityStats(
      deckId,
    ))?.lastFactId;
    if (isClosed) return;
    // With a resume cursor we need the whole id list to locate it (it may sit
    // past the first page); otherwise keep the one-page fast paint.
    final ids = resumeId == null
        ? await CardService.listFactIdsPage(deckId)
        : await CardService.listFactIds(deckId);
    if (isClosed) return;
    // The cursor marks the last verified fact (advanced server-side on verify);
    // resume just past it so the reviewer picks up at the next unreviewed fact.
    final verifiedIndex = resumeId == null ? -1 : ids.indexOf(resumeId);
    final startIndex = verifiedIndex >= 0
        ? (verifiedIndex + 1).clamp(0, ids.length - 1)
        : 0;
    emit(
      QaModeState(
        loading: ids.isNotEmpty,
        factIds: ids,
        index: startIndex,
        editedCount: state.editedCount,
      ),
    );
    if (ids.isEmpty) return;
    await _loadCurrentFact();
    await _refreshHeader();
    if (resumeId == null) await _loadRemainingIds();
  }

  Future<void> goTo(int index) async {
    if (state.busy || index < 0 || index >= state.factIds.length) return;
    emit(
      QaModeState(
        factIds: state.factIds,
        index: index,
        stats: state.stats,
        editedCount: state.editedCount,
      ),
    );
    await _loadCurrentFact();
  }

  Future<void> next() async {
    // Auto sign-off: signing the checked columns is what advances the
    // server-side resume cursor, so send it silently before walking forward.
    if (state.checkedIndexes.isNotEmpty) {
      await verify();
    }
    await goTo(state.index + 1);
  }

  Future<void> prev() => goTo(state.index - 1);

  void toggleColumn(int entryIndex) {
    if (state.busy) return;
    final checked = Set<int>.of(state.checkedIndexes);
    if (!checked.remove(entryIndex)) {
      checked.add(entryIndex);
    }
    emit(state.copyWith(checkedIndexes: checked));
  }

  /// `entries` payload the next Verified would PUT (shown in the confirm sheet).
  Map<String, dynamic> pendingPutEntries() => qaMergedQualityEntries(
    quality: state.quality,
    entries: state.entries,
    checkedIndexes: state.checkedIndexes,
  );

  /// Signs off the checked columns. Returns the raw API error, or `null` when ok.
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

  /// Freezes the overlay just saved by the fact editor as a `fact_edit`
  /// contribution (QA skips the outbox). Returns the raw API error, or `null`.
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
    if (factId == null) return;
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

  Future<void> _loadRemainingIds() async {
    var offset = state.factIds.length;
    while (offset > 0 &&
        offset % CardService.factIdsPageSize == 0 &&
        offset <= 10000) {
      final page = await CardService.listFactIdsPage(deckId, offset: offset);
      if (isClosed || page.isEmpty) return;
      offset += page.length;
      emit(state.copyWith(factIds: [...state.factIds, ...page]));
    }
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

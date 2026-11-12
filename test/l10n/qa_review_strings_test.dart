import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';

List<String> _strings(AppLocalizations l) => [
  l.addFactSubmit,
  l.addFactSuccess,
  l.addFactMarkVerified,
  l.addFactSentToAuthor,
  l.addFactSavedUnsent,
  l.deckTagsSentToAuthor,
  l.deckTagsSavedUnsent,
  l.contributionsAcceptAllProgress(1, 3),
  l.contributionsAcceptAllPartial(1, 2),
  l.contributionsAcceptAllPartial(2, 1),
  l.qaModeFactsLoadFailed,
  l.qaModePrevious,
  l.qaModeWalkComplete,
  l.qaModeProgress(1, 3),
  l.qaModeSkip,
  l.qaVerifiedBadge,
  l.discoveryContributors('Ann'),
  l.discoveryContributorsMore('Ann', 2),
  l.qaReviewType,
  l.qaReviewSummary(1, 1),
  l.qaReviewSummary(2, 3),
  l.qaReviewSharedNotice,
  l.qaReviewSent(1),
  l.qaReviewSent(2),
  l.qaReviewNothingToSend,
  l.qaReviewOwnDeck,
  l.qaReviewAccepted(1),
  l.qaReviewAccepted(2),
  l.qaReviewViewFields,
  l.qaReviewPreviewSummary(1, 2),
  l.qaReviewStatusReady,
  l.qaReviewStatusChanged,
  l.qaReviewStatusVerified,
  l.qaReviewStatusRemoved,
  l.qaReviewAspectText,
  l.qaReviewAspectAudio,
  l.qaReviewNoFields,
];

void main() {
  for (final code in ['en', 'zh', 'ja']) {
    test('QA review strings are non-empty in $code', () {
      final l = lookupAppLocalizations(Locale(code));
      for (final s in _strings(l)) {
        expect(s.trim(), isNotEmpty);
      }
    });
  }
}

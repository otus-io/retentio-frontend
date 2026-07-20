import 'package:retentio/l10n/app_localizations.dart';

/// Maps raw API `msg` strings to localized user-facing messages.
///
/// Covers all documented errors in `docs/api.md#error-responses-reference`.
/// Unknown messages fall back to the raw server string; server 500-style
/// messages fall back to [AppLocalizations.errorServerError].
class ApiErrorMessages {
  const ApiErrorMessages._();

  static final _exact = <String, String Function(AppLocalizations)>{
    // Legacy keys (pre-existing l10n entries)
    'Invalid credentials': (loc) => loc.authInvalidCredentials,
    'Username already exists': (loc) => loc.authUsernameAlreadyExists,
    'Email already in use': (loc) => loc.authEmailAlreadyInUse,
    'Invalid or expired token': (loc) => loc.authSessionExpired,
    'Token has been revoked': (loc) => loc.authSessionExpired,
    'Authorization token required': (loc) => loc.authTokenRequired,
    'User not found for reset token': (loc) => loc.authResetTokenInvalid,
    'Invalid or expired reset token': (loc) => loc.authResetTokenInvalid,
    'Connect timeout': (loc) => loc.noNetworkConnection,
    'Connect error': (loc) => loc.noNetworkConnection,
    'Send timeout': (loc) => loc.noNetworkConnection,
    'Receive timeout': (loc) => loc.noNetworkConnection,
    'Transform timeout': (loc) => loc.noNetworkConnection,
    'cannot import your own deck': (loc) => loc.discoveryImportSelf,
    'source deck is not importable': (loc) => loc.errorSourceDeckNotImportable,
    'cannot import an imported deck': (loc) =>
        loc.errorCannotImportImportedDeck,
    'source deck has not been published': (loc) =>
        loc.errorSourceDeckNotPublished,
    'source deck not found': (loc) => loc.discoveryNotFound,
    'Deck not found in catalog': (loc) => loc.discoveryNotFound,
    'no changes to publish': (loc) => loc.errorNoChangesToPublish,
    'published decks cannot be deleted': (loc) =>
        loc.errorPublishedDeckCannotDelete,
    'cannot modify facts on an imported deck': (loc) =>
        loc.errorCannotModifyImportedDeck,
    'tag name already exists': (loc) => loc.tagAlreadyExists,
    'maximum number of tags reached': (loc) => loc.tagLimitReached,
    'deck_not_found': (loc) => loc.discoveryNotFound,
    'import_failed': (loc) => loc.discoveryImportFailed,

    // Client-side fallbacks (not from API envelope)
    'Could not create tag': (loc) => loc.tagCreateFailed,
    'Could not update tag': (loc) => loc.tagUpdateFailed,
    'Could not delete tag': (loc) => loc.tagDeleteFailed,
    'Tag name cannot be empty': (loc) => loc.tagNameRequired,
    'Login failed': (loc) => loc.errorLoginFailed,
    'Publish failed': (loc) => loc.publishDeckFailed,
    'submit_card_failed': (loc) => loc.errorSubmitCardFailed,
    'delete_card_failed': (loc) => loc.deleteCardFailed,

    'User not found': (loc) => loc.apiUserNotFound,
    'Invalid request payload': (loc) => loc.apiInvalidRequestPayload,
    'Deck not found': (loc) => loc.apiDeckNotFound,
    'Not authorized to access this deck': (loc) =>
        loc.apiNotAuthorizedAccessDeck,
    'Not authorized to modify this deck': (loc) =>
        loc.apiNotAuthorizedModifyDeck,
    'Not authorized to delete this deck': (loc) =>
        loc.apiNotAuthorizedDeleteDeck,
    'Not authorized': (loc) => loc.apiNotAuthorized,
    'Error retrieving deck': (loc) => loc.apiServerRetrieveDeck,
    'Error parsing deck data': (loc) => loc.apiServerParseDeck,
    'Username, password, and email are required': (loc) =>
        loc.apiRegisterFieldsRequired,
    'Username and password are required': (loc) => loc.apiLoginFieldsRequired,
    'Error checking username': (loc) => loc.apiServerCheckUsername,
    'Error checking email': (loc) => loc.apiServerCheckEmail,
    'Could not hash password': (loc) => loc.apiServerHashPassword,
    'Error serializing user data': (loc) => loc.apiServerSerializeUser,
    'Error creating user': (loc) => loc.apiServerCreateUser,
    'Error retrieving user data': (loc) => loc.apiServerRetrieveUser,
    'Error parsing user data': (loc) => loc.apiServerParseUser,
    'Could not generate token': (loc) => loc.apiServerGenerateToken,
    'Error logging out': (loc) => loc.apiServerLogout,
    'Email is required': (loc) => loc.apiEmailRequired,
    'Error generating reset token': (loc) => loc.apiServerGenerateResetToken,
    'Error storing reset token': (loc) => loc.apiServerStoreResetToken,
    'Token and new password are required': (loc) => loc.apiResetFieldsRequired,
    'Error validating reset token': (loc) => loc.apiServerValidateResetToken,
    'Error resetting password': (loc) => loc.apiServerResetPassword,
    'Error retrieving user profile': (loc) => loc.apiServerRetrieveProfile,
    'Deck name is required': (loc) => loc.apiDeckNameRequired,
    'fields must contain at least one column name': (loc) =>
        loc.apiDeckFieldsRequired,
    'each column name must be non-empty': (loc) => loc.apiDeckFieldNameEmpty,
    'Rate is required and must be between 1 and 1000': (loc) =>
        loc.apiDeckRateRequired,
    'provide either tags or tag_ids, not both': (loc) => loc.apiTagsOrTagIds,
    'deck description contains invalid characters': (loc) =>
        loc.apiDeckDescriptionInvalidChars,
    'deck description must be at most 500 characters': (loc) =>
        loc.apiDeckDescriptionTooLong,
    'tag id is required': (loc) => loc.apiTagIdRequired,
    'maximum tags per deck reached': (loc) => loc.apiMaxTagsPerDeck,
    'tag name is required': (loc) => loc.apiTagNameRequired,
    'tag name contains invalid characters': (loc) => loc.apiTagNameInvalidChars,
    'tag name is too long': (loc) => loc.apiTagNameTooLong,
    'tag not found': (loc) => loc.apiTagNotFound,
    'Error resolving deck tags': (loc) => loc.apiServerResolveDeckTags,
    'Error generating deck ID': (loc) => loc.apiServerGenerateDeckId,
    'Failed to marshal deck': (loc) => loc.apiServerMarshalDeck,
    'Error creating deck': (loc) => loc.apiServerCreateDeck,
    'Error preparing deck media storage': (loc) =>
        loc.apiServerPrepareDeckMedia,
    'Rate value must be between 1 and 1000': (loc) => loc.apiDeckRateRange,
    'invalid visibility': (loc) => loc.apiInvalidVisibility,
    'cannot change visibility after publishing': (loc) =>
        loc.apiCannotChangeVisibilityAfterPublish,
    'cannot change visibility on an imported deck': (loc) =>
        loc.apiCannotChangeVisibilityImported,
    'cannot change fields on an imported deck': (loc) =>
        loc.apiCannotChangeFieldsImported,
    'cannot change name on an imported deck': (loc) =>
        loc.apiCannotChangeNameImported,
    'cannot change description on an imported deck': (loc) =>
        loc.apiCannotChangeDescriptionImported,
    'Rate is required for imported deck updates': (loc) =>
        loc.apiImportedDeckRateRequired,
    'Error serializing deck data': (loc) => loc.apiServerSerializeDeck,
    'Error loading cards for deck': (loc) => loc.apiServerLoadCards,
    'Error rescheduling unseen cards': (loc) => loc.apiServerRescheduleCards,
    'Error updating deck and cards': (loc) => loc.apiServerUpdateDeckCards,
    'Error updating deck': (loc) => loc.apiServerUpdateDeck,
    'Error loading facts for deck deletion': (loc) =>
        loc.apiServerLoadFactsDelete,
    'Error cleaning up tags': (loc) => loc.apiServerCleanupTags,
    'Error deleting deck': (loc) => loc.apiServerDeleteDeck,
    'Error revoking import media grants': (loc) =>
        loc.apiServerRevokeMediaGrants,
    'Error retrieving decks': (loc) => loc.apiServerRetrieveDecks,
    'Error retrieving deck data': (loc) => loc.apiServerRetrieveDeckData,
    'Error listing catalog decks': (loc) => loc.apiServerListCatalog,
    'Error loading catalog deck': (loc) => loc.apiServerLoadCatalogDeck,
    'first publish requires visibility public': (loc) =>
        loc.apiFirstPublishPublic,
    'cannot publish an imported deck': (loc) => loc.apiCannotPublishImported,
    'source_deck_id is required': (loc) => loc.apiSourceDeckIdRequired,
    'maximum fact tags per deck reached': (loc) => loc.apiMaxFactTagsPerDeck,
    'updates are only available for imported decks': (loc) =>
        loc.apiUpdatesImportedOnly,
    'not an imported deck': (loc) => loc.apiNotImportedDeck,
    'source deck missing': (loc) => loc.apiSourceDeckMissing,
    'Facts array is required': (loc) => loc.apiFactsArrayRequired,
    'Invalid operation. Supported: append, prepend, shuffle, spread.': (loc) =>
        loc.apiInvalidFactOperation,
    'Deck rate must be at least 1 to add facts': (loc) =>
        loc.apiDeckRateMinForFacts,
    'at least one fact is required': (loc) => loc.apiAtLeastOneFact,
    'template invalid': (loc) => loc.apiTemplateInvalid,
    'at least one entry must have text, audio, image, video, or json': (loc) =>
        loc.apiEntryContentRequired,
    'Fact not found': (loc) => loc.apiFactNotFound,
    'Error adding facts and cards': (loc) => loc.apiServerAddFacts,
    'Error merging facts into deck': (loc) => loc.apiServerMergeFacts,
    'Error serializing fact data': (loc) => loc.apiServerSerializeFact,
    'Error rebuilding card template': (loc) => loc.apiServerRebuildTemplate,
    'Error retrieving cards': (loc) => loc.apiServerRetrieveCards,
    'Error serializing card data': (loc) => loc.apiServerSerializeCard,
    'Error updating fact': (loc) => loc.apiServerUpdateFact,
    'Error removing fact tags': (loc) => loc.apiServerRemoveFactTags,
    'Error removing fact from deck': (loc) => loc.apiServerRemoveFact,
    'Error deleting fact': (loc) => loc.apiServerDeleteFact,
    'Error retrieving facts': (loc) => loc.apiServerRetrieveFacts,
    'Error retrieving fact tags': (loc) => loc.apiServerRetrieveFactTags,
    'Error checking fact existence': (loc) => loc.apiServerCheckFact,
    'invalid used_on filter': (loc) => loc.apiInvalidUsedOnFilter,
    'used_on is required when deck_id is set': (loc) => loc.apiUsedOnRequired,
    'deck_id is required when used_on is fact': (loc) =>
        loc.apiDeckIdRequiredForFact,
    'Error retrieving tags': (loc) => loc.apiServerRetrieveTags,
    'Error checking tags': (loc) => loc.apiServerCheckTags,
    'Error checking tag name': (loc) => loc.apiServerCheckTagName,
    'Error generating tag id': (loc) => loc.apiServerGenerateTagId,
    'Error creating tag': (loc) => loc.apiServerCreateTag,
    'Error serializing tag': (loc) => loc.apiServerSerializeTag,
    'Error saving tag': (loc) => loc.apiServerSaveTag,
    'Error associating tag': (loc) => loc.apiServerAssociateTag,
    'Error removing tag': (loc) => loc.apiServerRemoveTag,
    'Error loading tags': (loc) => loc.apiServerLoadTags,
    'fact_id is required': (loc) => loc.apiFactIdRequired,
    'template is required (e.g. [[0],[1]] or [[1],[0]])': (loc) =>
        loc.apiTemplateRequired,
    'template already exists for this fact': (loc) => loc.apiTemplateExists,
    'Card not found': (loc) => loc.apiCardNotFound,
    'card_id is required': (loc) => loc.apiCardIdRequired,
    'card_id must be a non-empty string': (loc) => loc.apiCardIdEmpty,
    'Must include either "interval" or "hidden" field': (loc) =>
        loc.apiIntervalOrHiddenRequired,
    'Cannot send both interval and hidden in the same request': (loc) =>
        loc.apiIntervalAndHiddenConflict,
    'last_review is required with interval updates': (loc) =>
        loc.apiLastReviewRequired,
    'last_review is only valid with interval updates': (loc) =>
        loc.apiLastReviewIntervalOnly,
    'last_review must be a numeric unix timestamp': (loc) =>
        loc.apiLastReviewNumeric,
    'last_review must be a whole number (unix timestamp)': (loc) =>
        loc.apiLastReviewWhole,
    'last_review must be a positive unix timestamp': (loc) =>
        loc.apiLastReviewPositive,
    'interval must be a number': (loc) => loc.apiIntervalNumeric,
    'interval must be a positive number': (loc) => loc.apiIntervalPositive,
    'hidden must be a boolean': (loc) => loc.apiHiddenBoolean,
    'Unsupported operation, supported operations: interval, visibility':
        (loc) => loc.apiUnsupportedCardOperation,
    'Card template invalid for fact': (loc) =>
        loc.apiCardTemplateInvalidForFact,
    'Error updating card in Redis': (loc) => loc.apiServerUpdateCardRedis,
    'Error checking card membership': (loc) => loc.apiServerCheckCardMembership,
    'Error parsing card data': (loc) => loc.apiServerParseCard,
    'Error updating card': (loc) => loc.apiServerUpdateCard,
    'Error checking card': (loc) => loc.apiServerCheckCard,
    'Error deleting card': (loc) => loc.apiServerDeleteCard,
    'Error generating card ID': (loc) => loc.apiServerGenerateCardId,
    'Error merging card into deck': (loc) => loc.apiServerMergeCard,
    'Error adding card': (loc) => loc.apiServerAddCard,
    'Error parsing fact data': (loc) => loc.apiServerParseFact,
    'Invalid multipart form': (loc) => loc.apiInvalidMultipart,
    'Missing or invalid file field': (loc) => loc.apiMissingFileField,
    'deck_id is required': (loc) => loc.apiMediaDeckIdRequired,
    'client_id already in use': (loc) => loc.apiClientIdInUse,
    'File too large': (loc) => loc.apiFileTooLarge,
    'Unsupported media type': (loc) => loc.apiUnsupportedMediaType,
    'Invalid JSON document': (loc) => loc.apiInvalidJsonDocument,
    'Media storage not configured': (loc) => loc.apiMediaStorageNotConfigured,
    'Failed to check client_id': (loc) => loc.apiFailedCheckClientId,
    'Failed to verify deck': (loc) => loc.apiFailedVerifyDeck,
    'Failed to read file': (loc) => loc.apiFailedReadFile,
    'Failed to generate ID': (loc) => loc.apiFailedGenerateId,
    'Failed to prepare media storage': (loc) => loc.apiFailedPrepareMedia,
    'Failed to store file': (loc) => loc.apiFailedStoreFile,
    'Failed to save metadata': (loc) => loc.apiFailedSaveMetadata,
    'version query parameter v is required when multiple import grants exist for this media':
        (loc) => loc.apiMediaVersionRequired,
    'Access denied': (loc) => loc.apiAccessDenied,
    'Media not found': (loc) => loc.apiMediaNotFound,
    'Media file not found': (loc) => loc.apiMediaFileNotFound,
    'Failed to list media': (loc) => loc.apiFailedListMedia,
    'Failed to load media': (loc) => loc.apiFailedLoadMedia,
    'contributions are only available on imported decks': (loc) =>
        loc.apiFeedbackImportedOnly,
    'source deck is not published': (loc) => loc.apiFeedbackSourceNotPublished,
    'message must be between 1 and 2000 characters': (loc) =>
        loc.apiFeedbackMessageLength,
    'entry_index out of range': (loc) => loc.apiEntryIndexOutOfRange,
    'proposed_entries must have content': (loc) =>
        loc.apiProposedEntriesContent,
    'proposed_entries length must match snapshot fact': (loc) =>
        loc.apiProposedEntriesLength,
    'proposed_entries must differ from snapshot': (loc) =>
        loc.apiProposedEntriesDiffer,
    'fact not in pinned snapshot': (loc) => loc.apiFactNotInSnapshot,
    'deck not found': (loc) => loc.apiFeedbackDeckNotFound,
    'fact not found': (loc) => loc.apiFeedbackFactNotFound,
    'daily contribution limit exceeded': (loc) => loc.apiFeedbackDailyLimit,
    'contribution inbox is only available on source decks': (loc) =>
        loc.apiFeedbackInboxSourceOnly,
    'invalid status': (loc) => loc.apiInvalidFeedbackStatus,
    'contribution not found': (loc) => loc.apiFeedbackNotFound,
    'proposed_entries required to accept': (loc) =>
        loc.apiProposedEntriesRequiredAccept,
    'fact not found on source deck': (loc) => loc.apiFactNotOnSourceDeck,
    'report cannot be accepted': (loc) => loc.apiProposedEntriesRequiredAccept,
    'Bad certificate': (loc) => loc.apiBadCertificate,
    'Bad response': (loc) => loc.apiBadResponse,
    'Request cancel': (loc) => loc.apiRequestCancel,
    'Unknown error': (loc) => loc.apiUnknownError,
  };

  static final _serverErrorPrefixes = ['Error ', 'Failed to ', 'Could not '];

  static String resolve(String? rawMsg, AppLocalizations loc) {
    final msg = rawMsg?.trim() ?? '';
    if (msg.isEmpty) return loc.errorUnknown;

    final exact = _exact[msg];
    if (exact != null) return exact(loc);

    final patterned = _resolvePattern(msg, loc);
    if (patterned != null) return patterned;

    if (_isServerError(msg)) return loc.errorServerError;

    return msg;
  }

  static bool _isServerError(String msg) {
    for (final prefix in _serverErrorPrefixes) {
      if (msg.startsWith(prefix)) return true;
    }
    return false;
  }

  static String? _resolvePattern(String msg, AppLocalizations loc) {
    final factEntryRequired = RegExp(
      r'^fact (\d+): at least one entry is required$',
    );
    final m1 = factEntryRequired.firstMatch(msg);
    if (m1 != null) {
      return loc.apiFactEntryRequired(int.parse(m1.group(1)!));
    }

    final factEntryContent = RegExp(
      r'^fact (\d+): at least one entry must have text, audio, image, video, or json$',
    );
    final m2 = factEntryContent.firstMatch(msg);
    if (m2 != null) {
      return loc.apiFactEntryContent(int.parse(m2.group(1)!));
    }

    if (msg.startsWith(
      'invalid template: must be [[front indices], [back indices]]',
    )) {
      return loc.apiInvalidTemplate;
    }

    final negativeInterval = RegExp(
      r'^something went wrong, interval is 0 or negative, try delete fact id: (.+)$',
    );
    final m3 = negativeInterval.firstMatch(msg);
    if (m3 != null) {
      return loc.apiNegativeInterval(m3.group(1)!);
    }

    if (msg.startsWith('unsupported media type: ')) {
      return loc.apiUnsupportedMediaMime(
        msg.substring('unsupported media type: '.length),
      );
    }

    if (msg.startsWith('invalid target version')) {
      return loc.apiInvalidTargetVersion;
    }

    return null;
  }
}

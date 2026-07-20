// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rete';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginPageTitle => 'Login';

  @override
  String get email => 'Email';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get passwordNotMatch => 'Passwords do not match';

  @override
  String get registerSuccess => 'Register Success';

  @override
  String get loginSuccess => 'Login Success';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordSent => 'Reset Password Sent';

  @override
  String get home => 'Home';

  @override
  String get decks => 'Decks';

  @override
  String get profile => 'Profile';

  @override
  String get noDecksAvailable => 'No decks available';

  @override
  String get retry => 'Retry';

  @override
  String get words => 'words';

  @override
  String get progress => 'Progress';

  @override
  String get cards => 'cards';

  @override
  String get newCards => 'New';

  @override
  String get review => 'Review';

  @override
  String get facts => 'Facts';

  @override
  String openDeck(String deckName) {
    return 'Open deck: $deckName';
  }

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get changeTheme => 'Change Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get totalCards => 'Total';

  @override
  String get dueCards => 'Due';

  @override
  String get learned => 'Learned';

  @override
  String get noCardsInDeck => 'No cards in this deck';

  @override
  String get startLearning => 'Start Learning';

  @override
  String get allCaughtUp => 'All Caught Up!';

  @override
  String get noCardsForTagFilter => 'No cards with this tag';

  @override
  String noCardsForTagFilterNamed(String tagName) {
    return 'No cards with tag \"$tagName\"';
  }

  @override
  String get clearTagFilter => 'Clear filter';

  @override
  String startLearningDeck(String deckName) {
    return 'Start learning: $deckName';
  }

  @override
  String get showAnswer => 'Show Answer';

  @override
  String get hard => 'Hard';

  @override
  String get good => 'Good';

  @override
  String get easy => 'Easy';

  @override
  String get backToDeck => 'Back to Deck';

  @override
  String get viewCards => 'View';

  @override
  String get learnButton => 'Learn';

  @override
  String get manage => 'Manage';

  @override
  String get createDeck => 'Create Deck';

  @override
  String get createInputDeckName => 'Deck Name';

  @override
  String get createInputDeckNameHint => 'Set a name for your deck';

  @override
  String get deckEditorFieldHint => 'e.g. English';

  @override
  String get deckEditorFieldHintSecond => 'e.g. Japanese';

  @override
  String get deckEditorAddFieldTooltip => 'Add column header';

  @override
  String get deckCreateAddField => 'Add a new field';

  @override
  String get deckEditorRemoveFieldTooltip => 'Remove column header';

  @override
  String get deckEditorNameRequired => 'Please enter a deck name';

  @override
  String get deckEditorMinTwoFields =>
      'Add another column header — at least two columns are required';

  @override
  String get deckEditorFieldNamesRequired => 'Fill in every column header';

  @override
  String get language => 'Language';

  @override
  String get rate => 'Rate';

  @override
  String get cardsPerDay => 'cards per day';

  @override
  String get slow => 'Slow';

  @override
  String get fast => 'Fast';

  @override
  String get unidirectional => 'Unidirectional';

  @override
  String get bidirectional => 'Bidirectional';

  @override
  String get template => 'Template';

  @override
  String get next => 'Next';

  @override
  String get noNetworkConnection =>
      'No network connection. Please check your internet settings.';

  @override
  String get reviewAgain => 'Review Again';

  @override
  String get editDeck => 'Edit Deck';

  @override
  String get editFact => 'Edit Fact';

  @override
  String get hideCard => 'Hide Card';

  @override
  String get deleteCard => 'Delete Card';

  @override
  String get deleteCardConfirm =>
      'Only this card will be removed. The fact and other cards for it stay in the deck.';

  @override
  String get deleteCardFailed => 'Could not delete card';

  @override
  String get deleteDeck => 'Delete Deck';

  @override
  String get noCardsInThisDeck => 'No cards in this deck';

  @override
  String get save => 'Save';

  @override
  String newCardEveryMinutes(int interval) {
    return 'Introduce a new card every $interval minutes';
  }

  @override
  String get addFact => 'Add fact';

  @override
  String get addFactAddRow => 'Add row';

  @override
  String get addFactRemoveRow => 'Remove row';

  @override
  String get addFactFieldNameHint => 'Field name (optional)';

  @override
  String get addFactContentHint => 'Text (optional if you add media)';

  @override
  String get addFactAttachImage => 'Image';

  @override
  String get addFactAttachVideo => 'Video';

  @override
  String get addFactAttachAudio => 'Audio';

  @override
  String get addFactClearAttachment => 'Clear';

  @override
  String get addFactAttachMediaTooltip =>
      'Attach image, video, or audio. Long press to remove.';

  @override
  String get addFactGalleryMediaTooltip =>
      'Choose photo or video from your library. Long press to remove.';

  @override
  String get addFactRecordAudioTooltip =>
      'Record audio with the microphone. Tap again to stop and attach. Long press while recording to discard.';

  @override
  String get addFactStopRecordingTooltip =>
      'Stop recording and attach audio to this field';

  @override
  String get addFactMicPermissionDenied =>
      'Microphone access is required to record audio.';

  @override
  String get addFactRecordingFailed => 'Could not record audio. Try again.';

  @override
  String get addFactSubmit => 'Save fact';

  @override
  String get addFactUploadFailed => 'Upload failed. Try again.';

  @override
  String addFactFileTooLarge(int maxMb) {
    return 'File is too large (max $maxMb MB).';
  }

  @override
  String get addFactEntryNeedsContent =>
      'Each row needs text or at least one attachment.';

  @override
  String get addFactFileTypeNotSupported => 'This file type is not supported.';

  @override
  String get addFactFileWrongSlot =>
      'Pick a file that matches this attachment type.';

  @override
  String get addFactFailed => 'Could not add fact';

  @override
  String get addFactSuccess => 'Fact added';

  @override
  String addFactFieldFallback(int number) {
    return 'Field $number';
  }

  @override
  String get addFactFieldShortLabel => 'Field';

  @override
  String get addFactPasteFromClipboard => 'Paste from clipboard';

  @override
  String get cardAudioUnavailable => 'Audio unavailable';

  @override
  String get font => 'Font';

  @override
  String get deckFontSheetTitle => 'Font & ruby';

  @override
  String get deckFontMainSizeLabel => 'Main text size';

  @override
  String get deckFontRubySizeLabel => 'Ruby text size';

  @override
  String get deckFontPreviewCaption => 'Preview';

  @override
  String get deckFontTabFront => 'Front';

  @override
  String get deckFontTabBack => 'Back';

  @override
  String get tags => 'Tags';

  @override
  String get tagLabel => 'Tag';

  @override
  String get addTag => 'Add tag';

  @override
  String get createTag => 'Create tag';

  @override
  String get editTag => 'Edit tag';

  @override
  String get deleteTag => 'Delete tag';

  @override
  String get tagName => 'Tag name';

  @override
  String get tagDescription => 'Description (optional)';

  @override
  String get tagNameHint => 'e.g. Grammar, Verbs…';

  @override
  String get tagNameRequired => 'Please enter a tag name';

  @override
  String get tagCreated => 'Tag created';

  @override
  String get tagUpdated => 'Tag updated';

  @override
  String get tagDeleted => 'Tag deleted';

  @override
  String get tagCreateFailed => 'Could not create tag';

  @override
  String get tagUpdateFailed => 'Could not update tag';

  @override
  String get tagDeleteFailed => 'Could not delete tag';

  @override
  String get tagAlreadyExists => 'A tag with this name already exists';

  @override
  String get tagLimitReached => 'You have reached the maximum of 1000 tags';

  @override
  String get noTags => 'No tags yet';

  @override
  String get manageTags => 'Manage tags';

  @override
  String get tagPickerTitle => 'Select tags';

  @override
  String get tagPickerSearchHint => 'Search tags…';

  @override
  String get tagPickerDone => 'Done';

  @override
  String tagPickerNoMatch(String query) {
    return 'No tags matching \"$query\"';
  }

  @override
  String get tagPickerEmptyHint =>
      'No tags yet. Tap below to create the first one.';

  @override
  String get filterAll => 'All';

  @override
  String get studyTagFilterTitle => 'Study by tag';

  @override
  String get tagFacts => 'Facts';

  @override
  String get noFactsInTag => 'No facts in this tag yet';

  @override
  String get discoveryTab => 'Discover';

  @override
  String get discoverySearchHint => 'Search decks, authors, tags';

  @override
  String get discoveryFilterLatest => 'Latest';

  @override
  String get discoveryFilterFavorites => 'Favorites';

  @override
  String get discoveryEmpty => 'No public decks yet';

  @override
  String get discoveryFavoritesEmpty => 'No favorited decks';

  @override
  String get discoveryImport => 'Import';

  @override
  String get discoveryImporting => 'Importing…';

  @override
  String get discoveryImported => 'Imported';

  @override
  String get discoveryGoStudy => 'Go study';

  @override
  String get discoveryImportSuccess => 'Added to your decks';

  @override
  String get discoveryFavorite => 'Favorite';

  @override
  String get discoveryUnfavorite => 'Unfavorite';

  @override
  String discoveryYearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String discoveryMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String discoveryDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String discoveryHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get discoveryJustNow => 'Just now';

  @override
  String get discoveryDeckUnavailable => 'Unavailable';

  @override
  String discoveryCardSemantics(String name, String factCount, String owner) {
    return '$name, $factCount, by $owner';
  }

  @override
  String get discoveryImportedBadgeSemantics => 'Imported to my decks';

  @override
  String get discoveryUnavailableBadgeSemantics => 'This deck is unavailable';

  @override
  String discoveryLoginToAccessTab(String tabLabel) {
    return 'Log in to access $tabLabel.';
  }

  @override
  String get deckOptionsTooltip => 'Deck options';

  @override
  String get discoveryNotFound => 'Deck not found or no longer available';

  @override
  String get discoveryImportSelf => 'You can\'t import your own deck';

  @override
  String get discoveryImportDuplicate => 'Already imported this deck';

  @override
  String get discoveryImportFailed => 'Import failed. Please try again.';

  @override
  String get discoveryLoginToImport => 'Sign in to import';

  @override
  String get discoveryRetry => 'Retry';

  @override
  String get publishDeck => 'Publish Deck';

  @override
  String get publishDeckHint =>
      'Once published, others can discover and import your deck in the Discovery tab.';

  @override
  String get publishDeckAction => 'Publish';

  @override
  String get publishingDeck => 'Publishing…';

  @override
  String get publishDeckSuccess => 'Published!';

  @override
  String get publishDeckFailed => 'Failed to publish. Please try again.';

  @override
  String get publishDeckAlreadyPublished => 'Published';

  @override
  String get publishDeckUpdate => 'Update Published Version';

  @override
  String get errorUnknown => 'An unexpected error occurred';

  @override
  String get authInvalidCredentials => 'Invalid username or password';

  @override
  String get authUsernameAlreadyExists => 'Username is already taken';

  @override
  String get authEmailAlreadyInUse => 'Email is already in use';

  @override
  String get authSessionExpired => 'Session expired. Please log in again.';

  @override
  String get authTokenRequired => 'Please log in to continue';

  @override
  String get authResetTokenInvalid => 'Reset link is invalid or expired';

  @override
  String get errorLoginFailed => 'Login failed. Please try again.';

  @override
  String get errorRegisterFailed => 'Registration failed. Please try again.';

  @override
  String get errorPublishedDeckCannotDelete =>
      'Published decks cannot be deleted';

  @override
  String get errorNoChangesToPublish => 'No changes to publish';

  @override
  String get errorSourceDeckNotImportable =>
      'This deck is not available for import';

  @override
  String get errorCannotImportImportedDeck =>
      'Cannot re-import an already imported deck';

  @override
  String get errorSourceDeckNotPublished =>
      'This deck has not been published yet';

  @override
  String get errorCannotModifyImportedDeck =>
      'Imported decks cannot be modified';

  @override
  String get discoveryDetailFields => 'Fields';

  @override
  String get discoveryDetailDescription => 'Description';

  @override
  String discoveryDetailFactCount(int count) {
    return '$count cards';
  }

  @override
  String get imageLoadFailed => 'Load failed';

  @override
  String get homeDailyGoal => 'Daily Goal';

  @override
  String get homeLearningPath => 'Learning Path';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTodayFocus => 'Today Focus';

  @override
  String get homeTodayFocusText =>
      'Finish one review round first, then add new facts from your study notes.';

  @override
  String get apiUserNotFound => 'User not found';

  @override
  String get apiInvalidRequestPayload => 'Invalid request. Please try again.';

  @override
  String get apiDeckNotFound => 'Deck not found';

  @override
  String get apiNotAuthorizedAccessDeck =>
      'You are not allowed to access this deck';

  @override
  String get apiNotAuthorizedModifyDeck =>
      'You are not allowed to modify this deck';

  @override
  String get apiNotAuthorizedDeleteDeck =>
      'You are not allowed to delete this deck';

  @override
  String get apiNotAuthorized => 'You are not authorized';

  @override
  String get apiServerRetrieveDeck => 'Could not load deck. Please try again.';

  @override
  String get apiServerParseDeck => 'Deck data is corrupted. Please try again.';

  @override
  String get apiRegisterFieldsRequired =>
      'Username, password, and email are required';

  @override
  String get apiLoginFieldsRequired => 'Username and password are required';

  @override
  String get apiServerCheckUsername =>
      'Could not verify username. Please try again.';

  @override
  String get apiServerCheckEmail => 'Could not verify email. Please try again.';

  @override
  String get apiServerHashPassword =>
      'Could not process password. Please try again.';

  @override
  String get apiServerSerializeUser =>
      'Could not save user data. Please try again.';

  @override
  String get apiServerCreateUser =>
      'Could not create account. Please try again.';

  @override
  String get apiServerRetrieveUser =>
      'Could not load user data. Please try again.';

  @override
  String get apiServerParseUser => 'User data is corrupted. Please try again.';

  @override
  String get apiServerGenerateToken => 'Could not sign in. Please try again.';

  @override
  String get apiServerLogout => 'Could not log out. Please try again.';

  @override
  String get apiEmailRequired => 'Email is required';

  @override
  String get apiServerGenerateResetToken =>
      'Could not send reset email. Please try again.';

  @override
  String get apiServerStoreResetToken =>
      'Could not process reset request. Please try again.';

  @override
  String get apiResetFieldsRequired =>
      'Reset token and new password are required';

  @override
  String get apiServerValidateResetToken =>
      'Could not validate reset link. Please try again.';

  @override
  String get apiServerResetPassword =>
      'Could not reset password. Please try again.';

  @override
  String get apiServerRetrieveProfile =>
      'Could not load profile. Please try again.';

  @override
  String get apiDeckNameRequired => 'Deck name is required';

  @override
  String get apiDeckFieldsRequired => 'At least one column name is required';

  @override
  String get apiDeckFieldNameEmpty => 'Each column name must be non-empty';

  @override
  String get apiDeckRateRequired =>
      'Daily new-card rate must be between 1 and 1000';

  @override
  String get apiTagsOrTagIds => 'Provide either tags or tag IDs, not both';

  @override
  String get apiDeckDescriptionInvalidChars =>
      'Deck description contains invalid characters';

  @override
  String get apiDeckDescriptionTooLong =>
      'Deck description must be at most 500 characters';

  @override
  String get apiTagIdRequired => 'Tag ID is required';

  @override
  String get apiMaxTagsPerDeck => 'Maximum tags per deck reached';

  @override
  String get apiTagNameRequired => 'Tag name is required';

  @override
  String get apiTagNameInvalidChars => 'Tag name contains invalid characters';

  @override
  String get apiTagNameTooLong => 'Tag name is too long (max 50 characters)';

  @override
  String get apiTagNotFound => 'Tag not found';

  @override
  String get apiServerResolveDeckTags =>
      'Could not resolve deck tags. Please try again.';

  @override
  String get apiServerGenerateDeckId =>
      'Could not create deck. Please try again.';

  @override
  String get apiServerMarshalDeck => 'Could not save deck. Please try again.';

  @override
  String get apiServerCreateDeck => 'Could not create deck. Please try again.';

  @override
  String get apiServerPrepareDeckMedia =>
      'Could not prepare media storage. Please try again.';

  @override
  String get apiDeckRateRange =>
      'Daily new-card rate must be between 1 and 1000';

  @override
  String get apiInvalidVisibility => 'Invalid visibility setting';

  @override
  String get apiCannotChangeVisibilityAfterPublish =>
      'Cannot change visibility after publishing';

  @override
  String get apiCannotChangeVisibilityImported =>
      'Cannot change visibility on an imported deck';

  @override
  String get apiCannotChangeFieldsImported =>
      'Cannot change fields on an imported deck';

  @override
  String get apiCannotChangeNameImported =>
      'Cannot change name on an imported deck';

  @override
  String get apiCannotChangeDescriptionImported =>
      'Cannot change description on an imported deck';

  @override
  String get apiImportedDeckRateRequired =>
      'Daily new-card rate is required for imported deck updates';

  @override
  String get apiServerSerializeDeck => 'Could not save deck. Please try again.';

  @override
  String get apiServerLoadCards => 'Could not load cards. Please try again.';

  @override
  String get apiServerRescheduleCards =>
      'Could not reschedule cards. Please try again.';

  @override
  String get apiServerUpdateDeckCards =>
      'Could not update deck. Please try again.';

  @override
  String get apiServerUpdateDeck => 'Could not update deck. Please try again.';

  @override
  String get apiServerLoadFactsDelete =>
      'Could not delete deck. Please try again.';

  @override
  String get apiServerCleanupTags => 'Could not delete deck. Please try again.';

  @override
  String get apiServerDeleteDeck => 'Could not delete deck. Please try again.';

  @override
  String get apiServerRevokeMediaGrants =>
      'Could not delete deck. Please try again.';

  @override
  String get apiServerRetrieveDecks =>
      'Could not load decks. Please try again.';

  @override
  String get apiServerRetrieveDeckData =>
      'Could not load deck. Please try again.';

  @override
  String get apiServerListCatalog =>
      'Could not load catalog. Please try again.';

  @override
  String get apiServerLoadCatalogDeck =>
      'Could not load deck details. Please try again.';

  @override
  String get apiFirstPublishPublic =>
      'First publish requires public visibility';

  @override
  String get apiCannotPublishImported => 'Imported decks cannot be published';

  @override
  String get apiSourceDeckIdRequired => 'Source deck ID is required';

  @override
  String get apiMaxFactTagsPerDeck => 'Maximum fact tags per deck reached';

  @override
  String get apiUpdatesImportedOnly =>
      'Updates are only available for imported decks';

  @override
  String get apiNotImportedDeck => 'This is not an imported deck';

  @override
  String get apiSourceDeckMissing => 'Source deck is missing';

  @override
  String get apiFactsArrayRequired => 'Facts are required';

  @override
  String get apiInvalidFactOperation =>
      'Invalid operation. Supported: append, prepend, shuffle, spread.';

  @override
  String get apiDeckRateMinForFacts =>
      'Set daily new-card rate to at least 1 before adding facts';

  @override
  String get apiAtLeastOneFact => 'At least one fact is required';

  @override
  String get apiTemplateInvalid => 'Card template is invalid';

  @override
  String get apiEntryContentRequired =>
      'Each entry needs text, audio, image, video, or JSON';

  @override
  String get apiFactNotFound => 'Fact not found';

  @override
  String get apiServerAddFacts => 'Could not add facts. Please try again.';

  @override
  String get apiServerMergeFacts => 'Could not add facts. Please try again.';

  @override
  String get apiServerSerializeFact => 'Could not save fact. Please try again.';

  @override
  String get apiServerRebuildTemplate =>
      'Could not update card. Please try again.';

  @override
  String get apiServerRetrieveCards =>
      'Could not load cards. Please try again.';

  @override
  String get apiServerSerializeCard => 'Could not save card. Please try again.';

  @override
  String get apiServerUpdateFact => 'Could not update fact. Please try again.';

  @override
  String get apiServerRemoveFactTags =>
      'Could not update fact. Please try again.';

  @override
  String get apiServerRemoveFact => 'Could not remove fact. Please try again.';

  @override
  String get apiServerDeleteFact => 'Could not delete fact. Please try again.';

  @override
  String get apiServerRetrieveFacts =>
      'Could not load facts. Please try again.';

  @override
  String get apiServerRetrieveFactTags =>
      'Could not load fact tags. Please try again.';

  @override
  String get apiServerCheckFact => 'Could not verify fact. Please try again.';

  @override
  String get apiInvalidUsedOnFilter => 'Invalid filter value';

  @override
  String get apiUsedOnRequired => 'Filter type is required when deck ID is set';

  @override
  String get apiDeckIdRequiredForFact => 'Deck ID is required for fact filter';

  @override
  String get apiServerRetrieveTags => 'Could not load tags. Please try again.';

  @override
  String get apiServerCheckTags => 'Could not verify tags. Please try again.';

  @override
  String get apiServerCheckTagName =>
      'Could not verify tag name. Please try again.';

  @override
  String get apiServerGenerateTagId =>
      'Could not create tag. Please try again.';

  @override
  String get apiServerCreateTag => 'Could not create tag. Please try again.';

  @override
  String get apiServerSerializeTag => 'Could not save tag. Please try again.';

  @override
  String get apiServerSaveTag => 'Could not save tag. Please try again.';

  @override
  String get apiServerAssociateTag => 'Could not add tag. Please try again.';

  @override
  String get apiServerRemoveTag => 'Could not remove tag. Please try again.';

  @override
  String get apiServerLoadTags => 'Could not load tags. Please try again.';

  @override
  String get apiFactIdRequired => 'Fact ID is required';

  @override
  String get apiTemplateRequired => 'Card template is required';

  @override
  String get apiTemplateExists => 'A template already exists for this fact';

  @override
  String get apiCardNotFound => 'Card not found';

  @override
  String get apiCardIdRequired => 'Card ID is required';

  @override
  String get apiCardIdEmpty => 'Card ID must not be empty';

  @override
  String get apiIntervalOrHiddenRequired =>
      'Include either interval or hidden field';

  @override
  String get apiIntervalAndHiddenConflict =>
      'Cannot send both interval and hidden in one request';

  @override
  String get apiLastReviewRequired =>
      'last_review is required with interval updates';

  @override
  String get apiLastReviewIntervalOnly =>
      'last_review is only valid with interval updates';

  @override
  String get apiLastReviewNumeric =>
      'last_review must be a numeric Unix timestamp';

  @override
  String get apiLastReviewWhole =>
      'last_review must be a whole-number Unix timestamp';

  @override
  String get apiLastReviewPositive =>
      'last_review must be a positive Unix timestamp';

  @override
  String get apiIntervalNumeric => 'interval must be a number';

  @override
  String get apiIntervalPositive => 'interval must be a positive number';

  @override
  String get apiHiddenBoolean => 'hidden must be true or false';

  @override
  String get apiUnsupportedCardOperation =>
      'Supported operations: interval, visibility';

  @override
  String get apiCardTemplateInvalidForFact =>
      'Card template is invalid for this fact';

  @override
  String get apiServerUpdateCardRedis =>
      'Could not update card. Please try again.';

  @override
  String get apiServerCheckCardMembership =>
      'Could not verify card. Please try again.';

  @override
  String get apiServerParseCard => 'Card data is corrupted. Please try again.';

  @override
  String get apiServerUpdateCard => 'Could not update card. Please try again.';

  @override
  String get apiServerCheckCard => 'Could not verify card. Please try again.';

  @override
  String get apiServerDeleteCard => 'Could not delete card. Please try again.';

  @override
  String get apiServerGenerateCardId =>
      'Could not create card. Please try again.';

  @override
  String get apiServerMergeCard => 'Could not add card. Please try again.';

  @override
  String get apiServerAddCard => 'Could not add card. Please try again.';

  @override
  String get apiServerParseFact => 'Fact data is corrupted. Please try again.';

  @override
  String get apiInvalidMultipart => 'Invalid file upload';

  @override
  String get apiMissingFileField => 'No file selected or file field is invalid';

  @override
  String get apiMediaDeckIdRequired => 'Deck ID is required for media upload';

  @override
  String get apiClientIdInUse => 'Upload ID already in use. Please retry.';

  @override
  String get apiFileTooLarge => 'File is too large';

  @override
  String get apiUnsupportedMediaType => 'Unsupported file type';

  @override
  String get apiInvalidJsonDocument => 'Invalid JSON file';

  @override
  String get apiMediaStorageNotConfigured => 'Media storage is not available';

  @override
  String get apiFailedCheckClientId => 'Upload failed. Please try again.';

  @override
  String get apiFailedVerifyDeck => 'Could not verify deck. Please try again.';

  @override
  String get apiFailedReadFile => 'Could not read file. Please try again.';

  @override
  String get apiFailedGenerateId => 'Upload failed. Please try again.';

  @override
  String get apiFailedPrepareMedia => 'Upload failed. Please try again.';

  @override
  String get apiFailedStoreFile => 'Could not save file. Please try again.';

  @override
  String get apiFailedSaveMetadata =>
      'Could not save file info. Please try again.';

  @override
  String get apiMediaVersionRequired =>
      'Version parameter is required for this media';

  @override
  String get apiAccessDenied => 'Access denied';

  @override
  String get apiMediaNotFound => 'Media not found';

  @override
  String get apiMediaFileNotFound => 'Media file not found';

  @override
  String get apiFailedListMedia => 'Could not load media. Please try again.';

  @override
  String get apiFailedLoadMedia => 'Could not load media. Please try again.';

  @override
  String get apiFeedbackImportedOnly =>
      'Contributions are only available on imported decks';

  @override
  String get apiFeedbackSourceNotPublished => 'Source deck is not published';

  @override
  String get apiFeedbackMessageLength => 'Message must be 1–2000 characters';

  @override
  String get apiEntryIndexOutOfRange => 'Entry index is out of range';

  @override
  String get apiProposedEntriesContent => 'Proposed entries must have content';

  @override
  String get apiProposedEntriesLength =>
      'Proposed entries must match the fact length';

  @override
  String get apiProposedEntriesDiffer =>
      'Proposed entries must differ from the original';

  @override
  String get apiFactNotInSnapshot => 'Fact is not in the pinned snapshot';

  @override
  String get apiFeedbackDeckNotFound => 'Deck not found';

  @override
  String get apiFeedbackFactNotFound => 'Fact not found';

  @override
  String get apiFeedbackDailyLimit =>
      'Daily contribution limit reached. Try again tomorrow.';

  @override
  String get apiServerSubmitFeedback =>
      'Could not submit feedback. Please try again.';

  @override
  String get apiFeedbackInboxSourceOnly =>
      'Contribution inbox is only available on source decks';

  @override
  String get apiServerListFeedback =>
      'Could not load feedback. Please try again.';

  @override
  String get apiInvalidFeedbackStatus => 'Invalid feedback status';

  @override
  String get apiFeedbackNotFound => 'Contribution not found';

  @override
  String get apiServerUpdateFeedback =>
      'Could not update feedback. Please try again.';

  @override
  String get apiProposedEntriesRequiredAccept =>
      'Proposed entries are required to accept feedback';

  @override
  String get apiFactNotOnSourceDeck => 'Fact not found on source deck';

  @override
  String get apiReportCannotBeAccepted => 'Report cannot be accepted';

  @override
  String get apiServerAcceptFeedback =>
      'Could not accept feedback. Please try again.';

  @override
  String get apiBadCertificate => 'Secure connection failed';

  @override
  String get apiBadResponse => 'Unexpected server response';

  @override
  String get apiRequestCancel => 'Request was cancelled';

  @override
  String get apiUnknownError => 'An unexpected error occurred';

  @override
  String get errorServerError =>
      'Something went wrong. Please try again later.';

  @override
  String apiFactEntryRequired(int index) {
    return 'Fact $index: at least one entry is required';
  }

  @override
  String apiFactEntryContent(int index) {
    return 'Fact $index: each entry needs text, audio, image, video, or JSON';
  }

  @override
  String get apiInvalidTemplate => 'Invalid card template for this fact';

  @override
  String apiNegativeInterval(String factId) {
    return 'Something went wrong with this card. Try removing fact $factId.';
  }

  @override
  String apiUnsupportedMediaMime(String mime) {
    return 'Unsupported file type: $mime';
  }

  @override
  String get apiInvalidTargetVersion => 'Invalid target version';

  @override
  String get errorSubmitCardFailed =>
      'Could not save card progress. Please try again.';

  @override
  String get deckCheckUpdates => 'Check updates';

  @override
  String get deckSyncNow => 'Sync now';

  @override
  String get deckUpToDate => 'Already up to date';

  @override
  String get deckSyncSuccess => 'Deck synced';

  @override
  String deckUpdatesVersion(int source, int latest) {
    return 'Current v$source -> latest v$latest';
  }

  @override
  String deckUpdatesCounts(int added, int edited, int removed, int media) {
    return 'Added $added, edited $edited, removed $removed, media changes $media';
  }

  @override
  String get feedbackSubmit => 'Submit feedback';

  @override
  String get feedbackMessageHint => 'Describe the issue for this fact';

  @override
  String get feedbackMessageRequired => 'Please enter feedback message';

  @override
  String get feedbackSubmitSuccess => 'Feedback submitted';

  @override
  String get factEditNoEntries => 'This fact has no entries';
}

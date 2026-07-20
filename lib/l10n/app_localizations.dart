import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Rete'**
  String get appTitle;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Username input field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Login page title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginPageTitle;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Confirm password input field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Validation error message when fields are empty
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// Validation error message when passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordNotMatch;

  /// Success message after successful registration
  ///
  /// In en, this message translates to:
  /// **'Register Success'**
  String get registerSuccess;

  /// Success message after successful login
  ///
  /// In en, this message translates to:
  /// **'Login Success'**
  String get loginSuccess;

  /// Error message when login fails
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// Link text to navigate back to login page
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Reset password button text
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Confirmation message that password reset email was sent
  ///
  /// In en, this message translates to:
  /// **'Reset Password Sent'**
  String get resetPasswordSent;

  /// Home tab label in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Decks tab label in bottom navigation and deck list screen title
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get decks;

  /// Profile tab label in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Message shown when there are no decks
  ///
  /// In en, this message translates to:
  /// **'No decks available'**
  String get noDecksAvailable;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Words label
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get words;

  /// Progress label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Cards label
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cards;

  /// New cards label
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCards;

  /// Learn tab label in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// Facts label
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get facts;

  /// Message when opening a deck
  ///
  /// In en, this message translates to:
  /// **'Open deck: {deckName}'**
  String openDeck(String deckName);

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Change language setting
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Change theme setting
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeTheme;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// System theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Total cards count label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalCards;

  /// Due cards label
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueCards;

  /// Learned cards label
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get learned;

  /// Message shown when deck has no cards
  ///
  /// In en, this message translates to:
  /// **'No cards in this deck'**
  String get noCardsInDeck;

  /// Start learning button text
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get startLearning;

  /// Message when no cards to study
  ///
  /// In en, this message translates to:
  /// **'All Caught Up!'**
  String get allCaughtUp;

  /// Message when an active tag filter returns no due cards
  ///
  /// In en, this message translates to:
  /// **'No cards with this tag'**
  String get noCardsForTagFilter;

  /// Message when a named tag filter returns no due cards
  ///
  /// In en, this message translates to:
  /// **'No cards with tag \"{tagName}\"'**
  String noCardsForTagFilterNamed(String tagName);

  /// Button to clear the active study tag filter
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearTagFilter;

  /// Message when starting to learn a deck
  ///
  /// In en, this message translates to:
  /// **'Start learning: {deckName}'**
  String startLearningDeck(String deckName);

  /// Button text to show answer
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get showAnswer;

  /// Difficulty rating: Hard (in slider context)
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// Difficulty rating: Good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// Difficulty rating: Easy (in slider context)
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// Button to go back to deck
  ///
  /// In en, this message translates to:
  /// **'Back to Deck'**
  String get backToDeck;

  /// Button to view all cards
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewCards;

  /// Button to start learning
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnButton;

  /// Button to manage deck
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Create a deck
  ///
  /// In en, this message translates to:
  /// **'Create Deck'**
  String get createDeck;

  /// Label for deck name input field
  ///
  /// In en, this message translates to:
  /// **'Deck Name'**
  String get createInputDeckName;

  /// Hint text for deck name input field
  ///
  /// In en, this message translates to:
  /// **'Set a name for your deck'**
  String get createInputDeckNameHint;

  /// Hint for first (and other non-second) deck column header row
  ///
  /// In en, this message translates to:
  /// **'e.g. English'**
  String get deckEditorFieldHint;

  /// Hint for second deck column header row
  ///
  /// In en, this message translates to:
  /// **'e.g. Japanese'**
  String get deckEditorFieldHintSecond;

  /// Tooltip for button that adds another deck column header row
  ///
  /// In en, this message translates to:
  /// **'Add column header'**
  String get deckEditorAddFieldTooltip;

  /// Text button to add a new deck field in create-deck sheet
  ///
  /// In en, this message translates to:
  /// **'Add a new field'**
  String get deckCreateAddField;

  /// Tooltip for button that removes a deck column header row
  ///
  /// In en, this message translates to:
  /// **'Remove column header'**
  String get deckEditorRemoveFieldTooltip;

  /// Snackbar when saving deck without a name
  ///
  /// In en, this message translates to:
  /// **'Please enter a deck name'**
  String get deckEditorNameRequired;

  /// Snackbar when fewer than two column header rows exist
  ///
  /// In en, this message translates to:
  /// **'Add another column header — at least two columns are required'**
  String get deckEditorMinTwoFields;

  /// Snackbar when a column header is empty
  ///
  /// In en, this message translates to:
  /// **'Fill in every column header'**
  String get deckEditorFieldNamesRequired;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Rate label
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// Suffix next to deck new-card rate picker (number shown in picker only)
  ///
  /// In en, this message translates to:
  /// **'cards per day'**
  String get cardsPerDay;

  /// Slow speed label
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// Fast speed label
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// Unidirectional label
  ///
  /// In en, this message translates to:
  /// **'Unidirectional'**
  String get unidirectional;

  /// Bidirectional label
  ///
  /// In en, this message translates to:
  /// **'Bidirectional'**
  String get bidirectional;

  /// Template label
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Error message when there is no network connection
  ///
  /// In en, this message translates to:
  /// **'No network connection. Please check your internet settings.'**
  String get noNetworkConnection;

  /// Button text to start reviewing again
  ///
  /// In en, this message translates to:
  /// **'Review Again'**
  String get reviewAgain;

  /// Menu item to edit deck
  ///
  /// In en, this message translates to:
  /// **'Edit Deck'**
  String get editDeck;

  /// Menu item to edit a fact
  ///
  /// In en, this message translates to:
  /// **'Edit Fact'**
  String get editFact;

  /// Menu item to hide card
  ///
  /// In en, this message translates to:
  /// **'Hide Card'**
  String get hideCard;

  /// Menu item to delete current card
  ///
  /// In en, this message translates to:
  /// **'Delete Card'**
  String get deleteCard;

  /// Confirmation message before deleting a card
  ///
  /// In en, this message translates to:
  /// **'Only this card will be removed. The fact and other cards for it stay in the deck.'**
  String get deleteCardConfirm;

  /// Snackbar when delete card API fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete card'**
  String get deleteCardFailed;

  /// Menu item to delete deck
  ///
  /// In en, this message translates to:
  /// **'Delete Deck'**
  String get deleteDeck;

  /// Message when deck has no cards
  ///
  /// In en, this message translates to:
  /// **'No cards in this deck'**
  String get noCardsInThisDeck;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Description of card introduction interval
  ///
  /// In en, this message translates to:
  /// **'Introduce a new card every {interval} minutes'**
  String newCardEveryMinutes(int interval);

  /// Menu and sheet title for adding a fact to a deck
  ///
  /// In en, this message translates to:
  /// **'Add fact'**
  String get addFact;

  /// Button to add another entry row
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get addFactAddRow;

  /// Semantics label for removing an entry row
  ///
  /// In en, this message translates to:
  /// **'Remove row'**
  String get addFactRemoveRow;

  /// Hint for optional column label
  ///
  /// In en, this message translates to:
  /// **'Field name (optional)'**
  String get addFactFieldNameHint;

  /// Hint for entry text field
  ///
  /// In en, this message translates to:
  /// **'Text (optional if you add media)'**
  String get addFactContentHint;

  /// Label for attaching an image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get addFactAttachImage;

  /// Label for attaching a video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get addFactAttachVideo;

  /// Label for attaching audio
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get addFactAttachAudio;

  /// Remove selected media attachment
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get addFactClearAttachment;

  /// Single media icon: tap to pick file, long press clears attachment
  ///
  /// In en, this message translates to:
  /// **'Attach image, video, or audio. Long press to remove.'**
  String get addFactAttachMediaTooltip;

  /// Add-fact toolbar: open gallery for image or video
  ///
  /// In en, this message translates to:
  /// **'Choose photo or video from your library. Long press to remove.'**
  String get addFactGalleryMediaTooltip;

  /// Add-fact toolbar: start voice recording
  ///
  /// In en, this message translates to:
  /// **'Record audio with the microphone. Tap again to stop and attach. Long press while recording to discard.'**
  String get addFactRecordAudioTooltip;

  /// Add-fact toolbar: finish voice recording
  ///
  /// In en, this message translates to:
  /// **'Stop recording and attach audio to this field'**
  String get addFactStopRecordingTooltip;

  /// Snackbar when user denies mic permission for add-fact recording
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to record audio.'**
  String get addFactMicPermissionDenied;

  /// Snackbar when starting or stopping recording fails
  ///
  /// In en, this message translates to:
  /// **'Could not record audio. Try again.'**
  String get addFactRecordingFailed;

  /// Submit add-fact form
  ///
  /// In en, this message translates to:
  /// **'Save fact'**
  String get addFactSubmit;

  /// Snackbar when media upload fails
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Try again.'**
  String get addFactUploadFailed;

  /// When picked file exceeds API size limit
  ///
  /// In en, this message translates to:
  /// **'File is too large (max {maxMb} MB).'**
  String addFactFileTooLarge(int maxMb);

  /// Validation when a row is empty
  ///
  /// In en, this message translates to:
  /// **'Each row needs text or at least one attachment.'**
  String get addFactEntryNeedsContent;

  /// When extension is not image/audio/video
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported.'**
  String get addFactFileTypeNotSupported;

  /// When file kind does not match image/video/audio slot
  ///
  /// In en, this message translates to:
  /// **'Pick a file that matches this attachment type.'**
  String get addFactFileWrongSlot;

  /// When add-facts API fails
  ///
  /// In en, this message translates to:
  /// **'Could not add fact'**
  String get addFactFailed;

  /// Snackbar after a fact was saved to the deck
  ///
  /// In en, this message translates to:
  /// **'Fact added'**
  String get addFactSuccess;

  /// Default column label when deck has fewer names than rows
  ///
  /// In en, this message translates to:
  /// **'Field {number}'**
  String addFactFieldFallback(int number);

  /// Compact label for column name; tap to edit on add-fact form
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get addFactFieldShortLabel;

  /// Tooltip for pasting plain text into add/edit fact fields
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get addFactPasteFromClipboard;

  /// Card review when the audio file is missing, empty, or invalid
  ///
  /// In en, this message translates to:
  /// **'Audio unavailable'**
  String get cardAudioUnavailable;

  /// Deck study overflow menu item to adjust card text and ruby sizes
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// Title of bottom sheet for deck card typography
  ///
  /// In en, this message translates to:
  /// **'Font & ruby'**
  String get deckFontSheetTitle;

  /// Slider label for base script font size on cards
  ///
  /// In en, this message translates to:
  /// **'Main text size'**
  String get deckFontMainSizeLabel;

  /// Slider label for reading (ruby) font size on cards
  ///
  /// In en, this message translates to:
  /// **'Ruby text size'**
  String get deckFontRubySizeLabel;

  /// Caption above Japanese sample with wiki ruby markup
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get deckFontPreviewCaption;

  /// Font sheet tab for card front typography
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get deckFontTabFront;

  /// Font sheet tab for card back typography
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deckFontTabBack;

  /// Tags section label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Single tag label
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tagLabel;

  /// Button/tooltip to add a tag
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// Button to create a new tag
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get createTag;

  /// Menu item to edit a tag
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get editTag;

  /// Menu item to delete a tag
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get deleteTag;

  /// Input label for tag name
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// Input label for tag description
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get tagDescription;

  /// Hint text for tag name input
  ///
  /// In en, this message translates to:
  /// **'e.g. Grammar, Verbs…'**
  String get tagNameHint;

  /// Validation error when tag name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a tag name'**
  String get tagNameRequired;

  /// Snackbar after a tag is created
  ///
  /// In en, this message translates to:
  /// **'Tag created'**
  String get tagCreated;

  /// Snackbar after a tag is updated
  ///
  /// In en, this message translates to:
  /// **'Tag updated'**
  String get tagUpdated;

  /// Snackbar after a tag is deleted
  ///
  /// In en, this message translates to:
  /// **'Tag deleted'**
  String get tagDeleted;

  /// Snackbar when create tag API fails
  ///
  /// In en, this message translates to:
  /// **'Could not create tag'**
  String get tagCreateFailed;

  /// Snackbar when update tag API fails
  ///
  /// In en, this message translates to:
  /// **'Could not update tag'**
  String get tagUpdateFailed;

  /// Snackbar when delete tag API fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete tag'**
  String get tagDeleteFailed;

  /// Error when tag name conflicts with existing tag (409)
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get tagAlreadyExists;

  /// Error when user hits 1000-tag limit
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum of 1000 tags'**
  String get tagLimitReached;

  /// Empty state for tag list
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get noTags;

  /// Menu item or page title to manage all tags
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get manageTags;

  /// Title of the tag picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Select tags'**
  String get tagPickerTitle;

  /// Hint in tag picker filter field
  ///
  /// In en, this message translates to:
  /// **'Search tags…'**
  String get tagPickerSearchHint;

  /// Done button in tag picker sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tagPickerDone;

  /// Empty state when search has no results
  ///
  /// In en, this message translates to:
  /// **'No tags matching \"{query}\"'**
  String tagPickerNoMatch(String query);

  /// Empty state when user has no tags at all
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Tap below to create the first one.'**
  String get tagPickerEmptyHint;

  /// Filter chip label meaning no filter / show everything
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Title for the deck study tag filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Study by tag'**
  String get studyTagFilterTitle;

  /// Screen title showing all facts belonging to a tag
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get tagFacts;

  /// Empty state for tag facts screen
  ///
  /// In en, this message translates to:
  /// **'No facts in this tag yet'**
  String get noFactsInTag;

  /// Discovery tab label
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoveryTab;

  /// Search bar placeholder
  ///
  /// In en, this message translates to:
  /// **'Search decks, authors, tags'**
  String get discoverySearchHint;

  /// Latest filter chip
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get discoveryFilterLatest;

  /// Favorites filter chip
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get discoveryFilterFavorites;

  /// Empty state for latest list
  ///
  /// In en, this message translates to:
  /// **'No public decks yet'**
  String get discoveryEmpty;

  /// Empty state for favorites
  ///
  /// In en, this message translates to:
  /// **'No favorited decks'**
  String get discoveryFavoritesEmpty;

  /// Import button label
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get discoveryImport;

  /// Import in-progress label
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get discoveryImporting;

  /// Already imported badge
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get discoveryImported;

  /// Navigate to study after import
  ///
  /// In en, this message translates to:
  /// **'Go study'**
  String get discoveryGoStudy;

  /// Import success snackbar
  ///
  /// In en, this message translates to:
  /// **'Added to your decks'**
  String get discoveryImportSuccess;

  /// Favorite tooltip
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get discoveryFavorite;

  /// Unfavorite tooltip
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get discoveryUnfavorite;

  /// Relative time in years for discovery card
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String discoveryYearsAgo(int count);

  /// Relative time in months for discovery card
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String discoveryMonthsAgo(int count);

  /// Relative time in days for discovery card
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String discoveryDaysAgo(int count);

  /// Relative time in hours for discovery card
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String discoveryHoursAgo(int count);

  /// Relative time for just-published discovery cards
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get discoveryJustNow;

  /// Badge text when a favorited deck is no longer available
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get discoveryDeckUnavailable;

  /// Accessibility label for discovery card
  ///
  /// In en, this message translates to:
  /// **'{name}, {factCount}, by {owner}'**
  String discoveryCardSemantics(String name, String factCount, String owner);

  /// Accessibility label for imported badge on discovery card
  ///
  /// In en, this message translates to:
  /// **'Imported to my decks'**
  String get discoveryImportedBadgeSemantics;

  /// Accessibility label for unavailable badge on discovery card
  ///
  /// In en, this message translates to:
  /// **'This deck is unavailable'**
  String get discoveryUnavailableBadgeSemantics;

  /// Placeholder text for tabs that require authentication
  ///
  /// In en, this message translates to:
  /// **'Log in to access {tabLabel}.'**
  String discoveryLoginToAccessTab(String tabLabel);

  /// Tooltip for deck menu button
  ///
  /// In en, this message translates to:
  /// **'Deck options'**
  String get deckOptionsTooltip;

  /// 404 error for catalog deck
  ///
  /// In en, this message translates to:
  /// **'Deck not found or no longer available'**
  String get discoveryNotFound;

  /// 403 error importing own deck
  ///
  /// In en, this message translates to:
  /// **'You can\'t import your own deck'**
  String get discoveryImportSelf;

  /// Already imported error
  ///
  /// In en, this message translates to:
  /// **'Already imported this deck'**
  String get discoveryImportDuplicate;

  /// Generic import error
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please try again.'**
  String get discoveryImportFailed;

  /// Prompt for unauthenticated import
  ///
  /// In en, this message translates to:
  /// **'Sign in to import'**
  String get discoveryLoginToImport;

  /// Retry button in discovery error state
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get discoveryRetry;

  /// Publish deck sheet title
  ///
  /// In en, this message translates to:
  /// **'Publish Deck'**
  String get publishDeck;

  /// Hint text in publish sheet
  ///
  /// In en, this message translates to:
  /// **'Once published, others can discover and import your deck in the Discovery tab.'**
  String get publishDeckHint;

  /// Publish action button label
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishDeckAction;

  /// Publishing in-progress label
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get publishingDeck;

  /// Success state in publish sheet
  ///
  /// In en, this message translates to:
  /// **'Published!'**
  String get publishDeckSuccess;

  /// Error state in publish sheet
  ///
  /// In en, this message translates to:
  /// **'Failed to publish. Please try again.'**
  String get publishDeckFailed;

  /// Badge for already-published deck
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishDeckAlreadyPublished;

  /// Re-publish to push a new version
  ///
  /// In en, this message translates to:
  /// **'Update Published Version'**
  String get publishDeckUpdate;

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errorUnknown;

  /// Login failure: wrong credentials
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get authInvalidCredentials;

  /// Register failure: username conflict
  ///
  /// In en, this message translates to:
  /// **'Username is already taken'**
  String get authUsernameAlreadyExists;

  /// Register failure: email conflict
  ///
  /// In en, this message translates to:
  /// **'Email is already in use'**
  String get authEmailAlreadyInUse;

  /// JWT is invalid, expired, or revoked
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get authSessionExpired;

  /// Request made without auth token
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get authTokenRequired;

  /// Forgot-password reset token validation failed
  ///
  /// In en, this message translates to:
  /// **'Reset link is invalid or expired'**
  String get authResetTokenInvalid;

  /// Generic login failure fallback
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get errorLoginFailed;

  /// Generic register failure fallback
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get errorRegisterFailed;

  /// 409 when deleting a published source deck
  ///
  /// In en, this message translates to:
  /// **'Published decks cannot be deleted'**
  String get errorPublishedDeckCannotDelete;

  /// 409 when re-publishing with no new changes
  ///
  /// In en, this message translates to:
  /// **'No changes to publish'**
  String get errorNoChangesToPublish;

  /// 403 when source deck visibility blocks import
  ///
  /// In en, this message translates to:
  /// **'This deck is not available for import'**
  String get errorSourceDeckNotImportable;

  /// 403 when trying to import an import deck
  ///
  /// In en, this message translates to:
  /// **'Cannot re-import an already imported deck'**
  String get errorCannotImportImportedDeck;

  /// 403 when source deck has no published version
  ///
  /// In en, this message translates to:
  /// **'This deck has not been published yet'**
  String get errorSourceDeckNotPublished;

  /// 403 when editing facts on an imported deck
  ///
  /// In en, this message translates to:
  /// **'Imported decks cannot be modified'**
  String get errorCannotModifyImportedDeck;

  /// Section label for deck fields in discovery detail
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get discoveryDetailFields;

  /// Section label for deck description in discovery detail
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get discoveryDetailDescription;

  /// Fact count label in discovery detail
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String discoveryDetailFactCount(int count);

  /// Error text shown when a network image fails to load
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get imageLoadFailed;

  /// Home screen daily goal card title
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get homeDailyGoal;

  /// Home screen learning path section title
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get homeLearningPath;

  /// Home screen today pill label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// Home screen today focus section title
  ///
  /// In en, this message translates to:
  /// **'Today Focus'**
  String get homeTodayFocus;

  /// Home screen coaching text in today focus section
  ///
  /// In en, this message translates to:
  /// **'Finish one review round first, then add new facts from your study notes.'**
  String get homeTodayFocusText;

  /// API error: apiUserNotFound
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get apiUserNotFound;

  /// API error: apiInvalidRequestPayload
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please try again.'**
  String get apiInvalidRequestPayload;

  /// API error: apiDeckNotFound
  ///
  /// In en, this message translates to:
  /// **'Deck not found'**
  String get apiDeckNotFound;

  /// API error: apiNotAuthorizedAccessDeck
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to access this deck'**
  String get apiNotAuthorizedAccessDeck;

  /// API error: apiNotAuthorizedModifyDeck
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to modify this deck'**
  String get apiNotAuthorizedModifyDeck;

  /// API error: apiNotAuthorizedDeleteDeck
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to delete this deck'**
  String get apiNotAuthorizedDeleteDeck;

  /// API error: apiNotAuthorized
  ///
  /// In en, this message translates to:
  /// **'You are not authorized'**
  String get apiNotAuthorized;

  /// API error: apiServerRetrieveDeck
  ///
  /// In en, this message translates to:
  /// **'Could not load deck. Please try again.'**
  String get apiServerRetrieveDeck;

  /// API error: apiServerParseDeck
  ///
  /// In en, this message translates to:
  /// **'Deck data is corrupted. Please try again.'**
  String get apiServerParseDeck;

  /// API error: apiRegisterFieldsRequired
  ///
  /// In en, this message translates to:
  /// **'Username, password, and email are required'**
  String get apiRegisterFieldsRequired;

  /// API error: apiLoginFieldsRequired
  ///
  /// In en, this message translates to:
  /// **'Username and password are required'**
  String get apiLoginFieldsRequired;

  /// API error: apiServerCheckUsername
  ///
  /// In en, this message translates to:
  /// **'Could not verify username. Please try again.'**
  String get apiServerCheckUsername;

  /// API error: apiServerCheckEmail
  ///
  /// In en, this message translates to:
  /// **'Could not verify email. Please try again.'**
  String get apiServerCheckEmail;

  /// API error: apiServerHashPassword
  ///
  /// In en, this message translates to:
  /// **'Could not process password. Please try again.'**
  String get apiServerHashPassword;

  /// API error: apiServerSerializeUser
  ///
  /// In en, this message translates to:
  /// **'Could not save user data. Please try again.'**
  String get apiServerSerializeUser;

  /// API error: apiServerCreateUser
  ///
  /// In en, this message translates to:
  /// **'Could not create account. Please try again.'**
  String get apiServerCreateUser;

  /// API error: apiServerRetrieveUser
  ///
  /// In en, this message translates to:
  /// **'Could not load user data. Please try again.'**
  String get apiServerRetrieveUser;

  /// API error: apiServerParseUser
  ///
  /// In en, this message translates to:
  /// **'User data is corrupted. Please try again.'**
  String get apiServerParseUser;

  /// API error: apiServerGenerateToken
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please try again.'**
  String get apiServerGenerateToken;

  /// API error: apiServerLogout
  ///
  /// In en, this message translates to:
  /// **'Could not log out. Please try again.'**
  String get apiServerLogout;

  /// API error: apiEmailRequired
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get apiEmailRequired;

  /// API error: apiServerGenerateResetToken
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email. Please try again.'**
  String get apiServerGenerateResetToken;

  /// API error: apiServerStoreResetToken
  ///
  /// In en, this message translates to:
  /// **'Could not process reset request. Please try again.'**
  String get apiServerStoreResetToken;

  /// API error: apiResetFieldsRequired
  ///
  /// In en, this message translates to:
  /// **'Reset token and new password are required'**
  String get apiResetFieldsRequired;

  /// API error: apiServerValidateResetToken
  ///
  /// In en, this message translates to:
  /// **'Could not validate reset link. Please try again.'**
  String get apiServerValidateResetToken;

  /// API error: apiServerResetPassword
  ///
  /// In en, this message translates to:
  /// **'Could not reset password. Please try again.'**
  String get apiServerResetPassword;

  /// API error: apiServerRetrieveProfile
  ///
  /// In en, this message translates to:
  /// **'Could not load profile. Please try again.'**
  String get apiServerRetrieveProfile;

  /// API error: apiDeckNameRequired
  ///
  /// In en, this message translates to:
  /// **'Deck name is required'**
  String get apiDeckNameRequired;

  /// API error: apiDeckFieldsRequired
  ///
  /// In en, this message translates to:
  /// **'At least one column name is required'**
  String get apiDeckFieldsRequired;

  /// API error: apiDeckFieldNameEmpty
  ///
  /// In en, this message translates to:
  /// **'Each column name must be non-empty'**
  String get apiDeckFieldNameEmpty;

  /// API error: apiDeckRateRequired
  ///
  /// In en, this message translates to:
  /// **'Daily new-card rate must be between 1 and 1000'**
  String get apiDeckRateRequired;

  /// API error: apiTagsOrTagIds
  ///
  /// In en, this message translates to:
  /// **'Provide either tags or tag IDs, not both'**
  String get apiTagsOrTagIds;

  /// API error: apiDeckDescriptionInvalidChars
  ///
  /// In en, this message translates to:
  /// **'Deck description contains invalid characters'**
  String get apiDeckDescriptionInvalidChars;

  /// API error: apiDeckDescriptionTooLong
  ///
  /// In en, this message translates to:
  /// **'Deck description must be at most 500 characters'**
  String get apiDeckDescriptionTooLong;

  /// API error: apiTagIdRequired
  ///
  /// In en, this message translates to:
  /// **'Tag ID is required'**
  String get apiTagIdRequired;

  /// API error: apiMaxTagsPerDeck
  ///
  /// In en, this message translates to:
  /// **'Maximum tags per deck reached'**
  String get apiMaxTagsPerDeck;

  /// API error: apiTagNameRequired
  ///
  /// In en, this message translates to:
  /// **'Tag name is required'**
  String get apiTagNameRequired;

  /// API error: apiTagNameInvalidChars
  ///
  /// In en, this message translates to:
  /// **'Tag name contains invalid characters'**
  String get apiTagNameInvalidChars;

  /// API error: apiTagNameTooLong
  ///
  /// In en, this message translates to:
  /// **'Tag name is too long (max 50 characters)'**
  String get apiTagNameTooLong;

  /// API error: apiTagNotFound
  ///
  /// In en, this message translates to:
  /// **'Tag not found'**
  String get apiTagNotFound;

  /// API error: apiServerResolveDeckTags
  ///
  /// In en, this message translates to:
  /// **'Could not resolve deck tags. Please try again.'**
  String get apiServerResolveDeckTags;

  /// API error: apiServerGenerateDeckId
  ///
  /// In en, this message translates to:
  /// **'Could not create deck. Please try again.'**
  String get apiServerGenerateDeckId;

  /// API error: apiServerMarshalDeck
  ///
  /// In en, this message translates to:
  /// **'Could not save deck. Please try again.'**
  String get apiServerMarshalDeck;

  /// API error: apiServerCreateDeck
  ///
  /// In en, this message translates to:
  /// **'Could not create deck. Please try again.'**
  String get apiServerCreateDeck;

  /// API error: apiServerPrepareDeckMedia
  ///
  /// In en, this message translates to:
  /// **'Could not prepare media storage. Please try again.'**
  String get apiServerPrepareDeckMedia;

  /// API error: apiDeckRateRange
  ///
  /// In en, this message translates to:
  /// **'Daily new-card rate must be between 1 and 1000'**
  String get apiDeckRateRange;

  /// API error: apiInvalidVisibility
  ///
  /// In en, this message translates to:
  /// **'Invalid visibility setting'**
  String get apiInvalidVisibility;

  /// API error: apiCannotChangeVisibilityAfterPublish
  ///
  /// In en, this message translates to:
  /// **'Cannot change visibility after publishing'**
  String get apiCannotChangeVisibilityAfterPublish;

  /// API error: apiCannotChangeVisibilityImported
  ///
  /// In en, this message translates to:
  /// **'Cannot change visibility on an imported deck'**
  String get apiCannotChangeVisibilityImported;

  /// API error: apiCannotChangeFieldsImported
  ///
  /// In en, this message translates to:
  /// **'Cannot change fields on an imported deck'**
  String get apiCannotChangeFieldsImported;

  /// API error: apiCannotChangeNameImported
  ///
  /// In en, this message translates to:
  /// **'Cannot change name on an imported deck'**
  String get apiCannotChangeNameImported;

  /// API error: apiCannotChangeDescriptionImported
  ///
  /// In en, this message translates to:
  /// **'Cannot change description on an imported deck'**
  String get apiCannotChangeDescriptionImported;

  /// API error: apiImportedDeckRateRequired
  ///
  /// In en, this message translates to:
  /// **'Daily new-card rate is required for imported deck updates'**
  String get apiImportedDeckRateRequired;

  /// API error: apiServerSerializeDeck
  ///
  /// In en, this message translates to:
  /// **'Could not save deck. Please try again.'**
  String get apiServerSerializeDeck;

  /// API error: apiServerLoadCards
  ///
  /// In en, this message translates to:
  /// **'Could not load cards. Please try again.'**
  String get apiServerLoadCards;

  /// API error: apiServerRescheduleCards
  ///
  /// In en, this message translates to:
  /// **'Could not reschedule cards. Please try again.'**
  String get apiServerRescheduleCards;

  /// API error: apiServerUpdateDeckCards
  ///
  /// In en, this message translates to:
  /// **'Could not update deck. Please try again.'**
  String get apiServerUpdateDeckCards;

  /// API error: apiServerUpdateDeck
  ///
  /// In en, this message translates to:
  /// **'Could not update deck. Please try again.'**
  String get apiServerUpdateDeck;

  /// API error: apiServerLoadFactsDelete
  ///
  /// In en, this message translates to:
  /// **'Could not delete deck. Please try again.'**
  String get apiServerLoadFactsDelete;

  /// API error: apiServerCleanupTags
  ///
  /// In en, this message translates to:
  /// **'Could not delete deck. Please try again.'**
  String get apiServerCleanupTags;

  /// API error: apiServerDeleteDeck
  ///
  /// In en, this message translates to:
  /// **'Could not delete deck. Please try again.'**
  String get apiServerDeleteDeck;

  /// API error: apiServerRevokeMediaGrants
  ///
  /// In en, this message translates to:
  /// **'Could not delete deck. Please try again.'**
  String get apiServerRevokeMediaGrants;

  /// API error: apiServerRetrieveDecks
  ///
  /// In en, this message translates to:
  /// **'Could not load decks. Please try again.'**
  String get apiServerRetrieveDecks;

  /// API error: apiServerRetrieveDeckData
  ///
  /// In en, this message translates to:
  /// **'Could not load deck. Please try again.'**
  String get apiServerRetrieveDeckData;

  /// API error: apiServerListCatalog
  ///
  /// In en, this message translates to:
  /// **'Could not load catalog. Please try again.'**
  String get apiServerListCatalog;

  /// API error: apiServerLoadCatalogDeck
  ///
  /// In en, this message translates to:
  /// **'Could not load deck details. Please try again.'**
  String get apiServerLoadCatalogDeck;

  /// API error: apiFirstPublishPublic
  ///
  /// In en, this message translates to:
  /// **'First publish requires public visibility'**
  String get apiFirstPublishPublic;

  /// API error: apiCannotPublishImported
  ///
  /// In en, this message translates to:
  /// **'Imported decks cannot be published'**
  String get apiCannotPublishImported;

  /// API error: apiSourceDeckIdRequired
  ///
  /// In en, this message translates to:
  /// **'Source deck ID is required'**
  String get apiSourceDeckIdRequired;

  /// API error: apiMaxFactTagsPerDeck
  ///
  /// In en, this message translates to:
  /// **'Maximum fact tags per deck reached'**
  String get apiMaxFactTagsPerDeck;

  /// API error: apiUpdatesImportedOnly
  ///
  /// In en, this message translates to:
  /// **'Updates are only available for imported decks'**
  String get apiUpdatesImportedOnly;

  /// API error: apiNotImportedDeck
  ///
  /// In en, this message translates to:
  /// **'This is not an imported deck'**
  String get apiNotImportedDeck;

  /// API error: apiSourceDeckMissing
  ///
  /// In en, this message translates to:
  /// **'Source deck is missing'**
  String get apiSourceDeckMissing;

  /// API error: apiFactsArrayRequired
  ///
  /// In en, this message translates to:
  /// **'Facts are required'**
  String get apiFactsArrayRequired;

  /// API error: apiInvalidFactOperation
  ///
  /// In en, this message translates to:
  /// **'Invalid operation. Supported: append, prepend, shuffle, spread.'**
  String get apiInvalidFactOperation;

  /// API error: apiDeckRateMinForFacts
  ///
  /// In en, this message translates to:
  /// **'Set daily new-card rate to at least 1 before adding facts'**
  String get apiDeckRateMinForFacts;

  /// API error: apiAtLeastOneFact
  ///
  /// In en, this message translates to:
  /// **'At least one fact is required'**
  String get apiAtLeastOneFact;

  /// API error: apiTemplateInvalid
  ///
  /// In en, this message translates to:
  /// **'Card template is invalid'**
  String get apiTemplateInvalid;

  /// API error: apiEntryContentRequired
  ///
  /// In en, this message translates to:
  /// **'Each entry needs text, audio, image, video, or JSON'**
  String get apiEntryContentRequired;

  /// API error: apiFactNotFound
  ///
  /// In en, this message translates to:
  /// **'Fact not found'**
  String get apiFactNotFound;

  /// API error: apiServerAddFacts
  ///
  /// In en, this message translates to:
  /// **'Could not add facts. Please try again.'**
  String get apiServerAddFacts;

  /// API error: apiServerMergeFacts
  ///
  /// In en, this message translates to:
  /// **'Could not add facts. Please try again.'**
  String get apiServerMergeFacts;

  /// API error: apiServerSerializeFact
  ///
  /// In en, this message translates to:
  /// **'Could not save fact. Please try again.'**
  String get apiServerSerializeFact;

  /// API error: apiServerRebuildTemplate
  ///
  /// In en, this message translates to:
  /// **'Could not update card. Please try again.'**
  String get apiServerRebuildTemplate;

  /// API error: apiServerRetrieveCards
  ///
  /// In en, this message translates to:
  /// **'Could not load cards. Please try again.'**
  String get apiServerRetrieveCards;

  /// API error: apiServerSerializeCard
  ///
  /// In en, this message translates to:
  /// **'Could not save card. Please try again.'**
  String get apiServerSerializeCard;

  /// API error: apiServerUpdateFact
  ///
  /// In en, this message translates to:
  /// **'Could not update fact. Please try again.'**
  String get apiServerUpdateFact;

  /// API error: apiServerRemoveFactTags
  ///
  /// In en, this message translates to:
  /// **'Could not update fact. Please try again.'**
  String get apiServerRemoveFactTags;

  /// API error: apiServerRemoveFact
  ///
  /// In en, this message translates to:
  /// **'Could not remove fact. Please try again.'**
  String get apiServerRemoveFact;

  /// API error: apiServerDeleteFact
  ///
  /// In en, this message translates to:
  /// **'Could not delete fact. Please try again.'**
  String get apiServerDeleteFact;

  /// API error: apiServerRetrieveFacts
  ///
  /// In en, this message translates to:
  /// **'Could not load facts. Please try again.'**
  String get apiServerRetrieveFacts;

  /// API error: apiServerRetrieveFactTags
  ///
  /// In en, this message translates to:
  /// **'Could not load fact tags. Please try again.'**
  String get apiServerRetrieveFactTags;

  /// API error: apiServerCheckFact
  ///
  /// In en, this message translates to:
  /// **'Could not verify fact. Please try again.'**
  String get apiServerCheckFact;

  /// API error: apiInvalidUsedOnFilter
  ///
  /// In en, this message translates to:
  /// **'Invalid filter value'**
  String get apiInvalidUsedOnFilter;

  /// API error: apiUsedOnRequired
  ///
  /// In en, this message translates to:
  /// **'Filter type is required when deck ID is set'**
  String get apiUsedOnRequired;

  /// API error: apiDeckIdRequiredForFact
  ///
  /// In en, this message translates to:
  /// **'Deck ID is required for fact filter'**
  String get apiDeckIdRequiredForFact;

  /// API error: apiServerRetrieveTags
  ///
  /// In en, this message translates to:
  /// **'Could not load tags. Please try again.'**
  String get apiServerRetrieveTags;

  /// API error: apiServerCheckTags
  ///
  /// In en, this message translates to:
  /// **'Could not verify tags. Please try again.'**
  String get apiServerCheckTags;

  /// API error: apiServerCheckTagName
  ///
  /// In en, this message translates to:
  /// **'Could not verify tag name. Please try again.'**
  String get apiServerCheckTagName;

  /// API error: apiServerGenerateTagId
  ///
  /// In en, this message translates to:
  /// **'Could not create tag. Please try again.'**
  String get apiServerGenerateTagId;

  /// API error: apiServerCreateTag
  ///
  /// In en, this message translates to:
  /// **'Could not create tag. Please try again.'**
  String get apiServerCreateTag;

  /// API error: apiServerSerializeTag
  ///
  /// In en, this message translates to:
  /// **'Could not save tag. Please try again.'**
  String get apiServerSerializeTag;

  /// API error: apiServerSaveTag
  ///
  /// In en, this message translates to:
  /// **'Could not save tag. Please try again.'**
  String get apiServerSaveTag;

  /// API error: apiServerAssociateTag
  ///
  /// In en, this message translates to:
  /// **'Could not add tag. Please try again.'**
  String get apiServerAssociateTag;

  /// API error: apiServerRemoveTag
  ///
  /// In en, this message translates to:
  /// **'Could not remove tag. Please try again.'**
  String get apiServerRemoveTag;

  /// API error: apiServerLoadTags
  ///
  /// In en, this message translates to:
  /// **'Could not load tags. Please try again.'**
  String get apiServerLoadTags;

  /// API error: apiFactIdRequired
  ///
  /// In en, this message translates to:
  /// **'Fact ID is required'**
  String get apiFactIdRequired;

  /// API error: apiTemplateRequired
  ///
  /// In en, this message translates to:
  /// **'Card template is required'**
  String get apiTemplateRequired;

  /// API error: apiTemplateExists
  ///
  /// In en, this message translates to:
  /// **'A template already exists for this fact'**
  String get apiTemplateExists;

  /// API error: apiCardNotFound
  ///
  /// In en, this message translates to:
  /// **'Card not found'**
  String get apiCardNotFound;

  /// API error: apiCardIdRequired
  ///
  /// In en, this message translates to:
  /// **'Card ID is required'**
  String get apiCardIdRequired;

  /// API error: apiCardIdEmpty
  ///
  /// In en, this message translates to:
  /// **'Card ID must not be empty'**
  String get apiCardIdEmpty;

  /// API error: apiIntervalOrHiddenRequired
  ///
  /// In en, this message translates to:
  /// **'Include either interval or hidden field'**
  String get apiIntervalOrHiddenRequired;

  /// API error: apiIntervalAndHiddenConflict
  ///
  /// In en, this message translates to:
  /// **'Cannot send both interval and hidden in one request'**
  String get apiIntervalAndHiddenConflict;

  /// API error: apiLastReviewRequired
  ///
  /// In en, this message translates to:
  /// **'last_review is required with interval updates'**
  String get apiLastReviewRequired;

  /// API error: apiLastReviewIntervalOnly
  ///
  /// In en, this message translates to:
  /// **'last_review is only valid with interval updates'**
  String get apiLastReviewIntervalOnly;

  /// API error: apiLastReviewNumeric
  ///
  /// In en, this message translates to:
  /// **'last_review must be a numeric Unix timestamp'**
  String get apiLastReviewNumeric;

  /// API error: apiLastReviewWhole
  ///
  /// In en, this message translates to:
  /// **'last_review must be a whole-number Unix timestamp'**
  String get apiLastReviewWhole;

  /// API error: apiLastReviewPositive
  ///
  /// In en, this message translates to:
  /// **'last_review must be a positive Unix timestamp'**
  String get apiLastReviewPositive;

  /// API error: apiIntervalNumeric
  ///
  /// In en, this message translates to:
  /// **'interval must be a number'**
  String get apiIntervalNumeric;

  /// API error: apiIntervalPositive
  ///
  /// In en, this message translates to:
  /// **'interval must be a positive number'**
  String get apiIntervalPositive;

  /// API error: apiHiddenBoolean
  ///
  /// In en, this message translates to:
  /// **'hidden must be true or false'**
  String get apiHiddenBoolean;

  /// API error: apiUnsupportedCardOperation
  ///
  /// In en, this message translates to:
  /// **'Supported operations: interval, visibility'**
  String get apiUnsupportedCardOperation;

  /// API error: apiCardTemplateInvalidForFact
  ///
  /// In en, this message translates to:
  /// **'Card template is invalid for this fact'**
  String get apiCardTemplateInvalidForFact;

  /// API error: apiServerUpdateCardRedis
  ///
  /// In en, this message translates to:
  /// **'Could not update card. Please try again.'**
  String get apiServerUpdateCardRedis;

  /// API error: apiServerCheckCardMembership
  ///
  /// In en, this message translates to:
  /// **'Could not verify card. Please try again.'**
  String get apiServerCheckCardMembership;

  /// API error: apiServerParseCard
  ///
  /// In en, this message translates to:
  /// **'Card data is corrupted. Please try again.'**
  String get apiServerParseCard;

  /// API error: apiServerUpdateCard
  ///
  /// In en, this message translates to:
  /// **'Could not update card. Please try again.'**
  String get apiServerUpdateCard;

  /// API error: apiServerCheckCard
  ///
  /// In en, this message translates to:
  /// **'Could not verify card. Please try again.'**
  String get apiServerCheckCard;

  /// API error: apiServerDeleteCard
  ///
  /// In en, this message translates to:
  /// **'Could not delete card. Please try again.'**
  String get apiServerDeleteCard;

  /// API error: apiServerGenerateCardId
  ///
  /// In en, this message translates to:
  /// **'Could not create card. Please try again.'**
  String get apiServerGenerateCardId;

  /// API error: apiServerMergeCard
  ///
  /// In en, this message translates to:
  /// **'Could not add card. Please try again.'**
  String get apiServerMergeCard;

  /// API error: apiServerAddCard
  ///
  /// In en, this message translates to:
  /// **'Could not add card. Please try again.'**
  String get apiServerAddCard;

  /// API error: apiServerParseFact
  ///
  /// In en, this message translates to:
  /// **'Fact data is corrupted. Please try again.'**
  String get apiServerParseFact;

  /// API error: apiInvalidMultipart
  ///
  /// In en, this message translates to:
  /// **'Invalid file upload'**
  String get apiInvalidMultipart;

  /// API error: apiMissingFileField
  ///
  /// In en, this message translates to:
  /// **'No file selected or file field is invalid'**
  String get apiMissingFileField;

  /// API error: apiMediaDeckIdRequired
  ///
  /// In en, this message translates to:
  /// **'Deck ID is required for media upload'**
  String get apiMediaDeckIdRequired;

  /// API error: apiClientIdInUse
  ///
  /// In en, this message translates to:
  /// **'Upload ID already in use. Please retry.'**
  String get apiClientIdInUse;

  /// API error: apiFileTooLarge
  ///
  /// In en, this message translates to:
  /// **'File is too large'**
  String get apiFileTooLarge;

  /// API error: apiUnsupportedMediaType
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get apiUnsupportedMediaType;

  /// API error: apiInvalidJsonDocument
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON file'**
  String get apiInvalidJsonDocument;

  /// API error: apiMediaStorageNotConfigured
  ///
  /// In en, this message translates to:
  /// **'Media storage is not available'**
  String get apiMediaStorageNotConfigured;

  /// API error: apiFailedCheckClientId
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get apiFailedCheckClientId;

  /// API error: apiFailedVerifyDeck
  ///
  /// In en, this message translates to:
  /// **'Could not verify deck. Please try again.'**
  String get apiFailedVerifyDeck;

  /// API error: apiFailedReadFile
  ///
  /// In en, this message translates to:
  /// **'Could not read file. Please try again.'**
  String get apiFailedReadFile;

  /// API error: apiFailedGenerateId
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get apiFailedGenerateId;

  /// API error: apiFailedPrepareMedia
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get apiFailedPrepareMedia;

  /// API error: apiFailedStoreFile
  ///
  /// In en, this message translates to:
  /// **'Could not save file. Please try again.'**
  String get apiFailedStoreFile;

  /// API error: apiFailedSaveMetadata
  ///
  /// In en, this message translates to:
  /// **'Could not save file info. Please try again.'**
  String get apiFailedSaveMetadata;

  /// API error: apiMediaVersionRequired
  ///
  /// In en, this message translates to:
  /// **'Version parameter is required for this media'**
  String get apiMediaVersionRequired;

  /// API error: apiAccessDenied
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get apiAccessDenied;

  /// API error: apiMediaNotFound
  ///
  /// In en, this message translates to:
  /// **'Media not found'**
  String get apiMediaNotFound;

  /// API error: apiMediaFileNotFound
  ///
  /// In en, this message translates to:
  /// **'Media file not found'**
  String get apiMediaFileNotFound;

  /// API error: apiFailedListMedia
  ///
  /// In en, this message translates to:
  /// **'Could not load media. Please try again.'**
  String get apiFailedListMedia;

  /// API error: apiFailedLoadMedia
  ///
  /// In en, this message translates to:
  /// **'Could not load media. Please try again.'**
  String get apiFailedLoadMedia;

  /// API error: apiFeedbackImportedOnly
  ///
  /// In en, this message translates to:
  /// **'Contributions are only available on imported decks'**
  String get apiFeedbackImportedOnly;

  /// API error: apiFeedbackSourceNotPublished
  ///
  /// In en, this message translates to:
  /// **'Source deck is not published'**
  String get apiFeedbackSourceNotPublished;

  /// API error: apiFeedbackMessageLength
  ///
  /// In en, this message translates to:
  /// **'Message must be 1–2000 characters'**
  String get apiFeedbackMessageLength;

  /// API error: apiEntryIndexOutOfRange
  ///
  /// In en, this message translates to:
  /// **'Entry index is out of range'**
  String get apiEntryIndexOutOfRange;

  /// API error: apiProposedEntriesContent
  ///
  /// In en, this message translates to:
  /// **'Proposed entries must have content'**
  String get apiProposedEntriesContent;

  /// API error: apiProposedEntriesLength
  ///
  /// In en, this message translates to:
  /// **'Proposed entries must match the fact length'**
  String get apiProposedEntriesLength;

  /// API error: apiProposedEntriesDiffer
  ///
  /// In en, this message translates to:
  /// **'Proposed entries must differ from the original'**
  String get apiProposedEntriesDiffer;

  /// API error: apiFactNotInSnapshot
  ///
  /// In en, this message translates to:
  /// **'Fact is not in the pinned snapshot'**
  String get apiFactNotInSnapshot;

  /// API error: apiFeedbackDeckNotFound
  ///
  /// In en, this message translates to:
  /// **'Deck not found'**
  String get apiFeedbackDeckNotFound;

  /// API error: apiFeedbackFactNotFound
  ///
  /// In en, this message translates to:
  /// **'Fact not found'**
  String get apiFeedbackFactNotFound;

  /// API error: apiFeedbackDailyLimit
  ///
  /// In en, this message translates to:
  /// **'Daily contribution limit reached. Try again tomorrow.'**
  String get apiFeedbackDailyLimit;

  /// API error: apiServerSubmitFeedback
  ///
  /// In en, this message translates to:
  /// **'Could not submit feedback. Please try again.'**
  String get apiServerSubmitFeedback;

  /// API error: apiFeedbackInboxSourceOnly
  ///
  /// In en, this message translates to:
  /// **'Contribution inbox is only available on source decks'**
  String get apiFeedbackInboxSourceOnly;

  /// API error: apiServerListFeedback
  ///
  /// In en, this message translates to:
  /// **'Could not load feedback. Please try again.'**
  String get apiServerListFeedback;

  /// API error: apiInvalidFeedbackStatus
  ///
  /// In en, this message translates to:
  /// **'Invalid feedback status'**
  String get apiInvalidFeedbackStatus;

  /// API error: apiFeedbackNotFound
  ///
  /// In en, this message translates to:
  /// **'Contribution not found'**
  String get apiFeedbackNotFound;

  /// API error: apiServerUpdateFeedback
  ///
  /// In en, this message translates to:
  /// **'Could not update feedback. Please try again.'**
  String get apiServerUpdateFeedback;

  /// API error: apiProposedEntriesRequiredAccept
  ///
  /// In en, this message translates to:
  /// **'Proposed entries are required to accept feedback'**
  String get apiProposedEntriesRequiredAccept;

  /// API error: apiFactNotOnSourceDeck
  ///
  /// In en, this message translates to:
  /// **'Fact not found on source deck'**
  String get apiFactNotOnSourceDeck;

  /// API error: apiReportCannotBeAccepted
  ///
  /// In en, this message translates to:
  /// **'Report cannot be accepted'**
  String get apiReportCannotBeAccepted;

  /// API error: apiServerAcceptFeedback
  ///
  /// In en, this message translates to:
  /// **'Could not accept feedback. Please try again.'**
  String get apiServerAcceptFeedback;

  /// API error: apiBadCertificate
  ///
  /// In en, this message translates to:
  /// **'Secure connection failed'**
  String get apiBadCertificate;

  /// API error: apiBadResponse
  ///
  /// In en, this message translates to:
  /// **'Unexpected server response'**
  String get apiBadResponse;

  /// API error: apiRequestCancel
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled'**
  String get apiRequestCancel;

  /// API error: apiUnknownError
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get apiUnknownError;

  /// API error: errorServerError
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get errorServerError;

  /// API error pattern: apiFactEntryRequired
  ///
  /// In en, this message translates to:
  /// **'Fact {index}: at least one entry is required'**
  String apiFactEntryRequired(int index);

  /// API error pattern: apiFactEntryContent
  ///
  /// In en, this message translates to:
  /// **'Fact {index}: each entry needs text, audio, image, video, or JSON'**
  String apiFactEntryContent(int index);

  /// API error pattern: apiInvalidTemplate
  ///
  /// In en, this message translates to:
  /// **'Invalid card template for this fact'**
  String get apiInvalidTemplate;

  /// API error pattern: apiNegativeInterval
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with this card. Try removing fact {factId}.'**
  String apiNegativeInterval(String factId);

  /// API error pattern: apiUnsupportedMediaMime
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type: {mime}'**
  String apiUnsupportedMediaMime(String mime);

  /// API error pattern: apiInvalidTargetVersion
  ///
  /// In en, this message translates to:
  /// **'Invalid target version'**
  String get apiInvalidTargetVersion;

  /// Deck study submit failure
  ///
  /// In en, this message translates to:
  /// **'Could not save card progress. Please try again.'**
  String get errorSubmitCardFailed;

  /// Menu action to check imported deck updates
  ///
  /// In en, this message translates to:
  /// **'Check updates'**
  String get deckCheckUpdates;

  /// Action label to sync imported deck
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get deckSyncNow;

  /// Shown when imported deck has no updates
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get deckUpToDate;

  /// Toast after imported deck sync succeeds
  ///
  /// In en, this message translates to:
  /// **'Deck synced'**
  String get deckSyncSuccess;

  /// Version comparison for imported deck updates
  ///
  /// In en, this message translates to:
  /// **'Current v{source} -> latest v{latest}'**
  String deckUpdatesVersion(int source, int latest);

  /// Fact/media change counts in imported deck updates
  ///
  /// In en, this message translates to:
  /// **'Added {added}, edited {edited}, removed {removed}, media changes {media}'**
  String deckUpdatesCounts(int added, int edited, int removed, int media);

  /// Action to submit feedback for imported deck fact
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get feedbackSubmit;

  /// Hint text for feedback message input
  ///
  /// In en, this message translates to:
  /// **'Describe the issue for this fact'**
  String get feedbackMessageHint;

  /// Validation error when feedback message is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter feedback message'**
  String get feedbackMessageRequired;

  /// Toast after feedback submission succeeds
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted'**
  String get feedbackSubmitSuccess;

  /// Shown when fact edit opens an invalid empty fact
  ///
  /// In en, this message translates to:
  /// **'This fact has no entries'**
  String get factEditNoEntries;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

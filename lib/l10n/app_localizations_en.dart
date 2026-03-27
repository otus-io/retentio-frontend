// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Retentio';

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
  String get cardAudioUnavailable => 'Audio unavailable';
}

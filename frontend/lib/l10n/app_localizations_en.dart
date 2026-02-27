// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wordupx';

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
  String get learn => 'Learn';

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
  String get createInputDeckName => 'Name';

  @override
  String get createInputDeckNameHint => 'Set a name for your deck';

  @override
  String get language => 'Language';

  @override
  String get rate => 'Rate';

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
}

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
  /// **'Retentio'**
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

  /// Learn tab label in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

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

  /// Difficulty rating: Hard
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// Difficulty rating: Good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// Difficulty rating: Easy
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
  /// **'Name'**
  String get createInputDeckName;

  /// Hint text for deck name input field
  ///
  /// In en, this message translates to:
  /// **'Set a name for your deck'**
  String get createInputDeckNameHint;

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

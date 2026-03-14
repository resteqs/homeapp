import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get navGrocery;

  /// No description provided for @navChore.
  ///
  /// In en, this message translates to:
  /// **'Chore'**
  String get navChore;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get authPleaseWait;

  /// No description provided for @authSignupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authSignupPrompt;

  /// No description provided for @authLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get authLoginPrompt;

  /// No description provided for @authSignupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please check your email.'**
  String get authSignupSuccess;

  /// No description provided for @authSignoutError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out: {error}'**
  String authSignoutError(String error);

  /// No description provided for @authUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred: {error}'**
  String authUnexpectedError(String error);

  /// No description provided for @groceryMyLists.
  ///
  /// In en, this message translates to:
  /// **'My lists'**
  String get groceryMyLists;

  /// No description provided for @groceryNoLists.
  ///
  /// In en, this message translates to:
  /// **'No lists available.'**
  String get groceryNoLists;

  /// No description provided for @groceryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item...'**
  String get groceryAddItem;

  /// No description provided for @groceryAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get groceryAdd;

  /// No description provided for @groceryEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get groceryEditItem;

  /// No description provided for @groceryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get groceryQuantity;

  /// No description provided for @grocerySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get grocerySaveChanges;

  /// No description provided for @groceryEmptyList.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get groceryEmptyList;

  /// No description provided for @groceryBoughtItems.
  ///
  /// In en, this message translates to:
  /// **'Bought Items'**
  String get groceryBoughtItems;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get settingsLoggingOut;

  /// No description provided for @settingsAttributions.
  ///
  /// In en, this message translates to:
  /// **'Attributions'**
  String get settingsAttributions;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get langGerman;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

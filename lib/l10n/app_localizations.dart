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

  /// No description provided for @groceryAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get groceryAddProduct;

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

  /// No description provided for @settingsGroceryCategoryOrder.
  ///
  /// In en, this message translates to:
  /// **'Grocery category order'**
  String get settingsGroceryCategoryOrder;

  /// No description provided for @settingsGroceryCategoryOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag categories to match the order you usually walk through the supermarket.'**
  String get settingsGroceryCategoryOrderHint;

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

  /// No description provided for @groceryItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String groceryItemsSelected(int count);

  /// No description provided for @groceryDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get groceryDeleteSelected;

  /// No description provided for @groceryMoveToAnotherList.
  ///
  /// In en, this message translates to:
  /// **'Move to another list'**
  String get groceryMoveToAnotherList;

  /// No description provided for @groceryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groceryCancel;

  /// No description provided for @groceryNoOtherListAvailable.
  ///
  /// In en, this message translates to:
  /// **'No other list available.'**
  String get groceryNoOtherListAvailable;

  /// No description provided for @grocerySelectDestinationList.
  ///
  /// In en, this message translates to:
  /// **'Select destination list'**
  String get grocerySelectDestinationList;

  /// No description provided for @groceryDefaultListName.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get groceryDefaultListName;

  /// No description provided for @groceryDeleteListQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get groceryDeleteListQuestion;

  /// No description provided for @groceryDeleteListWarning.
  ///
  /// In en, this message translates to:
  /// **'The list \"{listName}\" will be deleted permanently.'**
  String groceryDeleteListWarning(String listName);

  /// No description provided for @groceryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get groceryDelete;

  /// No description provided for @groceryDeleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get groceryDeleteList;

  /// No description provided for @groceryCouldNotLoadList.
  ///
  /// In en, this message translates to:
  /// **'Could not load list.'**
  String get groceryCouldNotLoadList;

  /// No description provided for @groceryDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get groceryDeleteAll;

  /// No description provided for @groceryCategoryAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get groceryCategoryAlcohol;

  /// No description provided for @groceryCategoryBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get groceryCategoryBaby;

  /// No description provided for @groceryCategoryBakingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Baking Ingredients'**
  String get groceryCategoryBakingIngredients;

  /// No description provided for @groceryCategoryBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get groceryCategoryBakery;

  /// No description provided for @groceryCategoryCannedGoods.
  ///
  /// In en, this message translates to:
  /// **'Canned & Jarred Goods'**
  String get groceryCategoryCannedGoods;

  /// No description provided for @groceryCategoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get groceryCategoryElectronics;

  /// No description provided for @groceryCategoryReadyMeals.
  ///
  /// In en, this message translates to:
  /// **'Ready Meals'**
  String get groceryCategoryReadyMeals;

  /// No description provided for @groceryCategoryFish.
  ///
  /// In en, this message translates to:
  /// **'Fish & Seafood'**
  String get groceryCategoryFish;

  /// No description provided for @groceryCategoryMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get groceryCategoryMeat;

  /// No description provided for @groceryCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get groceryCategoryHealth;

  /// No description provided for @groceryCategoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get groceryCategoryBeverages;

  /// No description provided for @groceryCategoryCondiments.
  ///
  /// In en, this message translates to:
  /// **'Condiments, Sauces & Oils'**
  String get groceryCategoryCondiments;

  /// No description provided for @groceryCategoryHomeGarden.
  ///
  /// In en, this message translates to:
  /// **'Home & Garden'**
  String get groceryCategoryHomeGarden;

  /// No description provided for @groceryCategoryPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get groceryCategoryPets;

  /// No description provided for @groceryCategoryCoffeeTea.
  ///
  /// In en, this message translates to:
  /// **'Coffee & Tea'**
  String get groceryCategoryCoffeeTea;

  /// No description provided for @groceryCategoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get groceryCategoryClothing;

  /// No description provided for @groceryCategoryCosmeticsHygiene.
  ///
  /// In en, this message translates to:
  /// **'Cosmetics & Hygiene'**
  String get groceryCategoryCosmeticsHygiene;

  /// No description provided for @groceryCategoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get groceryCategoryDairy;

  /// No description provided for @groceryCategoryProduce.
  ///
  /// In en, this message translates to:
  /// **'Fruits & Vegetables'**
  String get groceryCategoryProduce;

  /// No description provided for @groceryCategoryCleaningLaundry.
  ///
  /// In en, this message translates to:
  /// **'Cleaning & Laundry'**
  String get groceryCategoryCleaningLaundry;

  /// No description provided for @groceryCategoryStationery.
  ///
  /// In en, this message translates to:
  /// **'Stationery'**
  String get groceryCategoryStationery;

  /// No description provided for @groceryCategorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks & Sweets'**
  String get groceryCategorySnacks;

  /// No description provided for @groceryCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get groceryCategoryOther;

  /// No description provided for @groceryCategoryFrozenFoods.
  ///
  /// In en, this message translates to:
  /// **'Frozen Foods'**
  String get groceryCategoryFrozenFoods;

  /// No description provided for @groceryCategoryDryGoods.
  ///
  /// In en, this message translates to:
  /// **'Dry Goods'**
  String get groceryCategoryDryGoods;
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

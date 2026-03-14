// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Home';

  @override
  String get navHome => 'Home';

  @override
  String get navGrocery => 'Grocery';

  @override
  String get navChore => 'Chore';

  @override
  String get navFinance => 'Finance';

  @override
  String get navSettings => 'Settings';

  @override
  String get authLogin => 'Login';

  @override
  String get authRegister => 'Register';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authUsername => 'Username';

  @override
  String get authPleaseWait => 'Please wait...';

  @override
  String get authSignupPrompt => 'Don\'t have an account? Register';

  @override
  String get authLoginPrompt => 'Already have an account? Login';

  @override
  String get authSignupSuccess =>
      'Registration successful! Please check your email.';

  @override
  String authSignoutError(String error) {
    return 'Could not sign out: $error';
  }

  @override
  String authUnexpectedError(String error) {
    return 'Unexpected error occurred: $error';
  }

  @override
  String get groceryMyLists => 'My lists';

  @override
  String get groceryNoLists => 'No lists available.';

  @override
  String get groceryAddItem => 'Add an item...';

  @override
  String get groceryAdd => 'ADD';

  @override
  String get groceryEditItem => 'Edit Item';

  @override
  String get groceryQuantity => 'Quantity';

  @override
  String get grocerySaveChanges => 'Save Changes';

  @override
  String get groceryEmptyList => 'Your list is empty';

  @override
  String get groceryBoughtItems => 'Bought Items';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLoggingOut => 'Signing out...';

  @override
  String get settingsAttributions => 'Attributions';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String groceryItemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get groceryDeleteSelected => 'Delete selected';

  @override
  String get groceryMoveToAnotherList => 'Move to another list';

  @override
  String get groceryCancel => 'Cancel';

  @override
  String get groceryNoOtherListAvailable => 'No other list available.';

  @override
  String get grocerySelectDestinationList => 'Select destination list';

  @override
  String get groceryDefaultListName => 'Shopping list';

  @override
  String get groceryDeleteListQuestion => 'Delete list?';

  @override
  String groceryDeleteListWarning(String listName) {
    return 'The list \"$listName\" will be deleted permanently.';
  }

  @override
  String get groceryDelete => 'Delete';

  @override
  String get groceryDeleteList => 'Delete list';

  @override
  String get groceryCouldNotLoadList => 'Could not load list.';

  @override
  String get groceryDeleteAll => 'Delete all';

  @override
  String get groceryCategoryProduce => 'Fruits & Vegetables';

  @override
  String get groceryCategoryDairy => 'Dairy';

  @override
  String get groceryCategoryBakery => 'Bakery';

  @override
  String get groceryCategoryDrinks => 'Drinks';

  @override
  String get groceryCategorySnacks => 'Snacks & Sweets';

  @override
  String get groceryCategoryCare => 'Care & Cleaning';

  @override
  String get groceryCategoryMeat => 'Meat & Fish';

  @override
  String get groceryCategoryOther => 'Other';
}

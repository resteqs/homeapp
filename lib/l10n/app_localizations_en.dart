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
  String get authFirstName => 'Name';

  @override
  String get authSurname => 'Surname';

  @override
  String get authNameRequired => 'Please enter your name and surname.';

  @override
  String get authPleaseWait => 'Please wait...';

  @override
  String get authSignupPrompt => 'Don\'t have an account? Register';

  @override
  String get authLoginPrompt => 'Already have an account? Login';

  @override
  String get authLoginSubtitle => 'Welcome back. Sign in to continue.';

  @override
  String get authRegisterSubtitle => 'Create your account to get started.';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authGoogle => 'Google';

  @override
  String get authApple => 'Apple';

  @override
  String authContinueInBrowser(String provider) {
    return 'Continue with $provider in your browser.';
  }

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
  String get groceryAddProduct => 'Add product';

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
  String get settingsGroceryCategoryOrder => 'Grocery category order';

  @override
  String get settingsGroceryCategoryOrderHint =>
      'Drag categories to match the order you usually walk through the supermarket.';

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
  String get groceryCategoryAlcohol => 'Alcohol';

  @override
  String get groceryCategoryBaby => 'Baby';

  @override
  String get groceryCategoryBakingIngredients => 'Baking Ingredients';

  @override
  String get groceryCategoryBakery => 'Bakery';

  @override
  String get groceryCategoryCannedGoods => 'Canned & Jarred Goods';

  @override
  String get groceryCategoryElectronics => 'Electronics';

  @override
  String get groceryCategoryReadyMeals => 'Ready Meals';

  @override
  String get groceryCategoryFish => 'Fish & Seafood';

  @override
  String get groceryCategoryMeat => 'Meat';

  @override
  String get groceryCategoryHealth => 'Health';

  @override
  String get groceryCategoryBeverages => 'Beverages';

  @override
  String get groceryCategoryCondiments => 'Condiments, Sauces & Oils';

  @override
  String get groceryCategoryHomeGarden => 'Home & Garden';

  @override
  String get groceryCategoryPets => 'Pets';

  @override
  String get groceryCategoryCoffeeTea => 'Coffee & Tea';

  @override
  String get groceryCategoryClothing => 'Clothing';

  @override
  String get groceryCategoryCosmeticsHygiene => 'Cosmetics & Hygiene';

  @override
  String get groceryCategoryDairy => 'Dairy & Eggs';

  @override
  String get groceryCategoryProduce => 'Fruits & Vegetables';

  @override
  String get groceryCategoryCleaningLaundry => 'Cleaning & Laundry';

  @override
  String get groceryCategoryStationery => 'Stationery';

  @override
  String get groceryCategorySnacks => 'Snacks & Sweets';

  @override
  String get groceryCategoryOther => 'Other';

  @override
  String get groceryCategoryFrozenFoods => 'Frozen Foods';

  @override
  String get groceryCategoryDryGoods => 'Dry Goods';
}

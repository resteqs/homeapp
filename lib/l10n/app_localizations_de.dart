// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Startseite';

  @override
  String get navHome => 'Startseite';

  @override
  String get navGrocery => 'Einkaufen';

  @override
  String get navChore => 'Hausarbeit';

  @override
  String get navFinance => 'Finanzen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get authLogin => 'Einloggen';

  @override
  String get authRegister => 'Registrieren';

  @override
  String get authEmail => 'E-Mail';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authFirstName => 'Vorname';

  @override
  String get authSurname => 'Nachname';

  @override
  String get authNameRequired => 'Bitte gib deinen Vor- und Nachnamen ein.';

  @override
  String get authPleaseWait => 'Bitte warten...';

  @override
  String get authSignupPrompt => 'Noch kein Konto? Registrieren';

  @override
  String get authLoginPrompt => 'Bereits ein Konto? Einloggen';

  @override
  String get authLoginSubtitle =>
      'Willkommen zuruck. Melde dich an, um weiterzumachen.';

  @override
  String get authRegisterSubtitle => 'Erstelle dein Konto, um zu starten.';

  @override
  String get authOrContinueWith => 'oder weiter mit';

  @override
  String get authContinueWithGoogle => 'Mit Google fortfahren';

  @override
  String get authContinueWithApple => 'Mit Apple fortfahren';

  @override
  String get authGoogle => 'Google';

  @override
  String get authApple => 'Apple';

  @override
  String authContinueInBrowser(String provider) {
    return 'Fahre mit $provider im Browser fort.';
  }

  @override
  String get authSignupSuccess =>
      'Registrierung erfolgreich! Bitte überprüfen Sie Ihre E-Mail.';

  @override
  String authSignoutError(String error) {
    return 'Abmelden fehlgeschlagen: $error';
  }

  @override
  String authUnexpectedError(String error) {
    return 'Unerwarteter Fehler aufgetreten: $error';
  }

  @override
  String get groceryMyLists => 'Meine Listen';

  @override
  String get groceryNoLists => 'Keine Listen verfügbar.';

  @override
  String get groceryAddItem => 'Element hinzufügen...';

  @override
  String get groceryAddProduct => 'Produkt hinzufügen';

  @override
  String get groceryAdd => 'HINZUFÜGEN';

  @override
  String get groceryEditItem => 'Element bearbeiten';

  @override
  String get groceryQuantity => 'Menge';

  @override
  String get grocerySaveChanges => 'Änderungen speichern';

  @override
  String get groceryEmptyList => 'Ihre Liste ist leer';

  @override
  String get groceryBoughtItems => 'Gekaufte Artikel';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLogout => 'Abmelden';

  @override
  String get settingsLoggingOut => 'Abmelden...';

  @override
  String get settingsAttributions => 'Namennennung';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsGroceryCategoryOrder =>
      'Reihenfolge der Einkaufskategorien';

  @override
  String get settingsGroceryCategoryOrderHint =>
      'Ziehe die Kategorien so, wie du normalerweise durch den Supermarkt gehst.';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String groceryItemsSelected(int count) {
    return '$count Artikel ausgewählt';
  }

  @override
  String get groceryDeleteSelected => 'Ausgewählte löschen';

  @override
  String get groceryMoveToAnotherList => 'In andere Liste verschieben';

  @override
  String get groceryCancel => 'Abbrechen';

  @override
  String get groceryNoOtherListAvailable => 'Keine andere Liste verfügbar.';

  @override
  String get grocerySelectDestinationList => 'Zielliste auswählen';

  @override
  String get groceryDefaultListName => 'Einkaufsliste';

  @override
  String get groceryDeleteListQuestion => 'Liste löschen?';

  @override
  String groceryDeleteListWarning(String listName) {
    return 'Die Liste \"$listName\" wird dauerhaft gelöscht.';
  }

  @override
  String get groceryDelete => 'Löschen';

  @override
  String get groceryDeleteList => 'Liste löschen';

  @override
  String get groceryCouldNotLoadList => 'Liste konnte nicht geladen werden.';

  @override
  String get groceryDeleteAll => 'Alle löschen';

  @override
  String get groceryCategoryAlcohol => 'Alkohol';

  @override
  String get groceryCategoryBaby => 'Baby';

  @override
  String get groceryCategoryBakingIngredients => 'Backzutaten';

  @override
  String get groceryCategoryBakery => 'Bäckerei';

  @override
  String get groceryCategoryCannedGoods => 'Dosen und Gläser';

  @override
  String get groceryCategoryElectronics => 'Elektronik';

  @override
  String get groceryCategoryReadyMeals => 'Fertiggerichte';

  @override
  String get groceryCategoryFish => 'Fisch und Meeresfrüchte';

  @override
  String get groceryCategoryMeat => 'Fleisch';

  @override
  String get groceryCategoryHealth => 'Gesundheit';

  @override
  String get groceryCategoryBeverages => 'Getränke';

  @override
  String get groceryCategoryCondiments => 'Gewürze, Saucen, Öle';

  @override
  String get groceryCategoryHomeGarden => 'Haus und Garten';

  @override
  String get groceryCategoryPets => 'Haustiere';

  @override
  String get groceryCategoryCoffeeTea => 'Kaffee und Tee';

  @override
  String get groceryCategoryClothing => 'Kleidung';

  @override
  String get groceryCategoryCosmeticsHygiene => 'Kosmetik und Hygiene';

  @override
  String get groceryCategoryDairy => 'Milchprodukte und Eier';

  @override
  String get groceryCategoryProduce => 'Obst und Gemüse';

  @override
  String get groceryCategoryCleaningLaundry => 'Reinigung und Wäsche';

  @override
  String get groceryCategoryStationery => 'Schreibwaren';

  @override
  String get groceryCategorySnacks => 'Snacks und Süßigkeiten';

  @override
  String get groceryCategoryOther => 'Sonstiges';

  @override
  String get groceryCategoryFrozenFoods => 'Tiefkühlkost';

  @override
  String get groceryCategoryDryGoods => 'Trockene Waren';
}

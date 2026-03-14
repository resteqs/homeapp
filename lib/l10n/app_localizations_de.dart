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
  String get authUsername => 'Benutzername';

  @override
  String get authPleaseWait => 'Bitte warten...';

  @override
  String get authSignupPrompt => 'Noch kein Konto? Registrieren';

  @override
  String get authLoginPrompt => 'Bereits ein Konto? Einloggen';

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
  String get groceryCategoryProduce => 'Obst & Gemüse';

  @override
  String get groceryCategoryDairy => 'Milchprodukte';

  @override
  String get groceryCategoryBakery => 'Bäckerei';

  @override
  String get groceryCategoryDrinks => 'Getränke';

  @override
  String get groceryCategorySnacks => 'Snacks & Süßes';

  @override
  String get groceryCategoryCare => 'Pflege & Reinigung';

  @override
  String get groceryCategoryMeat => 'Fleisch & Fisch';

  @override
  String get groceryCategoryOther => 'Sonstiges';
}

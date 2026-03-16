import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homeapp/main.dart';
import 'package:homeapp/utils/category_utils.dart';
import 'dart:ui' as ui;


/// Global app state for theme and locale.
///
/// Locale is persisted via SharedPreferences so language selection survives app
/// restarts.
class AppState extends ChangeNotifier {
  AppState();

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeMode _themeMode = _loadThemeMode();
  ThemeMode get themeMode => _themeMode;

  static ThemeMode _loadThemeMode() {
    final modeString = sharedPrefs.getString('themeMode');
    if (modeString == 'light') return ThemeMode.light;
    if (modeString == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Locale _locale = _loadLocale();
  List<String> _categoryOrder = _loadCategoryOrder();

  static Locale _loadLocale() {
    final langCode = sharedPrefs.getString('languageCode');
    if (langCode != null && langCode.isNotEmpty) {
      return Locale(langCode);
    }
    return ui.PlatformDispatcher.instance.locale;
  }

  Locale get locale => _locale;

  List<String> get categoryOrder => List<String>.unmodifiable(_categoryOrder);

  static List<String> _loadCategoryOrder() {
    return CategoryUtils.normalizedCategoryOrder(
      sharedPrefs.getStringList('groceryCategoryOrder'),
    );
  }

  /// Updates locale and persists the language code.
  void setLocale(Locale newLocale) {
    _locale = newLocale;
    sharedPrefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }

  /// Updates grocery category ordering and persists it for future sessions.
  void setCategoryOrder(List<String> newOrder) {
    _categoryOrder = CategoryUtils.normalizedCategoryOrder(newOrder);
    sharedPrefs.setStringList('groceryCategoryOrder', _categoryOrder);
    notifyListeners();
  }

  /// Updates theme mode and persists it.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    final modeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    sharedPrefs.setString('themeMode', modeString);
    notifyListeners();
  }
}

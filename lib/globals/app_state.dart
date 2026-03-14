import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:provider/provider.dart';
import 'package:homeapp/globals/themes.dart';
import 'package:homeapp/main.dart';
import 'dart:ui' as ui;

@NowaGenerated()
class AppState extends ChangeNotifier {
  AppState();

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = lightTheme;
  ThemeData get theme => _theme;

  Locale _locale = _loadLocale();

  static Locale _loadLocale() {
    final langCode = sharedPrefs.getString('languageCode');
    if (langCode != null && langCode.isNotEmpty) {
      return Locale(langCode);
    }
    return ui.PlatformDispatcher.instance.locale;
  }

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    sharedPrefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }

  void changeTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }
}

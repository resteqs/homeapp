import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

/// Centralized color tokens for the whole app.
///
/// Use these tokens directly (or via [Theme.of(context).colorScheme]) instead
/// of hardcoded color literals in widgets.
abstract final class AppColors {
  // Reduced green shades for a cleaner visual hierarchy.
  static const Color greenDark = Color(0xFF006400);
  static const Color greenMain = Color(0xFF38B000);
  static const Color greenLight = Color(0xFF9EF01A);

  // Neutral grays for readable surfaces, dividers, and inactive states.
  static const Color gray700 = Color(0xFF6B7280);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);

  // Contrast/action colors.
  static const Color blueMain = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFDBEAFE);
  static const Color redMain = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFEE2E2);

  // Core neutrals.
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Utility tokens used across widgets.
  static const Color transparent = Color(0x00000000);

  // Semantic aliases for readability in UI code.
  static const Color pageBackgroundLight = white;
  static const Color pageBackgroundDark = white;
  static const Color surfaceLight = white;
  static const Color surfaceDark = white;
  static const Color accent = Color.fromARGB(255, 73, 131, 255);
  static const Color accentStrong = greenMain;
  static const Color textOnLight = black;
  static const Color textOnDark = black;
}

/// Centralized category colors so category visuals never hardcode values.
abstract final class AppCategoryColors {
  static const Color produce = AppColors.greenMain;
  static const Color meat = AppColors.greenDark;
  static const Color fish = AppColors.greenLight;
  static const Color dairy = AppColors.greenLight;
  static const Color bakery = AppColors.greenDark;
  static const Color bakingIngredients = AppColors.greenDark;
  static const Color dryGoods = AppColors.greenMain;
  static const Color cannedGoods = AppColors.greenMain;
  static const Color frozenFoods = AppColors.greenLight;
  static const Color beverages = AppColors.greenMain;
  static const Color coffeeTea = AppColors.greenDark;
  static const Color snacks = AppColors.greenMain;
  static const Color condiments = AppColors.greenDark;
  static const Color health = AppColors.greenLight;
  static const Color cosmetics = AppColors.greenLight;
  static const Color cleaning = AppColors.greenDark;
  static const Color homeGarden = AppColors.greenMain;
  static const Color electronics = AppColors.gray700;
  static const Color baby = AppColors.greenLight;
  static const Color pets = AppColors.greenMain;
  static const Color readyMeals = AppColors.greenMain;
  static const Color alcohol = AppColors.greenDark;
  static const Color clothing = AppColors.gray700;
  static const Color stationery = AppColors.gray700;
  static const Color other = AppColors.gray700;
}

ThemeData _buildLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.accent,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.accentStrong,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.greenLight,
    onSecondaryContainer: AppColors.black,
    tertiary: AppColors.greenDark,
    onTertiary: AppColors.black,
    tertiaryContainer: AppColors.greenLight,
    onTertiaryContainer: AppColors.black,
    error: AppColors.redMain,
    onError: AppColors.white,
    errorContainer: AppColors.redLight,
    onErrorContainer: AppColors.redMain,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textOnLight,
    onSurfaceVariant: AppColors.gray700,
    outline: AppColors.gray300,
    outlineVariant: AppColors.gray200,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.white,
    onInverseSurface: AppColors.black,
    inversePrimary: AppColors.blueMain,
    surfaceTint: AppColors.accent,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.white,
    surfaceContainer: AppColors.gray100,
    surfaceContainerHigh: AppColors.gray100,
    surfaceContainerHighest: AppColors.gray100,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBackgroundLight,
    colorScheme: colorScheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.blueMain,
      linearTrackColor: AppColors.gray200,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: AppColors.textOnLight,
      displayColor: AppColors.textOnLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pageBackgroundLight,
      foregroundColor: AppColors.textOnLight,
      elevation: 0,
    ),
  );
}

ThemeData _buildDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.blueLight,
    onPrimaryContainer: AppColors.black,
    secondary: AppColors.accentStrong,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.greenLight,
    onSecondaryContainer: AppColors.black,
    tertiary: AppColors.greenDark,
    onTertiary: AppColors.black,
    tertiaryContainer: AppColors.greenLight,
    onTertiaryContainer: AppColors.black,
    error: AppColors.redMain,
    onError: AppColors.white,
    errorContainer: AppColors.redLight,
    onErrorContainer: AppColors.redMain,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textOnDark,
    onSurfaceVariant: AppColors.gray700,
    outline: AppColors.gray300,
    outlineVariant: AppColors.gray200,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.white,
    onInverseSurface: AppColors.black,
    inversePrimary: AppColors.accent,
    surfaceTint: AppColors.accent,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.white,
    surfaceContainer: AppColors.gray100,
    surfaceContainerHigh: AppColors.gray100,
    surfaceContainerHighest: AppColors.gray100,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBackgroundDark,
    colorScheme: colorScheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.blueMain,
      linearTrackColor: AppColors.gray200,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: AppColors.textOnDark,
      displayColor: AppColors.textOnDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pageBackgroundDark,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
    ),
  );
}

@NowaGenerated()
final ThemeData lightTheme = _buildLightTheme();

@NowaGenerated()
final ThemeData darkTheme = _buildDarkTheme();

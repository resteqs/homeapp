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
  static const Color produce = Color(0xFF2E7D32);
  static const Color meat = Color(0xFFC62828);
  static const Color fish = Color(0xFF1565C0);
  static const Color dairy = Color(0xFF0D9488);
  static const Color bakery = Color(0xFFB45309);
  static const Color bakingIngredients = Color(0xFFEA580C);
  static const Color dryGoods = Color(0xFF8D6E63);
  static const Color cannedGoods = Color(0xFF475569);
  static const Color frozenFoods = Color(0xFF0EA5E9);
  static const Color beverages = Color(0xFF0284C7);
  static const Color coffeeTea = Color(0xFF6D4C41);
  static const Color snacks = Color(0xFFD97706);
  static const Color condiments = Color(0xFFEF4444);
  static const Color health = Color(0xFF16A34A);
  static const Color cosmetics = Color(0xFFDB2777);
  static const Color cleaning = Color(0xFF06B6D4);
  static const Color homeGarden = Color(0xFF65A30D);
  static const Color electronics = Color(0xFF4F46E5);
  static const Color baby = Color(0xFFEC4899);
  static const Color pets = Color(0xFF7C3AED);
  static const Color readyMeals = Color(0xFFFB7185);
  static const Color alcohol = Color(0xFF9333EA);
  static const Color clothing = Color(0xFF0EA5A4);
  static const Color stationery = Color(0xFF0369A1);
  static const Color other = Color(0xFF64748B);
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
    surfaceTint: AppColors.greenLight,
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

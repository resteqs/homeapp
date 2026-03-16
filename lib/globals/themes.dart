import 'package:flutter/material.dart';

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
    primary: Color(0xFF4F772D),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCDE6B9),
    onPrimaryContainer: Color(0xFF223313),
    secondary: Color(0xFF4F772D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCDE6B9),
    onSecondaryContainer: Color(0xFF223313),
    tertiary: Color(0xFFBC4749),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6B9B9),
    onTertiaryContainer: Color(0xFF331314),
    error: Color(0xFFBC4749),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE6B9B9),
    onErrorContainer: Color(0xFF331314),
    surface: Color(0xFFfcfcfc),
    onSurface: Color(0xFF323331),
    surfaceTint: Color(0xFF4F772D), // Matches primary
    surfaceContainerHighest: Color(0xFFe1e6dd), // Replaces surfaceVariant
    onSurfaceVariant: Color(0xFF5f6659),
    outline: Color(0xFF8f9986),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFC3E6A6),
    onPrimary: Color(0xFF324C1D),
    primaryContainer: Color(0xFF436627),
    onPrimaryContainer: Color(0xFFCDE6B9),
    secondary: Color(0xFFC3E6A6),
    onSecondary: Color(0xFF324C1D),
    secondaryContainer: Color(0xFF436627),
    onSecondaryContainer: Color(0xFFCDE6B9),
    tertiary: Color(0xFFE6A6A7),
    onTertiary: Color(0xFF4C1D1E),
    tertiaryContainer: Color(0xFF662728),
    onTertiaryContainer: Color(0xFFE6B9B9),
    error: Color(0xFFE6C78E),
    onError: Color(0xFF4C360B),
    errorContainer: Color(0xFF66470F),
    onErrorContainer: Color(0xFFE6D0A8),
    surface: Color(0xFF323331),
    onSurface: Color(0xFFe4e6e3),
    surfaceTint: Color(0xFFC3E6A6), // Matches primary
    surfaceContainerHighest: Color(0xFF5f6659), // Replaces surfaceVariant
    onSurfaceVariant: Color(0xFFdfe6d9),
    outline: Color(0xFFabb3a5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

final ThemeData lightTheme = _buildLightTheme();
final ThemeData darkTheme = _buildDarkTheme();

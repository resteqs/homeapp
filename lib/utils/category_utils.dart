import 'package:flutter/material.dart';
import 'package:homeapp/l10n/app_localizations.dart';

class CategoryVisual {
  const CategoryVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}

class CategoryUtils {
  static String categoryKeyFromRaw(String rawCategory) {
    final category = rawCategory.toLowerCase();

    if (category.contains('obst') ||
        category.contains('gemu') ||
        category.contains('fruit') ||
        category.contains('veg')) {
      return 'produce';
    }

    if (category.contains('dairy') ||
        category.contains('milk') ||
        category.contains('kase') ||
        category.contains('käse') ||
        category.contains('milch')) {
      return 'dairy';
    }

    if (category.contains('bakery') ||
        category.contains('baker') ||
        category.contains('bread') ||
        category.contains('brot')) {
      return 'bakery';
    }

    if (category.contains('drink') ||
        category.contains('getrank') ||
        category.contains('getränk') ||
        category.contains('water') ||
        category.contains('wasser')) {
      return 'drinks';
    }

    if (category.contains('snack') || category.contains('sweet') || category.contains('su')) {
      return 'snacks';
    }

    if (category.contains('care') ||
        category.contains('clean') ||
        category.contains('reinigung') ||
        category.contains('hygiene') ||
        category.contains('pflege')) {
      return 'care';
    }

    if (category.contains('meat') ||
        category.contains('fleisch') ||
        category.contains('fish') ||
        category.contains('fisch') ||
        category.contains('deli')) {
      return 'meat';
    }

    return 'other';
  }

  static String localizedCategoryName(BuildContext context, String categoryKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case 'produce':
        return l10n.groceryCategoryProduce;
      case 'dairy':
        return l10n.groceryCategoryDairy;
      case 'bakery':
        return l10n.groceryCategoryBakery;
      case 'drinks':
        return l10n.groceryCategoryDrinks;
      case 'snacks':
        return l10n.groceryCategorySnacks;
      case 'care':
        return l10n.groceryCategoryCare;
      case 'meat':
        return l10n.groceryCategoryMeat;
      default:
        return l10n.groceryCategoryOther;
    }
  }

  static CategoryVisual getCategoryVisual(String categoryKey) {
    switch (categoryKey) {
      case 'produce':
        return const CategoryVisual(Icons.eco, Color(0xFF3A9D23));
      case 'dairy':
        return const CategoryVisual(Icons.local_drink, Color(0xFF2A76D2));
      case 'bakery':
        return const CategoryVisual(Icons.bakery_dining, Color(0xFFD18B2A));
      case 'drinks':
        return const CategoryVisual(Icons.water_drop, Color(0xFF1C9CEB));
      case 'snacks':
        return const CategoryVisual(Icons.cookie, Color(0xFFE07D26));
      case 'care':
        return const CategoryVisual(Icons.clean_hands, Color(0xFF8E57D6));
      case 'meat':
        return const CategoryVisual(Icons.set_meal, Color(0xFFDB4A39));
      default:
        return const CategoryVisual(Icons.category, Color(0xFF5F6D7A));
    }
  }
}

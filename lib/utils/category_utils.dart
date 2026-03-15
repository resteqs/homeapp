import 'package:flutter/material.dart';
import 'package:homeapp/globals/themes.dart';
import 'package:homeapp/l10n/app_localizations.dart';

class CategoryVisual {
  const CategoryVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Helpers for mapping raw category labels to app category keys, localized
/// labels, and display visuals.
///
/// Category keys correspond directly to the canonical category keys used by the
/// generated offline catalog (for example `fruits_vegetables`, `meat`,
/// `dry_goods`). Raw values stored in [GroceryItem.category] may be a
/// canonical key, a localized category name, or a legacy value;
/// [categoryKeyFromRaw] normalises all of these to the canonical key.
class CategoryUtils {
  static final Map<String, String> _cache = {};

  /// The set of canonical category keys used throughout the app.
  static const Set<String> knownKeys = {
    'alcohol',
    'baby',
    'baking_ingredients',
    'bakery',
    'canned_goods',
    'electronics',
    'ready_meals',
    'fish',
    'meat',
    'health',
    'beverages',
    'condiments_spices',
    'home_garden',
    'pets',
    'coffee_tea',
    'clothing',
    'cosmetics_hygiene',
    'dairy_eggs',
    'fruits_vegetables',
    'cleaning_laundry',
    'stationery',
    'snacks_sweets',
    'other',
    'frozen_foods',
    'dry_goods',
  };

  /// Normalises a raw category value (DB key, localized name, or legacy
  /// string) to a canonical category key.
  static String categoryKeyFromRaw(String rawCategory) {
    if (_cache.containsKey(rawCategory)) return _cache[rawCategory]!;

    // Fast path: already a known canonical key.
    if (knownKeys.contains(rawCategory)) {
      _cache[rawCategory] = rawCategory;
      return rawCategory;
    }

    final c = rawCategory.toLowerCase();

    // --- Fruits & Vegetables ---
    if (c.contains('obst') ||
        c.contains('gemüse') ||
        c.contains('gemu') ||
        c.contains('fruit') ||
        c.contains('vegetable') ||
        c.contains('veg')) {
      return _cache[rawCategory] = 'fruits_vegetables';
    }

    // --- Meat ---
    if (c.contains('fleisch') ||
        c.contains('meat') ||
        // legacy "Fleisch & Fisch" / "Meat & Fish"
        (c.contains('fisch') && c.contains('fleisch'))) {
      return _cache[rawCategory] = 'meat';
    }

    // --- Fish & Seafood ---
    if (c.contains('fisch') ||
        c.contains('meeresfrüchte') ||
        c.contains('meeresfruchte') ||
        c.contains('fish') ||
        c.contains('seafood')) {
      return _cache[rawCategory] = 'fish';
    }

    // --- Dairy & Eggs ---
    if (c.contains('milch') ||
        c.contains('milchprodukt') ||
        c.contains('dairy') ||
        c.contains('käse') ||
        c.contains('kase') ||
        c.contains('eier') ||
        c.contains('eggs')) {
      return _cache[rawCategory] = 'dairy_eggs';
    }

    // --- Bakery ---
    if (c.contains('bäckerei') ||
        c.contains('backerei') ||
        c.contains('bakery') ||
        c.contains('brot') ||
        c.contains('bread') ||
        // legacy "Backwaren & Brot"
        c.contains('backwar')) {
      return _cache[rawCategory] = 'bakery';
    }

    // --- Baking Ingredients ---
    if (c.contains('backzutat') ||
        c.contains('baking ingredient') ||
        c.contains('mehl') ||
        c.contains('flour') ||
        c.contains('backpulver') ||
        c.contains('baking powder')) {
      return _cache[rawCategory] = 'baking_ingredients';
    }

    // --- Dry Goods ---
    if (c.contains('trockene') ||
        c.contains('dry good') ||
        c.contains('vorrat') ||
        // legacy "Pantry & Dry Goods" / "Vorrat & Trockenwaren"
        c.contains('pantry') ||
        c.contains('trockenwaren')) {
      return _cache[rawCategory] = 'dry_goods';
    }

    // --- Canned & Jarred Goods ---
    if (c.contains('dosen') ||
        c.contains('gläser') ||
        c.contains('glaser') ||
        c.contains('canned') ||
        c.contains('jarred')) {
      return _cache[rawCategory] = 'canned_goods';
    }

    // --- Frozen Foods ---
    if (c.contains('tiefkühl') ||
        c.contains('tiefkuhl') ||
        c.contains('frozen')) {
      return _cache[rawCategory] = 'frozen_foods';
    }

    // --- Coffee & Tea ---
    if (c.contains('kaffee') ||
        c.contains('coffee') ||
        (c.contains('tee') && !c.contains('getränke')) ||
        c.contains('tea')) {
      return _cache[rawCategory] = 'coffee_tea';
    }

    // --- Beverages ---
    if (c.contains('getränke') ||
        c.contains('getränk') ||
        c.contains('getrank') ||
        c.contains('beverage') ||
        c.contains('drink') ||
        c.contains('wasser') ||
        c.contains('water') ||
        c.contains('saft') ||
        c.contains('juice')) {
      return _cache[rawCategory] = 'beverages';
    }

    // --- Snacks & Sweets ---
    if (c.contains('snack') ||
        c.contains('süßigkeit') ||
        c.contains('sussigkeit') ||
        c.contains('süß') ||
        c.contains('sweet') ||
        c.contains('chips')) {
      return _cache[rawCategory] = 'snacks_sweets';
    }

    // --- Condiments, Sauces & Oils ---
    if (c.contains('gewürz') ||
        c.contains('gewurz') ||
        c.contains('saucen') ||
        c.contains('öle') ||
        c.contains('condiment') ||
        c.contains('spice') ||
        c.contains('sauce') ||
        c.contains('oil') ||
        c.contains('ol') ||
        // legacy "Gewürze & Saucen"
        c.contains('international') ||
        c.contains('küche')) {
      return _cache[rawCategory] = 'condiments_spices';
    }

    // --- Health ---
    if (c.contains('gesundheit') ||
        c.contains('health') ||
        c.contains('vitamin') ||
        c.contains('medizin') ||
        c.contains('medic')) {
      return _cache[rawCategory] = 'health';
    }

    // --- Cosmetics & Hygiene ---
    if (c.contains('kosmetik') ||
        c.contains('hygiene') ||
        c.contains('cosmetic') ||
        c.contains('pflege') ||
        c.contains('shampoo') ||
        c.contains('seife') ||
        c.contains('soap')) {
      return _cache[rawCategory] = 'cosmetics_hygiene';
    }

    // --- Cleaning & Laundry ---
    if (c.contains('reinigung') ||
        c.contains('wäsche') ||
        c.contains('wasche') ||
        c.contains('cleaning') ||
        c.contains('laundry') ||
        c.contains('waschmittel') ||
        // legacy "Pflege & Reinigung" / "Care & Cleaning"
        c.contains('care')) {
      return _cache[rawCategory] = 'cleaning_laundry';
    }

    // --- Home & Garden ---
    if (c.contains('haus') ||
        c.contains('garten') ||
        c.contains('home') ||
        c.contains('garden') ||
        c.contains('haushalt') ||
        // legacy "Household & Cleaning"
        c.contains('household')) {
      return _cache[rawCategory] = 'home_garden';
    }

    // --- Electronics ---
    if (c.contains('elektronik') || c.contains('electronic')) {
      return _cache[rawCategory] = 'electronics';
    }

    // --- Baby ---
    if (c.contains('baby') || c.contains('säugling') || c.contains('windel')) {
      return _cache[rawCategory] = 'baby';
    }

    // --- Pets ---
    if (c.contains('haustier') ||
        c.contains('tier') ||
        c.contains('pets') ||
        c.contains('haustierbedarf')) {
      return _cache[rawCategory] = 'pets';
    }

    // --- Ready Meals ---
    if (c.contains('fertiggericht') ||
        c.contains('ready meal') ||
        c.contains('feinkost') ||
        c.contains('deli')) {
      return _cache[rawCategory] = 'ready_meals';
    }

    // --- Alcohol ---
    if (c.contains('alkohol') ||
        c.contains('alcohol') ||
        c.contains('bier') ||
        c.contains('beer') ||
        c.contains('wein') ||
        c.contains('wine') ||
        c.contains('spirits')) {
      return _cache[rawCategory] = 'alcohol';
    }

    // --- Clothing ---
    if (c.contains('kleidung') || c.contains('clothing')) {
      return _cache[rawCategory] = 'clothing';
    }

    // --- Stationery ---
    if (c.contains('schreibwaren') || c.contains('stationery')) {
      return _cache[rawCategory] = 'stationery';
    }

    return _cache[rawCategory] = 'other';
  }

  /// Returns the localized display name for a canonical category [categoryKey].
  static String localizedCategoryName(
      BuildContext context, String categoryKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case 'alcohol':
        return l10n.groceryCategoryAlcohol;
      case 'baby':
        return l10n.groceryCategoryBaby;
      case 'baking_ingredients':
        return l10n.groceryCategoryBakingIngredients;
      case 'bakery':
        return l10n.groceryCategoryBakery;
      case 'canned_goods':
        return l10n.groceryCategoryCannedGoods;
      case 'electronics':
        return l10n.groceryCategoryElectronics;
      case 'ready_meals':
        return l10n.groceryCategoryReadyMeals;
      case 'fish':
        return l10n.groceryCategoryFish;
      case 'meat':
        return l10n.groceryCategoryMeat;
      case 'health':
        return l10n.groceryCategoryHealth;
      case 'beverages':
        return l10n.groceryCategoryBeverages;
      case 'condiments_spices':
        return l10n.groceryCategoryCondiments;
      case 'home_garden':
        return l10n.groceryCategoryHomeGarden;
      case 'pets':
        return l10n.groceryCategoryPets;
      case 'coffee_tea':
        return l10n.groceryCategoryCoffeeTea;
      case 'clothing':
        return l10n.groceryCategoryClothing;
      case 'cosmetics_hygiene':
        return l10n.groceryCategoryCosmeticsHygiene;
      case 'dairy_eggs':
        return l10n.groceryCategoryDairy;
      case 'fruits_vegetables':
        return l10n.groceryCategoryProduce;
      case 'cleaning_laundry':
        return l10n.groceryCategoryCleaningLaundry;
      case 'stationery':
        return l10n.groceryCategoryStationery;
      case 'snacks_sweets':
        return l10n.groceryCategorySnacks;
      case 'frozen_foods':
        return l10n.groceryCategoryFrozenFoods;
      case 'dry_goods':
        return l10n.groceryCategoryDryGoods;
      default:
        return l10n.groceryCategoryOther;
    }
  }

  static CategoryVisual getCategoryVisual(String categoryKey) {
    switch (categoryKey) {
      case 'fruits_vegetables':
        return const CategoryVisual(Icons.eco, AppCategoryColors.produce);
      case 'meat':
        return const CategoryVisual(Icons.set_meal, AppCategoryColors.meat);
      case 'fish':
        return const CategoryVisual(Icons.set_meal, AppCategoryColors.fish);
      case 'dairy_eggs':
        return const CategoryVisual(
            Icons.egg_outlined, AppCategoryColors.dairy);
      case 'bakery':
        return const CategoryVisual(
            Icons.bakery_dining, AppCategoryColors.bakery);
      case 'baking_ingredients':
        return const CategoryVisual(Icons.cake, AppCategoryColors.bakingIngredients);
      case 'dry_goods':
        return const CategoryVisual(Icons.grain, AppCategoryColors.dryGoods);
      case 'canned_goods':
        return const CategoryVisual(
            Icons.inventory_2, AppCategoryColors.cannedGoods);
      case 'frozen_foods':
        return const CategoryVisual(
            Icons.ac_unit, AppCategoryColors.frozenFoods);
      case 'beverages':
        return const CategoryVisual(
            Icons.water_drop, AppCategoryColors.beverages);
      case 'coffee_tea':
        return const CategoryVisual(
            Icons.coffee, AppCategoryColors.coffeeTea);
      case 'snacks_sweets':
        return const CategoryVisual(Icons.cookie, AppCategoryColors.snacks);
      case 'condiments_spices':
        return const CategoryVisual(
            Icons.restaurant, AppCategoryColors.condiments);
      case 'health':
        return const CategoryVisual(
            Icons.medical_services, AppCategoryColors.health);
      case 'cosmetics_hygiene':
        return const CategoryVisual(Icons.spa, AppCategoryColors.cosmetics);
      case 'cleaning_laundry':
        return const CategoryVisual(
            Icons.local_laundry_service, AppCategoryColors.cleaning);
      case 'home_garden':
        return const CategoryVisual(Icons.home, AppCategoryColors.homeGarden);
      case 'electronics':
        return const CategoryVisual(
            Icons.electrical_services, AppCategoryColors.electronics);
      case 'baby':
        return const CategoryVisual(
            Icons.child_care, AppCategoryColors.baby);
      case 'pets':
        return const CategoryVisual(Icons.pets, AppCategoryColors.pets);
      case 'ready_meals':
        return const CategoryVisual(
            Icons.lunch_dining, AppCategoryColors.readyMeals);
      case 'alcohol':
        return const CategoryVisual(
            Icons.local_bar, AppCategoryColors.alcohol);
      case 'clothing':
        return const CategoryVisual(
            Icons.checkroom, AppCategoryColors.clothing);
      case 'stationery':
        return const CategoryVisual(Icons.edit, AppCategoryColors.stationery);
      default:
        return const CategoryVisual(Icons.category, AppCategoryColors.other);
    }
  }
}


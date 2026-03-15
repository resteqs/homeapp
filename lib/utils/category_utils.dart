import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:homeapp/globals/themes.dart';
import 'package:homeapp/l10n/app_localizations.dart';

class CategoryVisual {
  const CategoryVisual(this.icon, this.color, {this.viewportSize = 18});

  final IconData icon;
  final Color color;
  final double viewportSize;
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

  /// Default category order based on a typical German supermarket path:
  /// produce first, then bakery/fresh counters, pantry aisles, beverages,
  /// and finally household/non-food sections.
  static const List<String> defaultCategoryOrder = <String>[
    'fruits_vegetables',
    'bakery',
    'dairy_eggs',
    'meat',
    'fish',
    'ready_meals',
    'frozen_foods',
    'dry_goods',
    'baking_ingredients',
    'canned_goods',
    'condiments_spices',
    'snacks_sweets',
    'coffee_tea',
    'beverages',
    'alcohol',
    'baby',
    'cosmetics_hygiene',
    'health',
    'cleaning_laundry',
    'home_garden',
    'pets',
    'stationery',
    'electronics',
    'clothing',
    'other',
  ];

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

  /// Normalises a persisted category order by removing unknown keys,
  /// de-duplicating entries, and appending any missing known categories.
  static List<String> normalizedCategoryOrder(Iterable<String>? rawOrder) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final categoryKey in rawOrder ?? const <String>[]) {
      if (!knownKeys.contains(categoryKey) || !seen.add(categoryKey)) {
        continue;
      }
      normalized.add(categoryKey);
    }

    for (final categoryKey in defaultCategoryOrder) {
      if (seen.add(categoryKey)) {
        normalized.add(categoryKey);
      }
    }

    return normalized;
  }

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

  /// Returns the icon and color pair for a canonical [categoryKey].
  static CategoryVisual getCategoryVisual(String categoryKey) {
    switch (categoryKey) {
      case 'fruits_vegetables':
        return const CategoryVisual(
          FontAwesomeIcons.carrot,
          Color.fromARGB(255, 255, 133, 12),
          viewportSize: 21,
        );
      case 'meat':
        return const CategoryVisual(FontAwesomeIcons.bacon, AppCategoryColors.meat);
      case 'fish':
        return const CategoryVisual(FontAwesomeIcons.fish, AppCategoryColors.fish);
      case 'dairy_eggs':
        return const CategoryVisual(
          FontAwesomeIcons.cow,
          Color.fromARGB(255, 111, 183, 177),
          viewportSize: 21,
        );
      case 'bakery':
        return const CategoryVisual(
            FontAwesomeIcons.breadSlice, AppCategoryColors.bakery);
      case 'baking_ingredients':
        return const CategoryVisual(FontAwesomeIcons.cakeCandles, Color.fromARGB(255, 125, 54, 13));
      case 'dry_goods':
        return const CategoryVisual(FontAwesomeIcons.bowlRice, Color.fromARGB(255, 140, 141, 99));
      case 'canned_goods':
        return const CategoryVisual(
            FontAwesomeIcons.jar, Color.fromARGB(255, 118, 76, 137));
      case 'frozen_foods':
        return const CategoryVisual(
            FontAwesomeIcons.snowflake, AppCategoryColors.frozenFoods);
      case 'beverages':
        return const CategoryVisual(
            FontAwesomeIcons.bottleWater, Color.fromARGB(255, 29, 116, 255));
      case 'coffee_tea':
        return const CategoryVisual(
          FontAwesomeIcons.mugHot,
          Color.fromARGB(255, 105, 87, 82),
          viewportSize: 19,
        );
      case 'snacks_sweets':
        return const CategoryVisual(FontAwesomeIcons.cookieBite, AppCategoryColors.snacks);
      case 'condiments_spices':
        return const CategoryVisual(
            FontAwesomeIcons.pepperHot, Color.fromARGB(255, 255, 0, 0));
      case 'health':
        return const CategoryVisual(
            FontAwesomeIcons.briefcaseMedical, Color.fromARGB(255, 246, 52, 52));
      case 'cosmetics_hygiene':
        return const CategoryVisual(FontAwesomeIcons.faceKiss, Color.fromARGB(255, 255, 18, 204));
      case 'cleaning_laundry':
        return const CategoryVisual(
            FontAwesomeIcons.jugDetergent, AppCategoryColors.cleaning);
      case 'home_garden':
        return const CategoryVisual(FontAwesomeIcons.house, AppCategoryColors.homeGarden);
      case 'electronics':
        return const CategoryVisual(
            FontAwesomeIcons.bolt, Color.fromARGB(255, 207, 207, 9));
      case 'baby':
        return const CategoryVisual(
            FontAwesomeIcons.babyCarriage, AppCategoryColors.baby);
      case 'pets':
        return const CategoryVisual(FontAwesomeIcons.paw, AppCategoryColors.pets);
      case 'ready_meals':
        return const CategoryVisual(
            FontAwesomeIcons.burger, AppCategoryColors.readyMeals);
      case 'alcohol':
        return const CategoryVisual(
            FontAwesomeIcons.martiniGlass, AppCategoryColors.alcohol);
      case 'clothing':
        return const CategoryVisual(
          FontAwesomeIcons.shirt,
          AppCategoryColors.clothing,
          viewportSize: 19,
        );
      case 'stationery':
        return const CategoryVisual(FontAwesomeIcons.pen, Color.fromARGB(255, 173, 168, 43));
      default:
        return const CategoryVisual(FontAwesomeIcons.shapes, AppCategoryColors.other);
    }
  }
}


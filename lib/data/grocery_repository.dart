import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:homeapp/data/grocery_catalog.dart';
import 'package:homeapp/data/local_grocery_store.dart';
import 'package:homeapp/models/grocery_item.dart';

/// Provider that manages grocery lists and their items.
///
/// This repository implements an offline-first data synchronization model by
/// integrating [LocalGroceryStore] (SQLite) and [SupabaseClient].
/// Changes hit the local DB first using [syncStatus] to track pending writes.
class GroceryRepository extends ChangeNotifier {
  GroceryRepository({
    required SupabaseClient supabase,
    required LocalGroceryStore localStore,
  })  : _supabase = supabase,
        _localStore = localStore;

  final SupabaseClient _supabase;
  final LocalGroceryStore _localStore;
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<GroceryItem> _items = const [];
  bool _isLoading = true;
  bool _isSyncing = false;
  // If sync is requested during an active run, trigger one more pass afterward
  // so no local mutations are skipped.
  bool _syncQueued = false;
  bool _queuedRemotePull = false;
  String? _lastError;
  String? _listId;
  DateTime? _lastRemotePullAt;
  Timer? _syncDebounceTimer;

  static const Duration _remotePullCooldown = Duration(seconds: 15);
  static const Duration _syncDebounceWindow = Duration(milliseconds: 350);

  List<GroceryItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  String? get listId => _listId;

  /// Initializes repository state.
  ///
  /// This method intentionally loads local data before remote reconciliation so
  /// screens can render immediately when opening the grocery module.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Backend bootstrap guarantees profile, household membership, and at least
      // one grocery list before any data read/write.
      final bootstrap =
          await _supabase.rpc('ensure_user_household_and_default_lists');
      final resolvedListId = bootstrap['grocery_list_id']?.toString();
      if (resolvedListId == null || resolvedListId.isEmpty) {
        throw StateError('No grocery list available for this user.');
      }

      _listId = resolvedListId;
      await _localStore.setMeta('active_grocery_list_id', resolvedListId);
      // Show cached local data immediately, then reconcile with server.
      await refreshFromLocal();
      unawaited(sync(forceRemotePull: true));

      _connectivitySub ??=
          Connectivity().onConnectivityChanged.listen((results) {
        final hasConnection =
            results.any((result) => result != ConnectivityResult.none);
        if (hasConnection) {
          unawaited(sync(forceRemotePull: true));
        }
      });
    } catch (error) {
      _lastError = error.toString();

      final cachedListId = await _localStore.getMeta('active_grocery_list_id');
      if (cachedListId != null && cachedListId.isNotEmpty) {
        _listId = cachedListId;
        await refreshFromLocal();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads in-memory items from local SQLite for the active list.
  Future<void> refreshFromLocal() async {
    final id = _listId;
    if (id == null) {
      _items = const [];
      notifyListeners();
      return;
    }
    _items = await _localStore.getItems(id);
    notifyListeners();
  }

  void _setItems(List<GroceryItem> items) {
    items.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    _items = List<GroceryItem>.unmodifiable(items);
  }

  void _upsertLocalItemInMemory(GroceryItem item) {
    final nextItems =
        _items.where((existing) => existing.id != item.id).toList();
    if (item.deletedAt == null && item.listId == _listId) {
      nextItems.add(item);
    }
    _setItems(nextItems);
  }

  void _removeLocalItemFromMemory(String itemId) {
    if (_items.every((item) => item.id != itemId)) {
      return;
    }
    _setItems(_items.where((item) => item.id != itemId).toList());
  }

  Future<void> _resolveCategoryInBackground(
    GroceryItem item,
    String name, {
    required String locale,
  }) async {
    final resolvedCategory =
        _lookupCategoryFromLocalCatalog(name, locale: locale);
    if (resolvedCategory == null || resolvedCategory == item.category) {
      return;
    }

    final updated = item.copyWith(
      category: resolvedCategory,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_upsert',
    );
    await _localStore.upsertItem(updated);
    _upsertLocalItemInMemory(updated);
    notifyListeners();
    _scheduleSync();
  }

  String? _lookupCategoryFromLocalCatalog(String itemName,
      {required String locale}) {
    final normalized = itemName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final categoryMap = locale == 'de'
        ? groceryCategoryKeyByNameLowerDe
        : groceryCategoryKeyByNameLowerEn;

    var categoryKey = categoryMap[normalized];
    categoryKey ??= _lookupCategoryKeyBySubword(normalized, categoryMap);
    if (categoryKey == null) return null;

    if (locale == 'de') {
      return _deCategoryNameFromKey(categoryKey);
    }
    return _enCategoryNameFromKey(categoryKey);
  }

  String? _lookupCategoryKeyBySubword(
    String normalized,
    Map<String, String> categoryByName,
  ) {
    // Split by separators first, then attempt prefix/suffix matches for
    // German compounds like "joghurtschokolade" -> "schokolade".
    final parts = normalized.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true));
    final tokens = parts.where((part) => part.length >= 4).toList(growable: true);
    if (tokens.isEmpty && normalized.length >= 4) {
      tokens.add(normalized);
    }

    for (final token in tokens) {
      final exact = categoryByName[token];
      if (exact != null) return exact;

      if (token.length < 5) continue;
      for (var i = 1; i <= token.length - 4; i++) {
        final suffix = token.substring(i);
        final suffixCategory = categoryByName[suffix];
        if (suffixCategory != null) return suffixCategory;
      }

      for (var end = token.length - 1; end >= 4; end--) {
        final prefix = token.substring(0, end);
        final prefixCategory = categoryByName[prefix];
        if (prefixCategory != null) return prefixCategory;
      }
    }

    return null;
  }

  String? _enCategoryNameFromKey(String key) {
    switch (key) {
      case 'alcohol':
        return 'Alcohol';
      case 'baby':
        return 'Baby';
      case 'baking_ingredients':
        return 'Baking Ingredients';
      case 'bakery':
        return 'Bakery';
      case 'canned_goods':
        return 'Canned & Jarred Goods';
      case 'electronics':
        return 'Electronics';
      case 'ready_meals':
        return 'Ready Meals';
      case 'fish':
        return 'Fish & Seafood';
      case 'meat':
        return 'Meat';
      case 'health':
        return 'Health';
      case 'beverages':
        return 'Beverages';
      case 'condiments_spices':
        return 'Condiments, Sauces & Oils';
      case 'home_garden':
        return 'Home & Garden';
      case 'pets':
        return 'Pets';
      case 'coffee_tea':
        return 'Coffee & Tea';
      case 'clothing':
        return 'Clothing';
      case 'cosmetics_hygiene':
        return 'Cosmetics & Hygiene';
      case 'dairy_eggs':
        return 'Dairy & Eggs';
      case 'fruits_vegetables':
        return 'Fruits & Vegetables';
      case 'cleaning_laundry':
        return 'Cleaning & Laundry';
      case 'stationery':
        return 'Stationery';
      case 'snacks_sweets':
        return 'Snacks & Sweets';
      case 'frozen_foods':
        return 'Frozen Foods';
      case 'dry_goods':
        return 'Dry Goods';
      default:
        return null;
    }
  }

  String? _deCategoryNameFromKey(String key) {
    switch (key) {
      case 'alcohol':
        return 'Alkohol';
      case 'baby':
        return 'Baby';
      case 'baking_ingredients':
        return 'Backzutaten';
      case 'bakery':
        return 'Bäckerei';
      case 'canned_goods':
        return 'Dosen und Gläser';
      case 'electronics':
        return 'Elektronik';
      case 'ready_meals':
        return 'Fertiggerichte';
      case 'fish':
        return 'Fisch und Meeresfrüchte';
      case 'meat':
        return 'Fleisch';
      case 'health':
        return 'Gesundheit';
      case 'beverages':
        return 'Getränke';
      case 'condiments_spices':
        return 'Gewürze, Saucen, Öle';
      case 'home_garden':
        return 'Haus und Garten';
      case 'pets':
        return 'Haustiere';
      case 'coffee_tea':
        return 'Kaffee und Tee';
      case 'clothing':
        return 'Kleidung';
      case 'cosmetics_hygiene':
        return 'Kosmetik und Hygiene';
      case 'dairy_eggs':
        return 'Milchprodukte und Eier';
      case 'fruits_vegetables':
        return 'Obst und Gemüse';
      case 'cleaning_laundry':
        return 'Reinigung und Wäsche';
      case 'stationery':
        return 'Schreibwaren';
      case 'snacks_sweets':
        return 'Snacks und Süßigkeiten';
      case 'frozen_foods':
        return 'Tiefkühlkost';
      case 'dry_goods':
        return 'Trockene Waren';
      default:
        return null;
    }
  }

  /// Schedules sync work with a small debounce to batch rapid mutations.
  ///
  /// Example: quickly toggling several items should produce one sync burst,
  /// not one network call per tap.
  void _scheduleSync({bool forceRemotePull = false}) {
    if (forceRemotePull) {
      _syncDebounceTimer?.cancel();
      _syncDebounceTimer = null;
      unawaited(sync(forceRemotePull: true));
      return;
    }

    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceWindow, () {
      _syncDebounceTimer = null;
      unawaited(sync());
    });
  }

  bool _shouldPullRemote(bool forceRemotePull) {
    if (forceRemotePull || _lastRemotePullAt == null) {
      return true;
    }
    return DateTime.now().toUtc().difference(_lastRemotePullAt!) >=
        _remotePullCooldown;
  }

  String _fallbackCategoryFromItemName(String itemName,
      {required String locale}) {
    final text = itemName.trim().toLowerCase();
    if (text.isEmpty) return locale == 'de' ? 'Sonstiges' : 'Other';

    const produce = [
      'apple', 'banana', 'orange', 'tomato', 'onion', 'carrot', 'salad',
      'obst', 'gemüse', 'gemu', 'kartoffel', 'fruit', 'vegetable',
    ];
    const meat = [
      'chicken', 'beef', 'pork', 'ham', 'fleisch', 'meat',
      'huhn', 'rind', 'schwein', 'wurst', 'steak',
    ];
    const fish = [
      'fish', 'salmon', 'tuna', 'shrimp', 'fisch', 'lachs',
      'garnelen', 'seafood', 'meeresfrüchte',
    ];
    const dairy = [
      'milk', 'cheese', 'yogurt', 'butter', 'egg',
      'milch', 'käse', 'kase', 'joghurt', 'eier',
    ];
    const bakery = [
      'bread', 'bun', 'toast', 'cake', 'brot', 'bröt', 'broet',
      'kuchen', 'croissant', 'baguette', 'muffin',
    ];
    const bakingIngredients = [
      'flour', 'mehl', 'baking powder', 'backpulver', 'natron',
      'yeast', 'hefe', 'zucker', 'sugar', 'vanilla',
    ];
    const dryGoods = [
      'rice', 'pasta', 'noodle', 'reis', 'nudel', 'lentil', 'linse',
      'bean', 'bohne', 'oat', 'hafer', 'quinoa', 'couscous',
    ];
    const cannedGoods = [
      'canned', 'aus der dose', 'dosentomaten', 'broth', 'brühe',
    ];
    const frozenFoods = [
      'frozen', 'tiefkühl', 'ice cream', 'eis',
    ];
    const beverages = [
      'water', 'juice', 'cola', 'soda', 'bier', 'wein', 'saft',
      'getra', 'getränk', 'lemonade', 'limonade',
    ];
    const coffeeTea = [
      'coffee', 'tea', 'kaffee', 'tee', 'espresso', 'kakao',
    ];
    const snacks = [
      'chips', 'cookie', 'chocolate', 'candy', 'snack',
      'keks', 'schoko', 'süß', 'suss', 'gummi',
    ];
    const condiments = [
      'sauce', 'ketchup', 'mustard', 'oil', 'vinegar', 'spice',
      'senf', 'öl', 'ol', 'essig', 'gewürz', 'pfeffer',
    ];
    const health = [
      'vitamin', 'ibuprofen', 'paracetamol', 'supplement',
      'bandage', 'pflaster', 'protein powder',
    ];
    const cosmetics = [
      'shampoo', 'soap', 'seife', 'toothpaste', 'zahnpasta',
      'deodorant', 'moisturizer', 'razor', 'lotion',
    ];
    const cleaning = [
      'detergent', 'waschmittel', 'reiniger', 'cleaner',
      'bleach', 'bleichmittel', 'spülmittel',
    ];
    const baby = [
      'baby', 'diaper', 'windel', 'formula', 'säugling',
    ];
    const pets = [
      'dog food', 'cat food', 'pet', 'hundefutter', 'katzenfutter',
      'tierfutter', 'haustier',
    ];
    const alcohol = [
      'beer', 'wine', 'vodka', 'whisky', 'bier', 'wein', 'rum',
      'gin', 'alkohol', 'spirits',
    ];

    bool hasAny(List<String> kws) => kws.any(text.contains);

    if (hasAny(produce)) {
      return locale == 'de' ? 'Obst und Gemüse' : 'Fruits & Vegetables';
    }
    if (hasAny(fish)) {
      return locale == 'de' ? 'Fisch und Meeresfrüchte' : 'Fish & Seafood';
    }
    if (hasAny(meat)) return locale == 'de' ? 'Fleisch' : 'Meat';
    if (hasAny(dairy)) {
      return locale == 'de' ? 'Milchprodukte und Eier' : 'Dairy & Eggs';
    }
    if (hasAny(frozenFoods)) {
      return locale == 'de' ? 'Tiefkühlkost' : 'Frozen Foods';
    }
    if (hasAny(coffeeTea)) {
      return locale == 'de' ? 'Kaffee und Tee' : 'Coffee & Tea';
    }
    if (hasAny(beverages)) {
      return locale == 'de' ? 'Getränke' : 'Beverages';
    }
    if (hasAny(bakingIngredients)) {
      return locale == 'de' ? 'Backzutaten' : 'Baking Ingredients';
    }
    if (hasAny(bakery)) return locale == 'de' ? 'Bäckerei' : 'Bakery';
    if (hasAny(dryGoods)) {
      return locale == 'de' ? 'Trockene Waren' : 'Dry Goods';
    }
    if (hasAny(cannedGoods)) {
      return locale == 'de' ? 'Dosen und Gläser' : 'Canned & Jarred Goods';
    }
    if (hasAny(snacks)) {
      return locale == 'de' ? 'Snacks und Süßigkeiten' : 'Snacks & Sweets';
    }
    if (hasAny(condiments)) {
      return locale == 'de' ? 'Gewürze, Saucen, Öle' : 'Condiments, Sauces & Oils';
    }
    if (hasAny(health)) return locale == 'de' ? 'Gesundheit' : 'Health';
    if (hasAny(cosmetics)) {
      return locale == 'de' ? 'Kosmetik und Hygiene' : 'Cosmetics & Hygiene';
    }
    if (hasAny(cleaning)) {
      return locale == 'de' ? 'Reinigung und Wäsche' : 'Cleaning & Laundry';
    }
    if (hasAny(baby)) return locale == 'de' ? 'Baby' : 'Baby';
    if (hasAny(pets)) return locale == 'de' ? 'Haustiere' : 'Pets';
    if (hasAny(alcohol)) return locale == 'de' ? 'Alkohol' : 'Alcohol';
    return locale == 'de' ? 'Sonstiges' : 'Other';
  }

  /// Adds an item using a local-first write path.
  ///
  /// The UI is updated from local state immediately and server sync runs in
  /// the background. Exact product names can be refined from the local catalog.
  Future<void> addItem(String rawName, {String locale = 'en'}) async {
    final id = _listId;
    if (id == null) return;

    final name = rawName.trim();
    if (name.isEmpty) return;

    final category = _fallbackCategoryFromItemName(name, locale: locale);

    // Local-first write: create immediately in SQLite, then sync in background.
    final now = DateTime.now().toUtc();
    final item = GroceryItem(
      id: _uuid.v4(),
      listId: id,
      name: name,
      category: category,
      isBought: false,
      updatedAt: now,
      deletedAt: null,
      syncStatus: 'pending_upsert',
      quantity: 1,
      unit: null,
    );

    await _localStore.upsertItem(item);
    _upsertLocalItemInMemory(item);
    notifyListeners();
    unawaited(_resolveCategoryInBackground(item, name, locale: locale));
    _scheduleSync();
  }

  /// Toggles an item's bought flag locally and queues background sync.
  Future<void> toggleItem(GroceryItem item) async {
    // Local-first toggle for offline support and immediate UI feedback.
    final updated = item.copyWith(
      isBought: !item.isBought,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_upsert',
    );

    await _localStore.upsertItem(updated);
    _upsertLocalItemInMemory(updated);
    notifyListeners();
    _scheduleSync();
  }

  /// Marks one item for delete locally and queues background sync.
  Future<void> deleteItem(GroceryItem item) async {
    // Mark as pending delete locally so item disappears right away. Sync will
    // perform a hard delete on Supabase and then purge local row.
    final updated = item.copyWith(
      updatedAt: DateTime.now().toUtc(),
      deletedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_delete',
    );

    await _localStore.upsertItem(updated);
    _removeLocalItemFromMemory(item.id);
    notifyListeners();
    _scheduleSync();
  }

  /// Marks multiple items for delete in one local batch operation.
  Future<void> deleteItems(List<GroceryItem> items) async {
    final now = DateTime.now().toUtc();
    final updatedItems = items
        .map((item) => item.copyWith(
              updatedAt: now,
              deletedAt: now,
              syncStatus: 'pending_delete',
            ))
        .toList();

    await _localStore.upsertItems(updatedItems);
    final deletedIds = updatedItems.map((item) => item.id).toSet();
    _setItems(_items.where((item) => !deletedIds.contains(item.id)).toList());
    notifyListeners();
    _scheduleSync();
  }

  /// Updates item details locally and resolves category in the background.
  Future<void> updateItemDetails(
    GroceryItem item,
    String newName,
    int newQuantity,
    String? newUnit, {
    String locale = 'en',
  }) async {
    final normalizedName = newName.trim();
    final category =
        _fallbackCategoryFromItemName(normalizedName, locale: locale);

    final updated = item.copyWith(
      name: normalizedName,
      category: category,
      quantity: newQuantity,
      unit: newUnit,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_upsert',
    );

    await _localStore.upsertItem(updated);
    _upsertLocalItemInMemory(updated);
    notifyListeners();
    unawaited(
        _resolveCategoryInBackground(updated, normalizedName, locale: locale));
    _scheduleSync();
  }

  Future<List<Map<String, dynamic>>> fetchGroceryLists() async {
    final response = await _supabase.from('grocery_lists').select('''
          id,
          name,
          grocery_list_items (
            id,
            is_bought,
            deleted_at
          )
        ''').order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Switches active list and forces one remote pull for fresh list state.
  Future<void> setActiveList(String id) async {
    _listId = id;
    await _localStore.setMeta('active_grocery_list_id', id);
    await refreshFromLocal();
    _scheduleSync(forceRemotePull: true);
  }

  /// Moves items to another list locally and schedules a batched sync.
  Future<void> moveItemsToList(
      List<GroceryItem> items, String targetListId) async {
    if (items.isEmpty) return;

    final movedItems = items
        .map(
          (item) => item.copyWith(
            listId: targetListId,
            updatedAt: DateTime.now().toUtc(),
            syncStatus: 'pending_upsert',
            deletedAt: null,
          ),
        )
        .toList();

    await _localStore.upsertItems(movedItems);
    final movedIds = movedItems.map((item) => item.id).toSet();
    _setItems(_items.where((item) => !movedIds.contains(item.id)).toList());
    notifyListeners();
    _scheduleSync();
  }

  Future<void> deleteList(String listId) async {
    await _supabase.from('grocery_lists').delete().eq('id', listId);
    await _localStore.deleteItemsByListId(listId);

    if (_listId == listId) {
      _listId = null;
      await _localStore.setMeta('active_grocery_list_id', '');
      _items = const [];
    }

    notifyListeners();
  }

  /// Synchronizes local pending changes with Supabase.
  ///
  /// Order is important:
  /// 1. upserts, 2. deletes, 3. optional remote pull/merge.
  ///
  /// If called while already syncing, one follow-up pass is queued so new
  /// local mutations are not dropped.
  Future<void> sync({bool forceRemotePull = false}) async {
    final id = _listId;
    if (id == null) return;
    if (_isSyncing) {
      _syncQueued = true;
      _queuedRemotePull = _queuedRemotePull || forceRemotePull;
      return;
    }

    final shouldPullRemote = _shouldPullRemote(forceRemotePull);

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final pendingUpserts = await _localStore.getPendingUpserts(id);
      if (pendingUpserts.isNotEmpty) {
        await _supabase.from('grocery_list_items').upsert(
              pendingUpserts
                  .map(
                    (item) => {
                      'id': item.id,
                      'list_id': item.listId,
                      'name': item.name,
                      'category': item.category,
                      'is_bought': item.isBought,
                      'updated_at': item.updatedAt.toIso8601String(),
                      'deleted_at': null,
                      'updated_by': _supabase.auth.currentUser?.id,
                      'quantity': item.quantity,
                      'unit': item.unit,
                    },
                  )
                  .toList(growable: false),
              onConflict: 'id',
            );
        await _localStore.markUpsertsSynced(
          pendingUpserts.map((item) => item.id).toList(growable: false),
        );
      }

      final pendingDeletes = await _localStore.getPendingDeletes(id);
      if (pendingDeletes.isNotEmpty) {
        final deleteIds =
            pendingDeletes.map((item) => item.id).toList(growable: false);
        await _supabase
            .from('grocery_list_items')
            .delete()
            .inFilter('id', deleteIds);
        await _localStore.deleteItemsByIds(deleteIds);
      }

      if (shouldPullRemote) {
        final remote = await _supabase
            .from('grocery_list_items')
            .select(
                'id, list_id, name, category, is_bought, quantity, unit, updated_at, deleted_at')
            .eq('list_id', id)
            .isFilter('deleted_at', null)
            .order('updated_at', ascending: false);

        final remoteItems = (remote as List<dynamic>)
            .map((row) => GroceryItem.fromMap(
                {...row as Map<String, dynamic>, 'sync_status': 'synced'}))
            .toList(growable: false);

        await _localStore.mergeRemoteItems(id, remoteItems);
        _lastRemotePullAt = DateTime.now().toUtc();
        await refreshFromLocal();
      } else {
        final refreshedItems = await _localStore.getItems(id);
        _setItems(refreshedItems);
        notifyListeners();
      }
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();

      if (_syncQueued) {
        _syncQueued = false;
        final queuedRemotePull = _queuedRemotePull;
        _queuedRemotePull = false;
        unawaited(sync(forceRemotePull: queuedRemotePull));
      }
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _syncDebounceTimer?.cancel();
    super.dispose();
  }
}

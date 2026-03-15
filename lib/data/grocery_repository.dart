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
  final Map<String, String> _categoryCache = <String, String>{};
  final Map<String, Future<String>> _categoryLookups =
      <String, Future<String>>{};

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

  String _normalizedCategoryLookupKey(String itemName, String locale) {
    return '${locale.toLowerCase()}::${itemName.trim().toLowerCase()}';
  }

  Future<String> _lookupCategoryCached(String itemName,
      {required String locale}) {
    final key = _normalizedCategoryLookupKey(itemName, locale);
    final cached = _categoryCache[key];
    if (cached != null) {
      return Future<String>.value(cached);
    }

    final inFlight = _categoryLookups[key];
    if (inFlight != null) {
      return inFlight;
    }

    final lookup = lookupCategory(itemName, locale: locale).then((resolved) {
      _categoryCache[key] = resolved;
      _categoryLookups.remove(key);
      return resolved;
    }, onError: (Object error, StackTrace stackTrace) {
      _categoryLookups.remove(key);
      throw error;
    });

    _categoryLookups[key] = lookup;
    return lookup;
  }

  Future<void> _resolveCategoryInBackground(
    GroceryItem item,
    String name, {
    required String locale,
  }) async {
    // Resolve from local catalog first to avoid unnecessary remote DB calls.
    final localCategory = _lookupCategoryFromLocalCatalog(name, locale: locale);
    if (localCategory != null) {
      if (localCategory != item.category) {
        final updated = item.copyWith(
          category: localCategory,
          updatedAt: DateTime.now().toUtc(),
          syncStatus: 'pending_upsert',
        );
        await _localStore.upsertItem(updated);
        _upsertLocalItemInMemory(updated);
        notifyListeners();
        _scheduleSync();
      }
      return;
    }

    try {
      final resolvedCategory =
          await _lookupCategoryCached(name, locale: locale);
      if (resolvedCategory == item.category) {
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
    } catch (_) {
      // Keep the fallback category when remote lookup is unavailable.
    }
  }

  String? _lookupCategoryFromLocalCatalog(String itemName,
      {required String locale}) {
    final normalized = itemName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final categoryKey = locale == 'de'
        ? groceryCategoryKeyByNameLowerDe[normalized]
        : groceryCategoryKeyByNameLowerEn[normalized];
    if (categoryKey == null) return null;

    if (locale == 'de') {
      return _deCategoryNameFromKey(categoryKey);
    }
    return _enCategoryNameFromKey(categoryKey);
  }

  String? _enCategoryNameFromKey(String key) {
    switch (key) {
      case 'fruits_vegetables':
        return 'Fruits & Vegetables';
      case 'dairy':
        return 'Dairy';
      case 'bakery':
        return 'Bakery';
      case 'drinks':
        return 'Drinks';
      case 'snacks_sweets':
        return 'Snacks & Sweets';
      case 'care_cleaning':
        return 'Care & Cleaning';
      case 'meat_fish':
        return 'Meat & Fish';
      default:
        return null;
    }
  }

  String? _deCategoryNameFromKey(String key) {
    switch (key) {
      case 'fruits_vegetables':
        return 'Obst & Gemüse';
      case 'dairy':
        return 'Milchprodukte';
      case 'bakery':
        return 'Bäckerei';
      case 'drinks':
        return 'Getränke';
      case 'snacks_sweets':
        return 'Snacks & Süßes';
      case 'care_cleaning':
        return 'Pflege & Reinigung';
      case 'meat_fish':
        return 'Fleisch & Fisch';
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

  /// Looks up a category name for [itemName] using [locale] (e.g. 'en', 'de').
  /// Queries global_items where name_translations->>locale matches, then returns
  /// the category name in the same locale. Falls back to 'Other' if no match.
  Future<String> lookupCategory(String itemName, {String locale = 'en'}) async {
    final normalizedItemName = itemName.trim().toLowerCase();
    if (normalizedItemName.isEmpty) {
      return _fallbackCategoryFromItemName(itemName, locale: locale);
    }

    try {
      final exactResults = await _supabase
          .from('global_items')
          .select('categories!inner(name_translations)')
          .ilike('name_translations->>$locale', itemName.trim())
          .limit(1);

      if (exactResults.isNotEmpty) {
        final catTranslations = exactResults[0]['categories']
            ['name_translations'] as Map<String, dynamic>?;
        // Return the localized category name, falling back through en then key.
        return catTranslations?[locale]?.toString() ??
            catTranslations?['en']?.toString() ??
            'Other';
      }

      final fuzzyResults = await _supabase
          .from('global_items')
          .select('categories!inner(name_translations)')
          .ilike('name_translations->>$locale', '%${itemName.trim()}%')
          .limit(1);

      if (fuzzyResults.isNotEmpty) {
        final catTranslations = fuzzyResults[0]['categories']
            ['name_translations'] as Map<String, dynamic>?;
        return catTranslations?[locale]?.toString() ??
            catTranslations?['en']?.toString() ??
            'Other';
      }
    } catch (_) {
      // If offline or table not ready, fall through to default.
    }
    return _fallbackCategoryFromItemName(itemName, locale: locale);
  }

  String _fallbackCategoryFromItemName(String itemName,
      {required String locale}) {
    final text = itemName.trim().toLowerCase();
    if (text.isEmpty) return locale == 'de' ? 'Sonstiges' : 'Other';

    const produce = [
      'apple',
      'banana',
      'orange',
      'tomato',
      'onion',
      'carrot',
      'salad',
      'obst',
      'gemu',
      'kartoffel'
    ];
    const dairy = [
      'milk',
      'cheese',
      'yogurt',
      'butter',
      'egg',
      'milch',
      'kaese',
      'käse',
      'joghurt',
      'butter'
    ];
    const bakery = [
      'bread',
      'bun',
      'toast',
      'flour',
      'cake',
      'brot',
      'bröt',
      'broet',
      'mehl',
      'kuchen'
    ];
    const drinks = [
      'water',
      'juice',
      'cola',
      'soda',
      'coffee',
      'tea',
      'bier',
      'wein',
      'saft',
      'getra',
      'getränk'
    ];
    const snacks = [
      'chips',
      'cookie',
      'chocolate',
      'candy',
      'snack',
      'keks',
      'schoko',
      'suss',
      'süß'
    ];
    const hygiene = [
      'soap',
      'shampoo',
      'detergent',
      'toilet',
      'clean',
      'seife',
      'shampoo',
      'wasch',
      'hygiene',
      'pflege'
    ];
    const meatFish = [
      'meat',
      'chicken',
      'beef',
      'fish',
      'ham',
      'fleisch',
      'huhn',
      'rind',
      'fisch',
      'wurst'
    ];

    bool hasAny(List<String> keywords) => keywords.any(text.contains);

    if (hasAny(produce)) {
      return locale == 'de' ? 'Obst & Gemüse' : 'Fruits & Vegetables';
    }
    if (hasAny(dairy)) return locale == 'de' ? 'Milchprodukte' : 'Dairy';
    if (hasAny(bakery)) return locale == 'de' ? 'Bäckerei' : 'Bakery';
    if (hasAny(drinks)) return locale == 'de' ? 'Getränke' : 'Drinks';
    if (hasAny(snacks)) {
      return locale == 'de' ? 'Snacks & Süßes' : 'Snacks & Sweets';
    }
    if (hasAny(hygiene)) {
      return locale == 'de' ? 'Pflege & Reinigung' : 'Care & Cleaning';
    }
    if (hasAny(meatFish)) {
      return locale == 'de' ? 'Fleisch & Fisch' : 'Meat & Fish';
    }
    return locale == 'de' ? 'Sonstiges' : 'Other';
  }

  /// Adds an item using a local-first write path.
  ///
  /// The UI is updated from local state immediately and server sync runs in
  /// the background. Category quality is refined asynchronously.
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

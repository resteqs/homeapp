import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  String? _lastError;
  String? _listId;

  List<GroceryItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  String? get listId => _listId;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Backend bootstrap guarantees profile, household membership, and at least
      // one grocery list before any data read/write.
      final bootstrap = await _supabase.rpc('ensure_user_household_and_default_lists');
      final resolvedListId = bootstrap['grocery_list_id']?.toString();
      if (resolvedListId == null || resolvedListId.isEmpty) {
        throw StateError('No grocery list available for this user.');
      }

      _listId = resolvedListId;
      await _localStore.setMeta('active_grocery_list_id', resolvedListId);
      // Show cached local data immediately, then reconcile with server.
      await refreshFromLocal();
      await sync();

      _connectivitySub ??=
          Connectivity().onConnectivityChanged.listen((results) {
        final hasConnection =
            results.any((result) => result != ConnectivityResult.none);
        if (hasConnection) {
          unawaited(sync());
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
        final catTranslations =
            exactResults[0]['categories']['name_translations'] as Map<String, dynamic>?;
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
        final catTranslations =
            fuzzyResults[0]['categories']['name_translations'] as Map<String, dynamic>?;
        return catTranslations?[locale]?.toString() ??
            catTranslations?['en']?.toString() ??
            'Other';
      }
    } catch (_) {
      // If offline or table not ready, fall through to default.
    }
    return _fallbackCategoryFromItemName(itemName, locale: locale);
  }

  String _fallbackCategoryFromItemName(String itemName, {required String locale}) {
    final text = itemName.trim().toLowerCase();
    if (text.isEmpty) return locale == 'de' ? 'Sonstiges' : 'Other';

    const produce = ['apple', 'banana', 'orange', 'tomato', 'onion', 'carrot', 'salad', 'obst', 'gemu', 'kartoffel'];
    const dairy = ['milk', 'cheese', 'yogurt', 'butter', 'egg', 'milch', 'kaese', 'käse', 'joghurt', 'butter'];
    const bakery = ['bread', 'bun', 'toast', 'flour', 'cake', 'brot', 'bröt', 'broet', 'mehl', 'kuchen'];
    const drinks = ['water', 'juice', 'cola', 'soda', 'coffee', 'tea', 'bier', 'wein', 'saft', 'getra', 'getränk'];
    const snacks = ['chips', 'cookie', 'chocolate', 'candy', 'snack', 'keks', 'schoko', 'suss', 'süß'];
    const hygiene = ['soap', 'shampoo', 'detergent', 'toilet', 'clean', 'seife', 'shampoo', 'wasch', 'hygiene', 'pflege'];
    const meatFish = ['meat', 'chicken', 'beef', 'fish', 'ham', 'fleisch', 'huhn', 'rind', 'fisch', 'wurst'];

    bool hasAny(List<String> keywords) => keywords.any(text.contains);

    if (hasAny(produce)) return locale == 'de' ? 'Obst & Gemüse' : 'Fruits & Vegetables';
    if (hasAny(dairy)) return locale == 'de' ? 'Milchprodukte' : 'Dairy';
    if (hasAny(bakery)) return locale == 'de' ? 'Bäckerei' : 'Bakery';
    if (hasAny(drinks)) return locale == 'de' ? 'Getränke' : 'Drinks';
    if (hasAny(snacks)) return locale == 'de' ? 'Snacks & Süßes' : 'Snacks & Sweets';
    if (hasAny(hygiene)) return locale == 'de' ? 'Pflege & Reinigung' : 'Care & Cleaning';
    if (hasAny(meatFish)) return locale == 'de' ? 'Fleisch & Fisch' : 'Meat & Fish';
    return locale == 'de' ? 'Sonstiges' : 'Other';
  }

  Future<void> addItem(String rawName, {String locale = 'en'}) async {
    final id = _listId;
    if (id == null) return;

    final name = rawName.trim();
    if (name.isEmpty) return;

    // Resolve category before writing (best-effort; falls back to 'Other').
    final category = await lookupCategory(name, locale: locale);

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
    );

    await _localStore.upsertItem(item);
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<void> toggleItem(GroceryItem item) async {
    // Local-first toggle for offline support and immediate UI feedback.
    final updated = item.copyWith(
      isBought: !item.isBought,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_upsert',
    );

    await _localStore.upsertItem(updated);
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<void> deleteItem(GroceryItem item) async {
    // Mark as pending delete locally so item disappears right away. Sync will
    // perform a hard delete on Supabase and then purge local row.
    final updated = item.copyWith(
      updatedAt: DateTime.now().toUtc(),
      deletedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_delete',
    );

    await _localStore.upsertItem(updated);
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<void> deleteItems(List<GroceryItem> items) async {
    final now = DateTime.now().toUtc();
    final updatedItems = items.map((item) => item.copyWith(
      updatedAt: now,
      deletedAt: now,
      syncStatus: 'pending_delete',
    )).toList();

    await _localStore.upsertItems(updatedItems);
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<void> updateItemDetails(
    GroceryItem item,
    String newName,
    int newQuantity, {
    String locale = 'en',
  }) async {
    final normalizedName = newName.trim();
    final category = await lookupCategory(normalizedName, locale: locale);

    final updated = item.copyWith(
      name: normalizedName,
      category: category,
      quantity: newQuantity,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'pending_upsert',
    );

    await _localStore.upsertItem(updated);
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<List<Map<String, dynamic>>> fetchGroceryLists() async {
    final response = await _supabase
        .from('grocery_lists')
        .select('''
          id,
          name,
          grocery_list_items (
            id,
            is_bought,
            deleted_at
          )
        ''')
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> setActiveList(String id) async {
    _listId = id;
    await _localStore.setMeta('active_grocery_list_id', id);
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<void> moveItemsToList(List<GroceryItem> items, String targetListId) async {
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
    await refreshFromLocal();
    unawaited(sync());
  }

  Future<void> deleteList(String listId) async {
    await _supabase.from('grocery_lists').delete().eq('id', listId);
    await _localStore.deleteItemsByListId(listId);

    if (_listId == listId) {
      _listId = null;
      await _localStore.setMeta('active_grocery_list_id', '');
    }

    await refreshFromLocal();
    notifyListeners();
  }

  Future<void> sync() async {
    final id = _listId;
    if (id == null) return;
    if (_isSyncing) {
      _syncQueued = true;
      return;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final pendingUpserts = await _localStore.getPendingUpserts(id);
      for (final item in pendingUpserts) {
        await _supabase.from('grocery_list_items').upsert(
          {
            'id': item.id,
            'list_id': item.listId,
            'name': item.name,
            'category': item.category,
            'is_bought': item.isBought,
            'updated_at': item.updatedAt.toIso8601String(),
            'deleted_at': null,
            'updated_by': _supabase.auth.currentUser?.id,
            'quantity': item.quantity,
          },
          onConflict: 'id',
        );
        await _localStore.markUpsertSynced(item.id);
      }

      final pendingDeletes = await _localStore.getPendingDeletes(id);
      for (final item in pendingDeletes) {
        // Hard delete in remote DB to satisfy strict deletion semantics.
        await _supabase
            .from('grocery_list_items')
            .delete()
            .eq('id', item.id);
        await _localStore.deleteItemById(item.id);
      }

      final remote = await _supabase
          .from('grocery_list_items')
          .select('id, list_id, name, category, is_bought, quantity, updated_at, deleted_at')
          .eq('list_id', id)
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);

      final remoteItems = (remote as List<dynamic>)
          .map((row) => GroceryItem.fromMap({...row as Map<String, dynamic>, 'sync_status': 'synced'}))
          .toList();

      await _localStore.upsertItems(remoteItems);
      await refreshFromLocal();
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();

      if (_syncQueued) {
        _syncQueued = false;
        unawaited(sync());
      }
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

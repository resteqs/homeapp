import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:homeapp/data/local_grocery_store.dart';
import 'package:homeapp/models/grocery_item.dart';

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
    if (id == null) return;
    _items = await _localStore.getItems(id);
    notifyListeners();
  }

  Future<void> addItem(String rawName) async {
    final id = _listId;
    if (id == null) return;

    final name = rawName.trim();
    if (name.isEmpty) return;

    // Local-first write: create immediately in SQLite, then sync in background.
    final now = DateTime.now().toUtc();
    final item = GroceryItem(
      id: _uuid.v4(),
      listId: id,
      name: name,
      category: 'Other',
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

  Future<void> updateItemDetails(GroceryItem item, String newName, int newQuantity) async {
    final updated = item.copyWith(
      name: newName,
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

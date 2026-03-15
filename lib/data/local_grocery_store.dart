import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/models/household_custom_item.dart';

/// A singleton local database manager using SQLite.
///
/// This acts as the offline-first cache for grocery lists. All creates, updates,
/// and deletes are written to SQLite immediately, then synced in the background.
class LocalGroceryStore {
  static final LocalGroceryStore _instance = LocalGroceryStore._internal();
  LocalGroceryStore._internal();

  factory LocalGroceryStore() => _instance;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'homeapp_local.db'),
      version: 6,
      onCreate: (db, version) async {
        // Local-first cache for grocery items. sync_status tracks pending writes
        // so UI stays responsive while network sync runs in the background.
        await db.execute('''
          CREATE TABLE local_grocery_items(
            id TEXT PRIMARY KEY,
            list_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'Other',
            is_bought INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            sync_status TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            unit TEXT,
            notes TEXT,
            badge_emoji TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE local_meta(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE local_household_custom_items(
            id TEXT PRIMARY KEY,
            household_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'Other',
            sync_status TEXT NOT NULL
          )
        ''');

        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          if (!await _columnExists(db, 'local_grocery_items', 'quantity')) {
            await db.execute(
                'ALTER TABLE local_grocery_items ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1');
          }
        }
        if (oldVersion < 3) {
          if (!await _columnExists(db, 'local_grocery_items', 'unit')) {
            await db.execute(
                'ALTER TABLE local_grocery_items ADD COLUMN unit TEXT');
          }
        }
        if (oldVersion < 4) {
          await _createIndexes(db);
        }
        if (oldVersion < 5) {
          if (!await _columnExists(db, 'local_grocery_items', 'notes')) {
            await db
                .execute('ALTER TABLE local_grocery_items ADD COLUMN notes TEXT');
          }
          if (!await _columnExists(db, 'local_grocery_items', 'badge_emoji')) {
            await db.execute(
                'ALTER TABLE local_grocery_items ADD COLUMN badge_emoji TEXT');
          }
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_household_custom_items(
              id TEXT PRIMARY KEY,
              household_id TEXT NOT NULL,
              name TEXT NOT NULL,
              category TEXT NOT NULL DEFAULT 'Other',
              sync_status TEXT NOT NULL
            )
          ''');
          await _createIndexes(db);
        }
      },
    );
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_grocery_items_list_updated '
      'ON local_grocery_items(list_id, updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_grocery_items_list_sync '
      'ON local_grocery_items(list_id, sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_household_custom_items_household_sync '
      'ON local_household_custom_items(household_id, sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_household_custom_items_household_name '
      'ON local_household_custom_items(household_id, name)',
    );
  }

  Future<bool> _columnExists(
    DatabaseExecutor db,
    String tableName,
    String columnName,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    for (final column in columns) {
      if (column['name'] == columnName) {
        return true;
      }
    }
    return false;
  }

  /// Stores a key-value pair in the local metadata table.
  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'local_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a metadata value by [key], or null if not found.
  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query(
      'local_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value']?.toString();
  }

  /// Returns all non-deleted grocery items for [listId].
  Future<List<GroceryItem>> getItems(String listId) async {
    final db = await database;
    final rows = await db.query(
      'local_grocery_items',
      where: 'list_id = ? AND deleted_at IS NULL',
      whereArgs: [listId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(GroceryItem.fromMap).toList();
  }

  /// Returns all household custom items for [householdId].
  Future<List<HouseholdCustomItem>> getCustomItems(String householdId) async {
    final db = await database;
    final rows = await db.query(
      'local_household_custom_items',
      where: 'household_id = ?',
      whereArgs: [householdId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(HouseholdCustomItem.fromMap).toList();
  }

  /// Returns items with pending upsert status for the given [listId].
  Future<List<GroceryItem>> getPendingUpserts(String listId) async {
    final db = await database;
    final rows = await db.query(
      'local_grocery_items',
      where: 'list_id = ? AND sync_status = ? AND deleted_at IS NULL',
      whereArgs: [listId, 'pending_upsert'],
      orderBy: 'updated_at ASC',
    );
    return rows.map(GroceryItem.fromMap).toList();
  }

  /// Returns items marked for deletion for the given [listId].
  Future<List<GroceryItem>> getPendingDeletes(String listId) async {
    final db = await database;
    final rows = await db.query(
      'local_grocery_items',
      where: 'list_id = ? AND sync_status = ? AND deleted_at IS NOT NULL',
      whereArgs: [listId, 'pending_delete'],
      orderBy: 'updated_at ASC',
    );
    return rows.map(GroceryItem.fromMap).toList();
  }

  Future<List<HouseholdCustomItem>> getPendingCustomItemUpserts(
    String householdId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'local_household_custom_items',
      where: 'household_id = ? AND sync_status = ?',
      whereArgs: [householdId, 'pending_upsert'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(HouseholdCustomItem.fromMap).toList();
  }

  /// Inserts or replaces a single grocery item.
  Future<void> upsertItem(GroceryItem item) async {
    final db = await database;
    await db.insert(
      'local_grocery_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts or replaces multiple grocery items in a single batch.
  Future<void> upsertItems(List<GroceryItem> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'local_grocery_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Inserts or replaces a single household custom item.
  Future<void> upsertCustomItem(HouseholdCustomItem item) async {
    final db = await database;
    await db.insert(
      'local_household_custom_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  /// Marks a batch of grocery items as synced (upserts only).
  Future<void> markUpsertsSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE local_grocery_items '
      'SET sync_status = ? '
      'WHERE sync_status = ? AND deleted_at IS NULL AND id IN ($placeholders)',
      ['synced', 'pending_upsert', ...ids],
    );
  }

  Future<void> markCustomItemUpsertsSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE local_household_custom_items '
      'SET sync_status = ? '
      'WHERE sync_status = ? AND id IN ($placeholders)',
      ['synced', 'pending_upsert', ...ids],
    );
  }

  /// Deletes a single grocery item by [id].
  Future<void> deleteItemById(String id) async {
    final db = await database;
    await db.delete(
      'local_grocery_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes multiple grocery items by their IDs in a single operation.
  Future<void> deleteItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.delete(
      'local_grocery_items',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Deletes all local grocery items belonging to [listId].
  Future<void> deleteItemsByListId(String listId) async {
    final db = await database;
    await db.delete(
      'local_grocery_items',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

  /// Reconciles locally cached items for [listId] with a fresh remote
  /// snapshot. Synced rows not present in [items] are removed; pending
  /// local changes are preserved.
  Future<void> mergeRemoteItems(String listId, List<GroceryItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      if (items.isEmpty) {
        await txn.delete(
          'local_grocery_items',
          where: 'list_id = ? AND sync_status = ?',
          whereArgs: [listId, 'synced'],
        );
        return;
      }

      final remoteIds = items.map((item) => item.id).toList(growable: false);
      final placeholders = List.filled(remoteIds.length, '?').join(', ');
      await txn.delete(
        'local_grocery_items',
        where: 'list_id = ? AND sync_status = ? AND id NOT IN ($placeholders)',
        whereArgs: [listId, 'synced', ...remoteIds],
      );

      final batch = txn.batch();
      for (final item in items) {
        batch.update(
          'local_grocery_items',
          item.toMap(),
          where: 'id = ? AND sync_status = ?',
          whereArgs: [item.id, 'synced'],
        );
        batch.insert(
          'local_grocery_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Same as [mergeRemoteItems] but for household custom items.
  Future<void> mergeRemoteCustomItems(
    String householdId,
    List<HouseholdCustomItem> items,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      if (items.isEmpty) {
        await txn.delete(
          'local_household_custom_items',
          where: 'household_id = ? AND sync_status = ?',
          whereArgs: [householdId, 'synced'],
        );
        return;
      }

      final remoteIds = items.map((item) => item.id).toList(growable: false);
      final placeholders = List.filled(remoteIds.length, '?').join(', ');
      await txn.delete(
        'local_household_custom_items',
        where:
            'household_id = ? AND sync_status = ? AND id NOT IN ($placeholders)',
        whereArgs: [householdId, 'synced', ...remoteIds],
      );

      final batch = txn.batch();
      for (final item in items) {
        batch.update(
          'local_household_custom_items',
          item.toMap(),
          where: 'id = ? AND sync_status = ?',
          whereArgs: [item.id, 'synced'],
        );
        batch.insert(
          'local_household_custom_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:homeapp/models/grocery_item.dart';

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
      version: 5,
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

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'local_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<void> upsertItem(GroceryItem item) async {
    final db = await database;
    await db.insert(
      'local_grocery_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<void> markUpsertSynced(String id) async {
    final db = await database;
    // Guard against race conditions: only mark rows that are still pending
    // upserts. If a row changed to pending_delete meanwhile, do not override it.
    await db.update(
      'local_grocery_items',
      {'sync_status': 'synced'},
      where: 'id = ? AND sync_status = ? AND deleted_at IS NULL',
      whereArgs: [id, 'pending_upsert'],
    );
  }

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

  Future<void> deleteItemById(String id) async {
    final db = await database;
    await db.delete(
      'local_grocery_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<void> updateItemListId(String itemId, String newListId) async {
    final db = await database;
    await db.update(
      'local_grocery_items',
      {
        'list_id': newListId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_status': 'pending_upsert',
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteItemsByListId(String listId) async {
    final db = await database;
    await db.delete(
      'local_grocery_items',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

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
}

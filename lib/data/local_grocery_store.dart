import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:homeapp/models/grocery_item.dart';

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
      version: 2,
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
            quantity INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE local_meta(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE local_grocery_items ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1');
        }
      },
    );
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

  Future<void> deleteItemById(String id) async {
    final db = await database;
    await db.delete(
      'local_grocery_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

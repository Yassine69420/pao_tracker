import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_item.dart';

/// SQLite database provider / helper for `ProductItem`.
///
/// Usage:
///   final dbp = DatabaseHelper.instance;
///   await dbp.init(); // optional - will lazy initialize on first access
///   await dbp.insertProduct(product);
///   final all = await dbp.getAllProducts();
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbFileName = 'pao_tracker.db';
  static const _dbVersion = 1;

  Database? _db;

  /// Initialize DB explicitly (optional - other methods will lazily init).
  Future<void> init() async {
    if (_db != null && _db!.isOpen) return;
    _db = await _initDB();
  }

  /// Returns a ready-to-use database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, _dbFileName);

    // Ensure parent directory exists
    try {
      await Directory(p.dirname(dbPath)).create(recursive: true);
    } catch (_) {}

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  FutureOr<void> _onConfigure(Database db) async {
    // Enable foreign keys if you use them in the future.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // Create tables. Use the SQL statement from ProductItem model.
    await db.execute(ProductItem.createTable);
    // You can create indexes here if needed, for example on name or opened_date:
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_items_name ON ${ProductItem.tableName}(${ProductItem.colName});',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_items_opened_date ON ${ProductItem.tableName}(${ProductItem.colOpenedDate});',
    );
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here. Keep minimal for now.
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE ${ProductItem.tableName} ADD COLUMN new_column TEXT;');
    // }
  }

  // ----------------------------
  // CRUD operations for ProductItem
  // ----------------------------

  Future<void> insertProduct(ProductItem item) async {
    final db = await database;
    await db.insert(
      ProductItem.tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateProduct(ProductItem item) async {
    final db = await database;
    return await db.update(
      ProductItem.tableName,
      item.toMap(),
      where: '${ProductItem.colId} = ?',
      whereArgs: [item.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return await db.delete(
      ProductItem.tableName,
      where: '${ProductItem.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<ProductItem?> getProductById(String id) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      ProductItem.tableName,
      where: '${ProductItem.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductItem.fromMap(maps.first);
  }

  Future<List<ProductItem>> getAllProducts({
    int? limit,
    int? offset,
    String orderBy = '${ProductItem.colName} ASC',
  }) async {
    final db = await database;
    final maps = await db.query(
      ProductItem.tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => ProductItem.fromMap(m)).toList();
  }

  /// Search products by name or brand using a case-insensitive LIKE.
  Future<List<ProductItem>> searchProducts(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final maps = await db.query(
      ProductItem.tableName,
      where:
          '(${ProductItem.colName} LIKE ? OR ${ProductItem.colBrand} LIKE ?)',
      whereArgs: [q, q],
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => ProductItem.fromMap(m)).toList();
  }

  /// Returns products that are already expired (expiryDate < now).
  ///
  /// Note: expiryDate = opened_date + shelf_life_days.
  /// We can filter with opened_date + shelf_life_days * 86400000 < nowMillis
  Future<List<ProductItem>> getExpiredProducts() async {
    final db = await database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Compute expiry in milliseconds: opened_date + shelf_life_days * 86400000
    final maps = await db.rawQuery(
      '''
      SELECT * FROM ${ProductItem.tableName}
      WHERE (${ProductItem.colOpenedDate} + ${ProductItem.colShelfLifeDays} * 86400000) < ?
      ORDER BY (${ProductItem.colOpenedDate} + ${ProductItem.colShelfLifeDays} * 86400000) ASC
    ''',
      [nowMs],
    );
    return maps.map((m) => ProductItem.fromMap(m)).toList();
  }

  /// Returns products that will expire within the next [withinDays] days.
  Future<List<ProductItem>> getExpiringWithin(int withinDays) async {
    final db = await database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final targetMs = DateTime.now()
        .add(Duration(days: withinDays))
        .millisecondsSinceEpoch;
    final maps = await db.rawQuery(
      '''
      SELECT * FROM ${ProductItem.tableName}
      WHERE (${ProductItem.colOpenedDate} + ${ProductItem.colShelfLifeDays} * 86400000) BETWEEN ? AND ?
      ORDER BY (${ProductItem.colOpenedDate} + ${ProductItem.colShelfLifeDays} * 86400000) ASC
    ''',
      [nowMs, targetMs],
    );
    return maps.map((m) => ProductItem.fromMap(m)).toList();
  }

  /// Batch insert with transaction for performance.
  Future<void> insertProductsBatch(List<ProductItem> items) async {
    if (items.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          ProductItem.tableName,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Close DB when done (usually not needed - keep DB open for app lifecycle).
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = null;
  }

  // ----------------------------
  // Utilities
  // ----------------------------

  /// Helper to generate a simple unique string id (ms since epoch + random suffix).
  /// You may replace with a proper UUID generator if desired.
  static String generateId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final rnd = (DateTime.now().microsecondsSinceEpoch % 100000).toString();
    return 'prod_${ms}_$rnd';
  }

  /// Convert a ProductItem into a map suitable for searching by text (if you
  /// later add full text search tables).
  static Map<String, Object?> productToSearchMap(ProductItem item) {
    return {
      ProductItem.colId: item.id,
      ProductItem.colName: item.name,
      ProductItem.colBrand: item.brand,
      ProductItem.colLabel: item.label,
      ProductItem.colNotes: item.notes == null ? null : json.encode(item.notes),
    };
  }
}

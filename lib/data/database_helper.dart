// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart'; // For Colors
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_item.dart';
import '../models/category.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbFileName = 'pao_tracker.db';
  static const _dbVersion = 2; // Incremented version

  Database? _db;

  Future<void> init() async {
    if (_db != null && _db!.isOpen) return;
    _db = await _initDB();
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, _dbFileName);

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
    await db.execute('PRAGMA foreign_keys = ON');
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute(ProductItem.createTable);
    await db.execute(Category.createTable); // Create categories table

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_items_name ON ${ProductItem.tableName}(${ProductItem.colName});',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_items_opened_date ON ${ProductItem.tableName}(${ProductItem.colOpenedDate});',
    );

    await _seedCategories(db); // Seed default categories
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Create categories table
      await db.execute(Category.createTable);

      // 2. Seed categories
      await _seedCategories(db);

      // 3. Add category_id column to product_items
      // SQLite doesn't support adding a column with a foreign key constraint in one go easily,
      // but since we are just adding a column, we can do it.
      // However, to be safe and simple, we just add the column.
      // Note: We are NOT enforcing foreign key constraint strictly here on the column definition level
      // via ALTER TABLE because SQLite support varies. We rely on app logic or rebuild if needed.
      // But for a simple column add:
      await db.execute(
        'ALTER TABLE ${ProductItem.tableName} ADD COLUMN ${ProductItem.colCategoryId} TEXT;',
      );
    }
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      Category(
        id: 'cat_skincare',
        name: 'Skincare',
        iconCodepoint: Icons.face.codePoint,
        colorValue: Colors.pinkAccent.value,
      ),
      Category(
        id: 'cat_makeup',
        name: 'Makeup',
        iconCodepoint: Icons.brush.codePoint,
        colorValue: Colors.purpleAccent.value,
      ),
      Category(
        id: 'cat_haircare',
        name: 'Haircare',
        iconCodepoint: Icons.content_cut.codePoint,
        colorValue: Colors.brown.value,
      ),
      Category(
        id: 'cat_body',
        name: 'Body Care',
        iconCodepoint: Icons.accessibility_new.codePoint,
        colorValue: Colors.orangeAccent.value,
      ),
      Category(
        id: 'cat_bath',
        name: 'Bath & Shower',
        iconCodepoint: Icons.shower.codePoint,
        colorValue: Colors.lightBlueAccent.value,
      ),
      Category(
        id: 'cat_suncare',
        name: 'Sun Care (SPF)',
        iconCodepoint: Icons.wb_sunny.codePoint,
        colorValue: Colors.amber.value,
      ),
      Category(
        id: 'cat_fragrance',
        name: 'Fragrance',
        iconCodepoint: Icons.local_florist.codePoint,
        colorValue: Colors.teal.value,
      ),
      Category(
        id: 'cat_oralcare',
        name: 'Oral Care',
        iconCodepoint: Icons.health_and_safety.codePoint,
        colorValue: Colors.blueAccent.value,
      ),
      Category(
        id: 'cat_nails',
        name: 'Nails',
        iconCodepoint: Icons.color_lens.codePoint,
        colorValue: Colors.redAccent.value,
      ),
      Category(
        id: 'cat_mens',
        name: 'Men\'s Grooming',
        iconCodepoint: Icons.person.codePoint,
        colorValue: Colors.blueGrey.value,
      ),
      Category(
        id: 'cat_baby',
        name: 'Baby Care',
        iconCodepoint: Icons.child_care.codePoint,
        colorValue: Colors.lightGreen.value,
      ),
      Category(
        id: 'cat_medication',
        name: 'Medication',
        iconCodepoint: Icons.medical_services.codePoint,
        colorValue: Colors.red.value,
      ),
      Category(
        id: 'cat_supplements',
        name: 'Supplements',
        iconCodepoint: Icons.medication_liquid.codePoint,
        colorValue: Colors.green.value,
      ),
      Category(
        id: 'cat_cleaning',
        name: 'Cleaning Products',
        iconCodepoint: Icons.cleaning_services.codePoint,
        colorValue: Colors.cyan.value,
      ),
      Category(
        id: 'cat_other',
        name: 'Other',
        iconCodepoint: Icons.category.codePoint,
        colorValue: Colors.grey.value,
      ),
    ];


    final batch = db.batch();
    for (final cat in categories) {
      batch.insert(
        Category.tableName,
        cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(Category.tableName, orderBy: Category.colName);
    return maps.map((m) => Category.fromMap(m)).toList();
  }

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

  Future<List<ProductItem>> getExpiredProducts() async {
    final db = await database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

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

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = null;
  }

  static String generateId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final rnd = (DateTime.now().microsecondsSinceEpoch % 100000).toString();
    return 'prod_${ms}_$rnd';
  }

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

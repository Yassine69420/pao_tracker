// Product repository — CRUD wrapper around DatabaseHelper for ProductItem.
//
// Provides a clean interface for higher-level code (providers, UI, tests)
// to perform product operations without depending on raw SQL or sqflite details.


import 'package:pao_tracker/data/database_helper.dart';

import '../models/product_item.dart';


/// Repository responsible for CRUD operations related to `ProductItem`.
///
/// This class is intentionally thin — it delegates the heavy lifting to
/// `DatabaseHelper`. It focuses on transforming inputs/outputs and exposing
/// a convenient API for callers.
class ProductRepository {
  ProductRepository._(this._dbProvider);

  static final ProductRepository instance = ProductRepository._(
    DatabaseHelper.instance,
  );

  final DatabaseHelper _dbProvider;

  /// Create/insert a product. If `item.id` is already present in the DB it
  /// will be replaced because DatabaseHelper uses ConflictAlgorithm.replace.
  ///
  /// Returns the inserted item (same instance by default).
  Future<ProductItem> create(ProductItem item) async {
    // Ensure id exists — DatabaseHelper has a simple id generator if needed.
    final product = item.id.isEmpty
        ? item.copyWith(id: DatabaseHelper.generateId())
        : item;

    await _dbProvider.insertProduct(product);
    return product;
  }

  /// Convenience to create a ProductItem from fields and insert it.
  Future<ProductItem> createFromFields({
    required String name,
    String? brand,
    required DateTime openedDate,
    required int shelfLifeDays,
    required String label,
    String? photoPath,
    bool favorite = false,
    List<String>? notes,
    String? id,
  }) async {
    final resolvedId = (id == null || id.isEmpty)
        ? DatabaseHelper.generateId()
        : id;

    final item = ProductItem(
      id: resolvedId,
      name: name,
      brand: brand,
      openedDate: openedDate,
      shelfLifeDays: shelfLifeDays,
      label: label,
      photoPath: photoPath,
      favorite: favorite,
      notes: notes,
    );

    await _dbProvider.insertProduct(item);
    return item;
  }

  /// Read — get product by id. Returns `null` if not found.
  Future<ProductItem?> getById(String id) async {
    if (id.isEmpty) return null;
    return await _dbProvider.getProductById(id);
  }

  /// Read — get all products with optional pagination and custom ordering.
  Future<List<ProductItem>> getAll({
    int? limit,
    int? offset,
    String orderBy = '${ProductItem.colName} ASC',
  }) async {
    return await _dbProvider.getAllProducts(
      limit: limit,
      offset: offset,
      orderBy: orderBy,
    );
  }

  /// Update an existing product. Returns the number of rows affected.
  Future<int> update(ProductItem item) async {
    if (item.id.isEmpty) {
      throw ArgumentError('Product id must be provided to update an item.');
    }
    return await _dbProvider.updateProduct(item);
  }

  /// Delete a product by id. Returns the number of rows deleted.
  Future<int> delete(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('id must not be empty for delete operation.');
    }
    return await _dbProvider.deleteProduct(id);
  }

  /// Search products by name or brand. The repository trims the query and
  /// delegates to the DB provider.
  Future<List<ProductItem>> search(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }
    return await _dbProvider.searchProducts(
      trimmed,
      limit: limit,
      offset: offset,
    );
  }

  /// Get products that are already expired.
  Future<List<ProductItem>> getExpired() async {
    return await _dbProvider.getExpiredProducts();
  }

  /// Get products that will expire within the next [withinDays] days.
  Future<List<ProductItem>> getExpiringWithin(int withinDays) async {
    if (withinDays < 0) {
      throw ArgumentError.value(withinDays, 'withinDays', 'must be >= 0');
    }
    return await _dbProvider.getExpiringWithin(withinDays);
  }

  /// Insert multiple products in a batch (transactional). Useful for imports.
  Future<void> insertBatch(List<ProductItem> items) async {
    if (items.isEmpty) return;
    return await _dbProvider.insertProductsBatch(items);
  }

  /// Close the underlying database (mostly useful for tests).
  Future<void> close() async {
    await _dbProvider.close();
  }
}

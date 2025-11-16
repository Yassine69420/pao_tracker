import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_repository.dart';
import '../models/product_item.dart';

/// Provides the shared [ProductRepository] instance.
///
/// Use this to inject/mock the repository in tests.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository.instance;
});

/// Async state that holds the list of products.
///
/// Consumers can watch this provider to get the current list and loading/error
/// states. Use the notifier to perform CRUD operations.
final productListProvider =
    StateNotifierProvider<ProductListNotifier, AsyncValue<List<ProductItem>>>(
      (ref) => ProductListNotifier(ref),
    );

/// A [StateNotifier] that manages loading and mutating the list of products.
///
/// It exposes convenience methods for common repository operations and keeps
/// the UI state (loading/data/error) in an `AsyncValue<List<ProductItem>>`.
class ProductListNotifier extends StateNotifier<AsyncValue<List<ProductItem>>> {
  ProductListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadAll();
  }

  final Ref _ref;

  ProductRepository get _repo => _ref.read(productRepositoryProvider);

  /// Load all products from the repository and update state.
  Future<void> _loadAll() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Public refresh - reloads the list from DB.
  Future<void> refresh() async => _loadAll();

  /// Create a new product. The notifier updates state optimistically after the
  /// repository operation completes.
  Future<ProductItem?> create(ProductItem item) async {
    try {
      final created = await _repo.create(item);
      // Insert into the current list (if present).
      state = state.when(
        data: (list) => AsyncValue.data([created, ...list]),
        loading: () => AsyncValue.data([created]),
        error: (_, __) => AsyncValue.data([created]),
      );
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update an existing product. Updates the item in the state list on success.
  Future<int> update(ProductItem item) async {
    try {
      final rows = await _repo.update(item);
      if (rows > 0) {
        state = state.when(
          data: (list) {
            final idx = list.indexWhere((p) => p.id == item.id);
            if (idx == -1) {
              // If not found, add to front
              return AsyncValue.data([item, ...list]);
            }
            final newList = List<ProductItem>.from(list);
            newList[idx] = item;
            return AsyncValue.data(newList);
          },
          loading: () => state,
          error: (_, __) => state,
        );
      }
      return rows;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete a product by id. Removes it from the state list on success.
  Future<int> delete(String id) async {
    try {
      final rows = await _repo.delete(id);
      if (rows > 0) {
        state = state.when(
          data: (list) {
            final newList = list.where((p) => p.id != id).toList();
            return AsyncValue.data(newList);
          },
          loading: () => state,
          error: (_, __) => state,
        );
      }
      return rows;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Search products by name/brand; replaces current state with search results.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await refresh();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _repo.search(trimmed);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Get items that are already expired. Does not alter the main list state;
  /// returns the found items.
  Future<List<ProductItem>> getExpired() async {
    return _repo.getExpired();
  }

  /// Get items expiring within [withinDays]. Does not alter the main list state;
  /// returns the found items.
  Future<List<ProductItem>> getExpiringWithin(int withinDays) async {
    return _repo.getExpiringWithin(withinDays);
  }
}

/// A provider for a single product by id (useful for detail screens).
final productProvider = FutureProvider.family<ProductItem?, String>((
  ref,
  id,
) async {
  if (id.isEmpty) return null;
  final repo = ref.read(productRepositoryProvider);
  return repo.getById(id);
});

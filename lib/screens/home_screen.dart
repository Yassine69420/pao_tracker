import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../models/product_item.dart';
import '../utils/colors.dart';
import 'package:pao_tracker/screens/widgets/product_card.dart'; // Imported the separated widget
import 'add_edit_screen.dart';
import 'detail_screen.dart';

// Enum for the filter chips
enum ProductFilter { all, favorites, expiring, expired, safe }

// Enum for sorting
enum ProductSort {
  defaults, // By added (default from DB)
  byNameAsc, // A-Z
  byNameDesc, // Z-A
  byExpiryAsc, // Soonest
  byExpiryDesc, // Latest
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  ProductFilter _selectedFilter = ProductFilter.all;
  ProductSort _selectedSort = ProductSort.defaults;

  @override
  void initState() {
    super.initState();
    // Initial load
    Future.microtask(() => ref.read(productListProvider.notifier).refresh());
  }

  /// Helper to get the display name for a filter
  String _getFilterName(ProductFilter filter) {
    switch (filter) {
      case ProductFilter.all:
        return 'All';
      case ProductFilter.favorites:
        return 'Favorites';
      case ProductFilter.expiring:
        return 'Expiring';
      case ProductFilter.expired:
        return 'Expired';
      case ProductFilter.safe:
        return 'Safe';
    }
  }

  // Helper to get the display name for a sort option
  String _getSortName(ProductSort sort) {
    switch (sort) {
      case ProductSort.defaults:
        return 'Default (Newest)';
      case ProductSort.byNameAsc:
        return 'Name (A-Z)';
      case ProductSort.byNameDesc:
        return 'Name (Z-A)';
      case ProductSort.byExpiryAsc:
        return 'Expiry (Soonest)';
      case ProductSort.byExpiryDesc:
        return 'Expiry (Latest)';
    }
  }

  /// Client-side filtering based on the selected chip
  List<ProductItem> _getFilteredProducts(
    List<ProductItem> products,
    ProductFilter filter,
  ) {
    switch (filter) {
      case ProductFilter.favorites:
        return products.where((p) => p.favorite).toList();
      case ProductFilter.expiring:
        return products
            .where((p) => p.remainingDays <= 7 && p.remainingDays >= 0)
            .toList();
      case ProductFilter.expired:
        return products.where((p) => p.remainingDays < 0).toList();
      case ProductFilter.safe:
        return products.where((p) => p.remainingDays > 7).toList();
      case ProductFilter.all:
        return products;
    }
  }

  // Client-side sorting
  List<ProductItem> _applySorting(
    List<ProductItem> products,
    ProductSort sort,
  ) {
    // If default, just return the list from the filter (which is already a copy)
    if (sort == ProductSort.defaults) {
      return products;
    }

    // Create a new list to avoid modifying the original
    final sortedList = List<ProductItem>.from(products);

    switch (sort) {
      case ProductSort.byNameAsc:
        sortedList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProductSort.byNameDesc:
        sortedList.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case ProductSort.byExpiryAsc:
        sortedList.sort((a, b) => a.remainingDays.compareTo(b.remainingDays));
        break;
      case ProductSort.byExpiryDesc:
        sortedList.sort((a, b) => b.remainingDays.compareTo(a.remainingDays));
        break;
      case ProductSort.defaults:
        break;
    }
    return sortedList;
  }

  /// Gets the styling colors for a filter chip
  (Color, Color, Color) _getChipStyle(
    ProductFilter filter,
    bool isSelected,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    // Default unselected style
    Color chipBackgroundColor = theme.colorScheme.surface;
    Color labelColor = theme.colorScheme.onSurfaceVariant;
    Color borderColor = theme.colorScheme.outlineVariant;

    switch (filter) {
      case ProductFilter.all:
        labelColor = theme.colorScheme.primary;
        borderColor =
            isSelected ? Colors.transparent : theme.colorScheme.primary;
        chipBackgroundColor = isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.primary;
        break;
      case ProductFilter.favorites:
        labelColor = theme.colorScheme.tertiary;
        borderColor =
            isSelected ? Colors.transparent : theme.colorScheme.tertiary;
        chipBackgroundColor = isSelected
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? theme.colorScheme.onTertiaryContainer
            : theme.colorScheme.tertiary;
        break;
      case ProductFilter.expiring:
        labelColor = AppColors.warning;
        borderColor = isSelected ? Colors.transparent : AppColors.warning;
        chipBackgroundColor = isSelected
            ? AppColors.warningContainer
            : theme.colorScheme.surface;
        labelColor = isSelected ? const Color(0xFFC77C0E) : AppColors.warning;
        break;
      case ProductFilter.expired:
        labelColor = theme.colorScheme.error;
        borderColor =
            isSelected ? Colors.transparent : theme.colorScheme.error;
        chipBackgroundColor = isSelected
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.error;
        break;
      case ProductFilter.safe:
        labelColor = AppColors.success;
        borderColor = isSelected ? Colors.transparent : AppColors.success;
        chipBackgroundColor = isSelected
            ? AppColors.successContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? theme.colorScheme.onPrimaryContainer
            : AppColors.success;
        break;
    }
    return (chipBackgroundColor, labelColor, borderColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // SORT BUTTON
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortOptions(context),
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(productListProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Search products...',
              leading: const Icon(Icons.search),
              backgroundColor: MaterialStateProperty.all(
                colorScheme.surfaceVariant.withOpacity(0.5),
              ),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isEmpty) {
                  ref.read(productListProvider.notifier).refresh();
                } else {
                  ref.read(productListProvider.notifier).search(value);
                }
              },
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ProductFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final style = _getChipStyle(filter, isSelected, context);
                  final chipBackgroundColor = style.$1;
                  final labelColor = style.$2;
                  final borderColor = style.$3;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(_getFilterName(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                      showCheckmark: false,
                      backgroundColor: chipBackgroundColor,
                      selectedColor: chipBackgroundColor,
                      labelStyle: TextStyle(
                        color: labelColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Product list
          Expanded(
            child: productListAsync.when(
              data: (products) {
                // 1. Apply filtering
                final filteredProducts = _getFilteredProducts(
                  products,
                  _selectedFilter,
                );

                // 2. Apply sorting
                final displayedProducts = _applySorting(
                  filteredProducts,
                  _selectedSort,
                );

                if (displayedProducts.isEmpty) {
                  // Pass the original *unsorted* list length to check if DB is empty
                  return _buildEmptyState(products.isEmpty);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productListProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayedProducts[index];
                      // Use Dismissible for swipe-to-delete
                      return Dismissible(
                        key: Key(product.id),
                        direction: DismissDirection.endToStart,
                        // Show confirmation dialog before dismissing
                        confirmDismiss: (direction) =>
                            _showDeleteConfirmation(),
                        // Perform delete after confirmation
                        onDismissed: (direction) {
                          _performDelete(product.id);
                        },
                        background: _buildDismissibleBackground(context),
                        child: ProductCard(
                          product: product,
                          onTap: () =>
                              _navigateToDetail(context, product.id),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddEdit(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
        ),
      ),
    );
  }

  /// Build the background for the Dismissible (swipe-to-delete)
  Widget _buildDismissibleBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        Icons.delete_sweep_rounded,
        color: colorScheme.onErrorContainer,
      ),
    );
  }

  /// Build the empty state widget
  Widget _buildEmptyState(bool isDatabaseEmpty) {
    String title;
    String subtitle;
    if (_searchQuery.isNotEmpty) {
      title = 'No products found';
      subtitle = "Try a different search term for '$_searchQuery'";
    } else if (_selectedFilter != ProductFilter.all) {
      title = 'No products match filter';
      subtitle = 'Try selecting "All" to see all your products';
    } else if (isDatabaseEmpty) {
      title = 'No products yet';
      subtitle = 'Tap + to add your first product';
    } else {
      title = 'No products found';
      subtitle = 'Try selecting a different filter or sort';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// Build the error state widget
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(productListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddEdit(BuildContext context, [ProductItem? product]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddEditScreen(product: product)),
    );
    // Refresh after returning
    ref.read(productListProvider.notifier).refresh();
  }

  void _navigateToDetail(BuildContext context, String productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DetailScreen(productId: productId)),
    );
    // Refresh after returning
    ref.read(productListProvider.notifier).refresh();
  }

  // Shows the sorting modal bottom sheet
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              // Map all enum values to RadioListTiles
              ...ProductSort.values.map((sort) {
                return RadioListTile<ProductSort>(
                  title: Text(_getSortName(sort)),
                  value: sort,
                  groupValue: _selectedSort, // Uses the state variable
                  onChanged: (ProductSort? value) {
                    if (value != null) {
                      setState(() {
                        _selectedSort = value;
                      });
                      Navigator.pop(context);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, size: 32),
        title: const Text('Delete Product'),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete(String id) async {
    await ref.read(productListProvider.notifier).delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product deleted'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 500),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
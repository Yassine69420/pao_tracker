// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../models/product_item.dart';
import '../models/category.dart';
import '../data/database_helper.dart';
import '../utils/colors.dart';
import 'package:pao_tracker/screens/widgets/product_card.dart';
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

  // Category State
  Map<String, Category> _categoryMap = {};
  Category? _selectedCategory;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    // Initial load
    Future.microtask(() {
      ref.read(productListProvider.notifier).refresh();
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    if (mounted) {
      setState(() {
        _categoryMap = {for (var c in categories) c.id: c};
        _isLoadingCategories = false;
      });
    }
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

  /// Client-side filtering
  List<ProductItem> _getFilteredProducts(
    List<ProductItem> products,
    ProductFilter filter,
    Category? category,
  ) {
    var filtered = products;

    // 1. Apply Status Filter
    switch (filter) {
      case ProductFilter.favorites:
        filtered = filtered.where((p) => p.favorite).toList();
        break;
      case ProductFilter.expiring:
        filtered = filtered
            .where((p) => p.remainingDays <= 7 && p.remainingDays >= 0)
            .toList();
        break;
      case ProductFilter.expired:
        filtered = filtered.where((p) => p.remainingDays < 0).toList();
        break;
      case ProductFilter.safe:
        filtered = filtered.where((p) => p.remainingDays > 7).toList();
        break;
      case ProductFilter.all:
        // No status filter
        break;
    }

    // 2. Apply Category Filter
    if (category != null) {
      filtered = filtered.where((p) => p.categoryId == category.id).toList();
    }

    return filtered;
  }

  // Client-side sorting
  List<ProductItem> _applySorting(
    List<ProductItem> products,
    ProductSort sort,
  ) {
    if (sort == ProductSort.defaults) {
      return products;
    }

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
        borderColor = isSelected
            ? Colors.transparent
            : theme.colorScheme.primary;
        chipBackgroundColor = isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.primary;
        break;
      case ProductFilter.favorites:
        labelColor = theme.colorScheme.tertiary;
        borderColor = isSelected
            ? Colors.transparent
            : theme.colorScheme.tertiary;
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
        borderColor = isSelected ? Colors.transparent : theme.colorScheme.error;
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
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // CATEGORY FILTER BUTTON
          IconButton(
            icon: Icon(
              _selectedCategory == null
                  ? Icons.filter_list
                  : Icons.filter_list_off,
              color: _selectedCategory == null ? null : colorScheme.primary,
            ),
            onPressed: () => _showCategoryFilter(context),
            tooltip: 'Filter by Category',
          ),
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
              _loadCategories();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(productListProvider.notifier).refresh();
          await _loadCategories();
        },
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
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
                      borderRadius: BorderRadius.circular(28),
                    ),
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
            ),

            // Active Category Filter Indicator
            if (_selectedCategory != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Category:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: InputChip(
                          label: Text(
                            _selectedCategory!.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          avatar: Icon(
                            _selectedCategory!.icon,
                            size: 16,
                            color: _selectedCategory!.color,
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
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
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
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
            ),

            // Product list
            productListAsync.when(
              data: (products) {
                // 1. Apply filtering
                final filteredProducts = _getFilteredProducts(
                  products,
                  _selectedFilter,
                  _selectedCategory,
                );

                // 2. Apply sorting
                final displayedProducts = _applySorting(
                  filteredProducts,
                  _selectedSort,
                );

                if (displayedProducts.isEmpty) {
                  // Pass the original *unsorted* list length to check if DB is empty
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(products.isEmpty),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                          category: product.categoryId != null
                              ? _categoryMap[product.categoryId]
                              : null,
                          onTap: () => _navigateToDetail(context, product.id),
                        ),
                      );
                    }, childCount: displayedProducts.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(error),
              ),
            ),
          ],
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
    } else if (_selectedFilter != ProductFilter.all ||
        _selectedCategory != null) {
      title = 'No products match filter';
      subtitle = 'Try clearing filters to see all your products';
    } else if (isDatabaseEmpty) {
      title = 'No products yet';
      subtitle = 'Tap + to add your first product';
    } else {
      title = 'No products found';
      subtitle = 'Try selecting a different filter or sort';
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the error state widget
  Widget _buildErrorState(Object error) {
    return Center(
      child: SingleChildScrollView(
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
              textAlign: TextAlign.center,
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
      MaterialPageRoute(builder: (context) => AddEditScreen(product: product)),
    );
    // Refresh after returning
    ref.read(productListProvider.notifier).refresh();
  }

  void _navigateToDetail(BuildContext context, String productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(productId: productId),
      ),
    );
    // Refresh after returning
    ref.read(productListProvider.notifier).refresh();
  }

  // Shows the category filter modal bottom sheet
  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_selectedCategory != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedCategory = null);
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingCategories)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryMap.values.map((category) {
                      final isSelected = _selectedCategory?.id == category.id;
                      return FilterChip(
                        label: Text(category.name),
                        avatar: Icon(
                          category.icon,
                          size: 16,
                          color: category.color,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                          Navigator.pop(context);
                        },
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Shows the sorting modal bottom sheet
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

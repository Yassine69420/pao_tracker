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
  bool _isFilterExpanded = false; // Default to closed for cleaner initial UI

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
        return 'All Items';
      case ProductFilter.favorites:
        return 'Favorites';
      case ProductFilter.expiring:
        return 'Expiring Soon';
      case ProductFilter.expired:
        return 'Expired';
      case ProductFilter.safe:
        return 'Good Condition';
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
  /// Returns: (BackgroundColor, LabelColor, BorderColor)
  (Color, Color, Color) _getChipStyle(
    ProductFilter filter,
    bool isSelected,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    // Base colors for unselected state
    Color bgColor = Colors.transparent;
    Color labelColor = theme.colorScheme.onSurfaceVariant;
    Color borderColor = theme.colorScheme.outlineVariant;

    if (!isSelected) {
      return (bgColor, labelColor, borderColor);
    }

    // Selected colors mapped to AppColors
    switch (filter) {
      case ProductFilter.all:
        bgColor = AppColors.primaryContainer;
        labelColor = AppColors.onPrimaryContainer;
        borderColor = AppColors.primary;
        break;
      case ProductFilter.favorites:
        bgColor = AppColors.tertiaryContainer;
        labelColor = AppColors.onTertiaryContainer;
        borderColor = AppColors.tertiary;
        break;
      case ProductFilter.expiring:
        bgColor = AppColors.warningContainer;
        labelColor = const Color(
          0xFFC77C0E,
        ); // Darker orange for text legibility
        borderColor = AppColors.warning;
        break;
      case ProductFilter.expired:
        bgColor = AppColors.expiredContainer;
        labelColor = AppColors.onErrorContainer;
        borderColor = AppColors.expired;
        break;
      case ProductFilter.safe:
        bgColor = AppColors.successContainer;
        labelColor = AppColors.onPrimaryContainer;
        borderColor = AppColors.success;
        break;
    }
    return (bgColor, labelColor, borderColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final productListAsync = ref.watch(productListProvider);

    // Standard input border styling
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
    );

    final inputFocusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(productListProvider.notifier).refresh();
          await _loadCategories();
        },
        child: CustomScrollView(
          slivers: [
            // 1. THE HEADER
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'My Products',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort_rounded),
                  color: AppColors
                      .primary, // FIX: Added primary color to sort icon
                  onPressed: () => _showSortOptions(context),
                ),
              ],
              bottom: PreferredSize(
                // FIX: Increased expanded height from 220 to 240 to prevent overflow (12px error)
                preferredSize: Size.fromHeight(_isFilterExpanded ? 240 : 70),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- TOP ROW: Search & Toggle ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value);
                                    if (value.isEmpty) {
                                      ref
                                          .read(productListProvider.notifier)
                                          .refresh();
                                    } else {
                                      ref
                                          .read(productListProvider.notifier)
                                          .search(value);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search items...',
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: AppColors.primary,
                                    ), // FIX: Added primary color to search icon
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: inputFocusedBorder,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // The "Filter" Toggle Button
                            GestureDetector(
                              onTap: () => setState(
                                () => _isFilterExpanded = !_isFilterExpanded,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: _isFilterExpanded
                                      ? AppColors.primary
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    // FIX: Border is grey (outlineVariant) when unchecked, transparent when checked
                                    color: _isFilterExpanded
                                        ? Colors.transparent
                                        : colorScheme.outlineVariant,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  _isFilterExpanded
                                      ? Icons.filter_list_off
                                      : Icons.tune_rounded,
                                  // Icon is primary color when inactive, white when active
                                  color: _isFilterExpanded
                                      ? colorScheme.onPrimary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- EXPANDABLE PANEL ---
                      if (_isFilterExpanded) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // A. Categories as "Stories"
                            SizedBox(
                              height: 115,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _categoryMap.length + 1,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final isSelected =
                                        _selectedCategory == null;
                                    return _buildCategoryAvatar(
                                      label: "All",
                                      icon: Icons.grid_view,
                                      color: Colors.grey.shade800,
                                      isSelected: isSelected,
                                      onTap: () => setState(
                                        () => _selectedCategory = null,
                                      ),
                                      colorScheme: colorScheme,
                                    );
                                  }
                                  final category = _categoryMap.values
                                      .elementAt(index - 1);
                                  final isSelected =
                                      _selectedCategory?.id == category.id;
                                  return _buildCategoryAvatar(
                                    label: category.name,
                                    icon: category.icon,
                                    color: category.color,
                                    isSelected: isSelected,
                                    onTap: () => setState(
                                      () => _selectedCategory = isSelected
                                          ? null
                                          : category,
                                    ),
                                    colorScheme: colorScheme,
                                  );
                                },
                              ),
                            ),

                            // B. Status Tags
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: ProductFilter.values.map((filter) {
                                    final isSelected =
                                        _selectedFilter == filter;

                                    // Retrieve the custom style logic
                                    final (
                                      bgColor,
                                      labelColor,
                                      borderColor,
                                    ) = _getChipStyle(
                                      filter,
                                      isSelected,
                                      context,
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () => setState(
                                          () => _selectedFilter = (isSelected
                                              ? null
                                              : filter)!,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ), // Softer pill shape
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            // FIX: Border is always visible and colored now
                                            border: Border.all(
                                              color: borderColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            _getFilterName(filter),
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: labelColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 2. CONTENT LIST
            productListAsync.when(
              data: (products) {
                final filteredProducts = _getFilteredProducts(
                  products,
                  _selectedFilter,
                  _selectedCategory,
                );
                final displayedProducts = _applySorting(
                  filteredProducts,
                  _selectedSort,
                );

                if (displayedProducts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(products.isEmpty),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = displayedProducts[index];
                      return Dismissible(
                        key: Key(product.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _showDeleteConfirmation(),
                        onDismissed: (_) => _performDelete(product.id),
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
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) =>
                  SliverFillRemaining(child: _buildErrorState(error)),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddEdit(context),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          // Removed Brutal Border, used standard rounded shape
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add),
          label: const Text(
            'NEW ITEM',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Helper for the "Story Style" Categories
  Widget _buildCategoryAvatar({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Use lighter container when selected for softer look, grey when unchecked
              color: isSelected
                  ? color.withOpacity(0.15)
                  : colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              // FIX: Always use the specific category color, even when unchecked
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the background for the Dismissible (swipe-to-delete)
  Widget _buildDismissibleBackground(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            "Delete",
            style: TextStyle(
              color: AppColors.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.delete_sweep_rounded,
            color: AppColors.onErrorContainer,
          ),
        ],
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
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.error),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

  // Shows the sorting modal bottom sheet
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      showDragHandle: true, // Modern drag handle
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                  activeColor: AppColors.primary,
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
          duration: Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

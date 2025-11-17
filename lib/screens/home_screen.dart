import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../models/product_item.dart';
import '../utils/colors.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

// Enum for the filter chips
enum ProductFilter { all, favorites, expiring, expired, safe }

// --- NEW: Enum for sorting ---
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
  ProductSort _selectedSort = ProductSort.defaults; // <-- NEW: Sort state

  @override
  void initState() {
    super.initState();
    // Initial load
    Future.microtask(() => ref.read(productListProvider.notifier).refresh());
  }

  /// Helper to get the display name for a filter
  String _getFilterName(ProductFilter filter) {
    // ... existing code ...
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

  // --- NEW: Helper to get the display name for a sort option ---
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
    // ... existing code ...
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

  // --- NEW: Client-side sorting ---
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
        // This case is handled by the check above, but switch needs it
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
    // ... (existing code, no changes)
    final theme = Theme.of(context);
    // Default unselected style
    Color chipBackgroundColor = theme.colorScheme.surface;
    // UPDATED: Use theme color
    Color labelColor = theme.colorScheme.onSurfaceVariant;
    Color borderColor = theme.colorScheme.outlineVariant;
    switch (filter) {
      case ProductFilter.all:
        // UPDATED: Use theme colors
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
        // UPDATED: Use theme colors
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
        // Using Warning colors (from AppColors, as it's not in standard theme)
        labelColor = AppColors.warning;
        borderColor = isSelected ? Colors.transparent : AppColors.warning;
        chipBackgroundColor = isSelected
            ? AppColors.warningContainer
            : theme.colorScheme.surface;
        // Define a fitting "onWarningContainer" color
        labelColor = isSelected ? const Color(0xFFC77C0E) : AppColors.warning;
        break;
      case ProductFilter.expired:
        // UPDATED: Use theme colors
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
        // Using Success colors (from AppColors, as it's not in standard theme)
        labelColor = AppColors.success;
        borderColor = isSelected ? Colors.transparent : AppColors.success;
        chipBackgroundColor = isSelected
            ? AppColors.successContainer
            : theme.colorScheme.surface;
        // Re-using onPrimaryContainer as it's a fitting dark green
        labelColor = isSelected
            ? theme
                  .colorScheme
                  .onPrimaryContainer // UPDATED
            : AppColors.success;
        break;
    }
    return (chipBackgroundColor, labelColor, borderColor);
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED: Get theme and colorScheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface, // UPDATED
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: colorScheme.surface, // UPDATED
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents tint on scroll
        actions: [
          // --- NEW: SORT BUTTON ---
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortOptions(context),
            tooltip: 'Sort',
          ),
          // --- END NEW ---
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
            // ... (existing code, no changes)
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Search products...',
              leading: const Icon(Icons.search),
              backgroundColor: MaterialStateProperty.all(
                colorScheme.surfaceVariant.withOpacity(0.5), // UPDATED
              ),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onChanged: (value) {
                // ... existing code ...
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
            // ... (existing code, no changes)
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // ... existing code ...
              child: Row(
                children: ProductFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  // Get dynamic colors based on filter status
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
          // Product list
          Expanded(
            child: productListAsync.when(
              data: (products) {
                // --- MODIFIED: Apply filtering THEN sorting ---
                // 1. Apply filtering to the list
                final filteredProducts = _getFilteredProducts(
                  products,
                  _selectedFilter,
                );

                // 2. Apply sorting to the filtered list
                final displayedProducts = _applySorting(
                  filteredProducts,
                  _selectedSort,
                );
                // --- END MODIFICATION ---

                if (displayedProducts.isEmpty) {
                  // Pass the original *unsorted* list length to check if DB is empty
                  return _buildEmptyState(products.isEmpty);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productListProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    // ... existing code ...
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: displayedProducts.length, // <-- Use sorted list
                    itemBuilder: (context, index) {
                      final product =
                          displayedProducts[index]; // <-- Use sorted list
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
                        // UPDATED: Pass context
                        background: _buildDismissibleBackground(context),
                        child: ProductCard(
                          product: product,
                          onTap: () => _navigateToDetail(context, product.id),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        // ... (existing code, no changes)
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
  // UPDATED: Added context
  Widget _buildDismissibleBackground(BuildContext context) {
    // ... (existing code, no changes)
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer, // UPDATED
        borderRadius: BorderRadius.circular(12), // Match card
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        Icons.delete_sweep_rounded,
        color: colorScheme.onErrorContainer, // UPDATED
      ),
    );
  }

  /// Build the empty state widget
  Widget _buildEmptyState(bool isDatabaseEmpty) {
    // ... (existing code, no changes)
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
      // ... existing code ...
      title = 'No products found';
      subtitle = 'Try selecting a different filter or sort'; // <-- Updated text
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            // UPDATED: Use theme
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant, // UPDATED
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              // UPDATED: Use theme
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
    // ... (existing code, no changes)
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
            ), // UPDATED
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ), // UPDATED
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
    // ... (existing code, no changes)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditScreen(product: product)),
    );
    // Refresh after returning
    ref.read(productListProvider.notifier).refresh();
  }

  void _navigateToDetail(BuildContext context, String productId) async {
    // ... (existing code, no changes)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(productId: productId),
      ),
    );
    // Refresh after returning
    ref.read(productListProvider.notifier).refresh();
  }

  // --- NEW: Shows the sorting modal bottom sheet ---
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640), // Good for tablet/web
      builder: (context) {
        return Padding(
          // Add padding for aesthetics
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
                      // 1. Update the main screen's state
                      setState(() {
                        _selectedSort = value;
                      });
                      // 2. Close the sheet
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
  // --- END NEW ---

  /// Shows the delete confirmation dialog.
  /// Returns `true` if delete is confirmed, `false` otherwise.
  Future<bool?> _showDeleteConfirmation() async {
    // ... (existing code, no changes)
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
            // UPDATED: Use theme
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Performs the actual deletion logic.
  void _performDelete(String id) async {
    // ... (existing code, no changes)
    await ref.read(productListProvider.notifier).delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

/// Rest of the file (ProductCard, _ExpiryStatus, etc.)
/// ... (No changes needed below this line) ...
///
/// Restyled ProductCard
class ProductCard extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    // UPDATED: Pass context to _getExpiryStatus
    final expiryStatus = _getExpiryStatus(product.remainingDays, context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: expiryStatus.color, width: 1.5),
      ),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildLeadingWidget(context, expiryStatus),
              const SizedBox(width: 16),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.favorite) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.favorite,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.error, // UPDATED
                          ),
                        ],
                      ],
                    ),
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand!,
                        style: TextStyle(
                          // UPDATED: Use theme
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: expiryStatus.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expiryStatus.message,
                            style: TextStyle(
                              color: expiryStatus.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // NEW: PAO Label chip
                        // --- MODIFIED: Only show if label is not empty ---
                        if (product.label.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              // UPDATED: Use theme
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.label,
                              style: TextStyle(
                                // UPDATED: Use theme
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the leading widget: either the product photo or a placeholder icon.
  Widget _buildLeadingWidget(BuildContext context, _ExpiryStatus expiryStatus) {
    // ... existing code ...
    final hasPhoto = product.photoPath != null && product.photoPath!.isNotEmpty;
    final double size = 56.0; // Increased size for photos
    final borderRadius = BorderRadius.circular(12);
    if (hasPhoto) {
      try {
        // Use ClipRRect for rounded corners on the image
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            File(product.photoPath!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Add an error builder in case the file is missing/corrupt
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(
                context,
                expiryStatus,
                size,
                borderRadius,
              );
            },
          ),
        );
      } catch (e) {
        // Catch potential exceptions from File constructor (e.g., invalid path)
        return _buildPlaceholder(context, expiryStatus, size, borderRadius);
      }
    } else {
      // No photo, show the original status indicator
      return _buildPlaceholder(context, expiryStatus, size, borderRadius);
    }
  }

  /// Builds the placeholder (the original status icon)
  Widget _buildPlaceholder(
    BuildContext context,
    _ExpiryStatus expiryStatus,
    double size,
    BorderRadius borderRadius,
  ) {
    // ... existing code ...
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: expiryStatus.color.withOpacity(0.15),
        borderRadius: borderRadius,
      ),
      child: Icon(
        expiryStatus.icon,
        color: expiryStatus.color,
        size: 28, // Slightly larger icon for the larger box
      ),
    );
  }

  // UPDATED: Pass context
  _ExpiryStatus _getExpiryStatus(int remainingDays, BuildContext context) {
    if (remainingDays < 0) {
      return _ExpiryStatus(
        message: 'Expired ${remainingDays.abs()}d ago',
        color: AppColors.expired, // Kept semantic color
        icon: Icons.error_rounded,
      );
    } else if (remainingDays == 0) {
      return _ExpiryStatus(
        message: 'Expires today!',
        color: AppColors.warning, // Kept semantic color
        icon: Icons.warning_amber_rounded,
      );
    } else if (remainingDays <= 7) {
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: AppColors.warning, // Kept semantic color
        icon: Icons.warning_amber_rounded,
      );
    } else if (remainingDays <= 30) {
      // Use a less "urgent" color for 8-30 days
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: Theme.of(context).colorScheme.primary, // UPDATED
        icon: Icons.info_outline_rounded,
      );
    } else {
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: AppColors.success, // Kept semantic color
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }
}

class _ExpiryStatus {
  final String message;
  final Color color;
  final IconData icon;
  _ExpiryStatus({
    required this.message,
    required this.color,
    required this.icon,
  });
}

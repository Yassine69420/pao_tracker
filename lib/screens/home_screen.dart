import 'dart:io'; // <-- Add this import for File operations
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../models/product_item.dart';
import '../utils/colors.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

// Enum for the filter chips
enum ProductFilter { all, favorites, expiring, expired, safe }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  ProductFilter _selectedFilter = ProductFilter.all;

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

  /// Gets the styling colors for a filter chip
  (Color, Color, Color) _getChipStyle(
    ProductFilter filter,
    bool isSelected,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    // Default unselected style
    Color chipBackgroundColor = theme.colorScheme.surface;
    Color labelColor = AppColors.onSurfaceVariant;
    Color borderColor = AppColors.outlineVariant;
    switch (filter) {
      case ProductFilter.all:
        labelColor = AppColors.primary;
        borderColor = isSelected ? Colors.transparent : AppColors.primary;
        chipBackgroundColor = isSelected
            ? AppColors.primaryContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? AppColors.onPrimaryContainer
            : AppColors.primary;
        break;
      case ProductFilter.favorites:
        labelColor = AppColors.tertiary;
        borderColor = isSelected ? Colors.transparent : AppColors.tertiary;
        chipBackgroundColor = isSelected
            ? AppColors.tertiaryContainer
            : theme.colorScheme.surface;
        labelColor = isSelected
            ? AppColors.onTertiaryContainer
            : AppColors.tertiary;
        break;
      case ProductFilter.expiring:
        // Using Warning colors
        labelColor = AppColors.warning;
        borderColor = isSelected ? Colors.transparent : AppColors.warning;
        chipBackgroundColor = isSelected
            ? AppColors.warningContainer
            : theme.colorScheme.surface;
        // Define a fitting "onWarningContainer" color
        labelColor = isSelected ? Color(0xFFC77C0E) : AppColors.warning;
        break;
      case ProductFilter.expired:
        // Using Error colors
        labelColor = AppColors.error;
        borderColor = isSelected ? Colors.transparent : AppColors.error;
        chipBackgroundColor = isSelected
            ? AppColors.errorContainer
            : theme.colorScheme.surface;
        labelColor = isSelected ? AppColors.onErrorContainer : AppColors.error;
        break;
      case ProductFilter.safe:
        // Using Success colors
        labelColor = AppColors.success;
        borderColor = isSelected ? Colors.transparent : AppColors.success;
        chipBackgroundColor = isSelected
            ? AppColors.successContainer
            : theme.colorScheme.surface;
        // Re-using onPrimaryContainer as it's a fitting dark green
        labelColor = isSelected
            ? AppColors.onPrimaryContainer
            : AppColors.success;
        break;
    }
    return (chipBackgroundColor, labelColor, borderColor);
  }

  @override
  Widget build(BuildContext context) {
    final productListAsync = ref.watch(productListProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents tint on scroll
        actions: [
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
                AppColors.surfaceVariant.withOpacity(0.5),
              ),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
              // Add showScrollbar: true if you have many filters
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
                // Apply filtering to the list
                final displayedProducts = _getFilteredProducts(
                  products,
                  _selectedFilter,
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
                    // [FIX] This padding clears the floating nav bar.
                    // 88px is the magic number: ~80px for the nav bar + 8px padding.
                    // This must be coordinated with the FAB's padding.
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
                        background: _buildDismissibleBackground(),
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
  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12), // Match card
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        Icons.delete_sweep_rounded,
        color: AppColors.onErrorContainer,
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
      // This case covers when filters/search result in empty
      // but the database itself is not empty.
      title = 'No products found';
      subtitle = 'Pull to refresh or try a different filter/sort';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
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

  /// Shows the delete confirmation dialog.
  /// Returns `true` if delete is confirmed, `false` otherwise.
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

  /// Performs the actual deletion logic.
  void _performDelete(String id) async {
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

/// Restyled ProductCard
class ProductCard extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final remainingDays = product.remainingDays;
    final expiryStatus = _getExpiryStatus(remainingDays);
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
                            color: AppColors.error,
                          ),
                        ],
                      ],
                    ),
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand!,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors
                                .surfaceVariant, // soft, card-like gray
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.label,
                            style: const TextStyle(
                              color: AppColors
                                  .onSurfaceVariant, // slightly darker text
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

  _ExpiryStatus _getExpiryStatus(int remainingDays) {
    if (remainingDays < 0) {
      return _ExpiryStatus(
        message: 'Expired ${remainingDays.abs()}d ago',
        color: AppColors.expired,
        icon: Icons.error_rounded,
      );
    } else if (remainingDays == 0) {
      return _ExpiryStatus(
        message: 'Expires today!',
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    } else if (remainingDays <= 7) {
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    } else if (remainingDays <= 30) {
      // Use a less "urgent" color for 8-30 days
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: AppColors.primary,
        icon: Icons.info_outline_rounded,
      );
    } else {
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: AppColors.success,
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

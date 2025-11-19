import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_item.dart';
import '../providers/product_provider.dart';
// Kept for semantic colors (expired, warning, success)
import '../utils/colors.dart';
import 'add_edit_screen.dart';

class DetailScreen extends ConsumerWidget {
  final String productId;

  const DetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // --- UPDATED: Use theme color ---
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Product Details'),
        // --- UPDATED: Use theme color ---
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          // --- MODIFICATION START ---
          // Add a favorite toggle button to the app bar
          productAsync.maybeWhen(
            data: (product) => product != null
                ? IconButton(
                    icon: Icon(
                      product.favorite
                          ? Icons.favorite
                          : Icons.favorite_border_outlined,
                      // --- UPDATED: Use theme color ---
                      color: product.favorite ? colorScheme.error : null,
                    ),
                    onPressed: () => _toggleFavorite(ref, product, context),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),

          // --- MODIFICATION END ---
          productAsync.maybeWhen(
            data: (product) => product != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _navigateToEdit(context, ref, product),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    // --- UPDATED: Use theme color ---
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Product not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }
          return _ProductDetailContent(product: product);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  // --- UPDATED: Use theme color ---
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading product',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // --- UPDATED: Use theme color ---
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW METHOD ---
  /// Toggles the favorite status of the product
  void _toggleFavorite(
    WidgetRef ref,
    ProductItem product,
    BuildContext context,
  ) async {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final updatedProduct = product.copyWith(favorite: !product.favorite);
      // Call the update method from the provider
      await ref.read(productListProvider.notifier).update(updatedProduct);

      // Invalidate providers to refresh UI
      ref.invalidate(productProvider(product.id));
      ref.invalidate(productListProvider);

      if (context.mounted) {
        // Show a brief confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedProduct.favorite
                  ? 'Added to favorites'
                  : 'Removed from favorites',
                 
            ),
            duration: Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          // --- UPDATED: Use theme color ---
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(milliseconds: 500),

        ),
      );
    }
  }
  // --- END NEW METHOD ---

  void _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    ProductItem product,
  ) async {
    // FIXED: Wait for result and refresh if updated
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEditScreen(product: product)),
    );

    // FIXED: Only invalidate if something was actually updated
    if (result == true) {
      ref.invalidate(productProvider(productId));
      // ADDED: Also refresh the main product list
      ref.invalidate(productListProvider);
    }
  }
}

class _ProductDetailContent extends ConsumerWidget {
  final ProductItem product;

  const _ProductDetailContent({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    final remainingDays = product.remainingDays;
    final progress = _calculateProgress();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        if (product.photoPath != null)
          Center(
            child: Hero(
              tag: 'product_${product.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(product.photoPath!),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Product name and favorite
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.brand!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // --- UPDATED: Use theme color ---
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // --- MODIFICATION ---
            // Removed the static favorite icon from here
          ],
        ),
        const SizedBox(height: 24),

        // Expiry progress card
        Card(
          elevation: 2,
          // --- UPDATED: Pass context ---
          shadowColor: _getProgressColor(
            remainingDays,
            context,
          ).withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // --- UPDATED: Use theme color ---
                    Icon(Icons.schedule_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Expiry Timeline',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    // --- UPDATED: Use theme color ---
                    backgroundColor: colorScheme.surfaceVariant,
                    // --- UPDATED: Pass context ---
                    color: _getProgressColor(remainingDays, context),
                  ),
                ),
                const SizedBox(height: 16),

                // Dates row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DateInfo(
                      label: 'Opened',
                      date: product.openedDate,
                      icon: Icons.calendar_today_outlined,
                    ),
                    _DateInfo(
                      label: 'Expires',
                      date: product.expiryDate,
                      icon: Icons.event_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Remaining days display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      // --- UPDATED: Pass context ---
                      color: _getProgressColor(
                        remainingDays,
                        context,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          remainingDays >= 0
                              ? '$remainingDays'
                              : '${remainingDays.abs()}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            // --- UPDATED: Pass context ---
                            color: _getProgressColor(remainingDays, context),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remainingDays >= 0
                              ? 'days remaining'
                              : 'days expired',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            // --- UPDATED: Pass context ---
                            color: _getProgressColor(remainingDays, context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- MODIFICATION START ---
        // Restyled info cards to be side-by-side
        Column(
          children: [
            if (product.label.isNotEmpty) ...[
              _InfoCard(
                icon: Icons.label_outlined,
                title: 'PAO Label',
                value: product.label,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),

              _InfoCard(
                icon: Icons.hourglass_bottom_outlined,
                title: 'Shelf Life',
                value:
                    '${product.shelfLifeDays} days (≈${(product.shelfLifeDays / 30).round()} months)',
                color: colorScheme.secondary,
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // --- MODIFICATION END ---
        // Notes
        if (product.notes != null && product.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // --- UPDATED: Use theme color ---
                      Icon(Icons.note_outlined, color: colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...product.notes!.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              // --- UPDATED: Use theme color ---
                              color: colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Delete button
        OutlinedButton.icon(
          onPressed: () => _deleteProduct(context, ref),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete Product'),
          style: OutlinedButton.styleFrom(
            // --- UPDATED: Use theme color ---
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  double _calculateProgress() {
    final totalDays = product.shelfLifeDays;
    // Prevent division by zero if shelfLifeDays is 0
    if (totalDays == 0) {
      // If not opened, progress is 0. If opened and no shelf life, treat as 100% elapsed.
      return product.isOpened ? 1.0 : 0.0;
    }
    final elapsed = DateTime.now().difference(product.openedDate).inDays;
    final progress = elapsed / totalDays;
    return progress.clamp(0.0, 1.0);
  }

  // --- UPDATED: Pass context to get theme colors ---
  Color _getProgressColor(int remainingDays, BuildContext context) {
    if (remainingDays < 0) return AppColors.expired; // Keep semantic color
    if (remainingDays <= 7) return AppColors.warning; // Keep semantic color
    if (remainingDays <= 30) {
      // --- UPDATED: Use theme color ---
      return Theme.of(context).colorScheme.primary;
    }
    return AppColors.success; // Keep semantic color
  }

  void _deleteProduct(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
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
            // --- UPDATED: Use theme color ---
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(productListProvider.notifier).delete(product.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 500),// <- shorter time
          ),
        );
      }
    }
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;

  const _DateInfo({
    required this.label,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // --- UPDATED: Use theme color ---
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                // --- UPDATED: Use theme color ---
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(date),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      // --- UPDATED: Use theme color ---
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    // Allow text to wrap if it's too long
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pao_tracker/utils/colors.dart';
import '../models/product_item.dart';
import '../providers/product_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // --- UPDATED: Use theme color ---
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Statistics'),
        // --- UPDATED: Use theme color ---
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: productListAsync.when(
        data: (products) {
          if (products.isEmpty) return _buildEmptyState(context);
          return _buildStatsView(context, products);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to load statistics:\n$e',
              textAlign: TextAlign.center,
              // --- UPDATED: Use theme color ---
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsView(BuildContext context, List<ProductItem> products) {
    // --- NEW: Get themes ---
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final totalProducts = products.length;
    final totalFavorites = products.where((p) => p.favorite).length;
    final totalExpired = products.where((p) => p.remainingDays < 0).length;
    final totalExpiring = products
        .where((p) => p.remainingDays >= 0 && p.remainingDays <= 7)
        .length;
    final totalSafe = products.where((p) => p.remainingDays > 7).length;

    // labels
    final labelCounts = <String, int>{};
    for (final p in products) {
      // Use a placeholder if label is empty
      final label = p.label.isEmpty ? 'No Label' : p.label;
      labelCounts.update(label, (v) => v + 1, ifAbsent: () => 1);
    }
    final sortedLabels = labelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLabels = sortedLabels.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Overview',
            style: textTheme.titleLarge?.copyWith(
              // --- UPDATED: Use theme color ---
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // KPI cards using Wrap for better responsiveness
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _compactStatCard(
                context, // --- UPDATED ---
                'Total',
                totalProducts.toString(),
                Icons.inventory_2_outlined,
                // --- UPDATED: Use theme color ---
                colorScheme.primary,
              ),
              _compactStatCard(
                context, // --- UPDATED ---
                'Favorites',
                totalFavorites.toString(),
                Icons.favorite_border_rounded,
                // --- UPDATED: Use theme color ---
                colorScheme.tertiary,
              ),
              _compactStatCard(
                context, // --- UPDATED ---
                'Expired',
                totalExpired.toString(),
                Icons.error_outline_rounded,
                // --- UPDATED: Use theme color ---
                colorScheme.error,
              ),
              _compactStatCard(
                context, // --- UPDATED ---
                'Expiring',
                totalExpiring.toString(),
                Icons.watch_later_outlined,
                AppColors.warning, // Keep semantic color
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status chart + legend in a unified card
          Text(
            'Product Status',
            style: textTheme.titleLarge?.copyWith(
              // --- UPDATED: Use theme color ---
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // --- UPDATED: Pass context ---
          _statusCard(context, totalSafe, totalExpiring, totalExpired),

          const SizedBox(height: 18),

          // Most common labels
          Text(
            'Most Common Labels',
            style: textTheme.titleLarge?.copyWith(
              // --- UPDATED: Use theme color ---
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (topLabels.isEmpty)
            Text(
              'No labels found.',
              style: textTheme.bodyMedium?.copyWith(
                // --- UPDATED: Use theme color ---
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: topLabels
                  .map(
                    (e) => _labelRow(context, e.key, e.value, products.length),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // Compact stat card used in the Wrap
  Widget _compactStatCard(
    BuildContext context, // --- UPDATED ---
    String title,
    String value,
    IconData icon,
    Color accent,
  ) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 160, // keeps a consistent footprint
      child: Card(
        elevation: 0,
        // --- UPDATED: Use theme color ---
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // --- UPDATED: Use theme color ---
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  // --- UPDATED: Use theme color ---
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  // --- UPDATED: Use theme color ---
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(
      BuildContext context, int safe, int expiring, int expired) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    final total = safe + expiring + expired;
    if (total == 0) {
      return Card(
        elevation: 0,
        // --- UPDATED: Use theme color ---
        color: colorScheme.surfaceVariant.withOpacity(0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'No products to analyze',
                  // --- UPDATED: Use theme color ---
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safePct = safe / total;
    final expiringPct = expiring / total;
    final expiredPct = expired / total;

    return Card(
      elevation: 0,
      // --- UPDATED: Use theme color ---
      color: colorScheme.surfaceVariant.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stacked bar with min flex fallback for tiny slices
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (safe > 0)
                    Expanded(
                      flex: (safePct * 100).clamp(1, 100).toInt(),
                      child: Container(height: 18, color: AppColors.success),
                    ),
                  if (expiring > 0)
                    Expanded(
                      flex: (expiringPct * 100).clamp(1, 100).toInt(),
                      child: Container(height: 18, color: AppColors.warning),
                    ),
                  if (expired > 0)
                    Expanded(
                      flex: (expiredPct * 100).clamp(1, 100).toInt(),
                      // --- UPDATED: Use theme color ---
                      child: Container(height: 18, color: colorScheme.error),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14), // Increased spacing
            // [FIX] Redesigned Legend: Vertical layout to prevent overflow
            Column(
              children: [
                _legendItem(
                  context, // --- UPDATED ---
                  AppColors.success,
                  'Safe',
                  safe,
                  (safePct * 100),
                ),
                const SizedBox(height: 6), // Spacing between items
                _legendItem(
                  context, // --- UPDATED ---
                  AppColors.warning,
                  'Expiring',
                  expiring,
                  (expiringPct * 100),
                ),
                const SizedBox(height: 6), // Spacing between items
                _legendItem(
                  context, // --- UPDATED ---
                  // --- UPDATED: Use theme color ---
                  colorScheme.error,
                  'Expired',
                  expired,
                  (expiredPct * 100),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(
      BuildContext context, Color color, String title, int count, double pct) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        // [FIX] Use Flexible to allow title to shrink and avoid overflow
        Flexible(
          child: Text(
            title,
            // --- UPDATED: Use theme color ---
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            overflow: TextOverflow.ellipsis, // Add ellipsis for long text
            maxLines: 1,
          ),
        ),
        const Spacer(),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            // --- UPDATED: Use theme color ---
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        // --- UPDATED: Use theme color ---
        Text('($count)', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _labelRow(BuildContext context, String label, int count, int total) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    final pct = total == 0 ? 0.0 : (count / total * 100);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      // --- UPDATED: Use theme color ---
      color: colorScheme.surfaceVariant.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                // --- UPDATED: Use theme color ---
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  // --- UPDATED: Use theme color ---
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count items',
              // --- UPDATED: Use theme color ---
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                // --- UPDATED: Use theme color ---
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 84,
            // --- UPDATED: Use theme color ---
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No Statistics Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  // --- UPDATED: Use theme color ---
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to see your stats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // --- UPDATED: Use theme color ---
                  color: colorScheme.onSurfaceVariant.withOpacity(0.75),
                ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pao_tracker/utils/colors.dart';
import '../models/product_item.dart';
import '../providers/product_provider.dart';

/// Redesigned StatisticsScreen
/// - tighter spacing
/// - responsive KPI grid using Wrap
/// - unified card styles
/// - cleaner status bar and legend
/// - accessible contrast and breathing room
/// - [FIX] Redesigned status legend to a Column to fix overflow.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: AppColors.surface,
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
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsView(BuildContext context, List<ProductItem> products) {
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
      labelCounts.update(p.label, (v) => v + 1, ifAbsent: () => 1);
    }
    final sortedLabels = labelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLabels = sortedLabels.take(3).toList();

    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Overview',
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface,
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
                'Total',
                totalProducts.toString(),
                Icons.inventory_2_outlined,
                AppColors.primary,
              ),
              _compactStatCard(
                'Favorites',
                totalFavorites.toString(),
                Icons.favorite_border_rounded,
                AppColors.tertiary,
              ),
              _compactStatCard(
                'Expired',
                totalExpired.toString(),
                Icons.error_outline_rounded,
                AppColors.error,
              ),
              _compactStatCard(
                'Expiring',
                totalExpiring.toString(),
                Icons.watch_later_outlined,
                AppColors.warning,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status chart + legend in a unified card
          Text(
            'Product Status',
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _statusCard(totalSafe, totalExpiring, totalExpired),

          const SizedBox(height: 18),

          // Most common labels
          Text(
            'Most Common Labels',
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (topLabels.isEmpty)
            Text(
              'No labels found.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
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
    String title,
    String value,
    IconData icon,
    Color accent,
  ) {
    return SizedBox(
      width: 160, // keeps a consistent footprint
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.45)),
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
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(int safe, int expiring, int expired) {
    final total = safe + expiring + expired;
    if (total == 0) {
      return Card(
        elevation: 0,
        color: AppColors.surfaceVariant.withOpacity(0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'No products to analyze',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
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
      color: AppColors.surfaceVariant.withOpacity(0.12),
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
                      child: Container(height: 18, color: AppColors.error),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14), // Increased spacing
            // [FIX] Redesigned Legend: Vertical layout to prevent overflow
            Column(
              children: [
                _legendItem(
                  AppColors.success,
                  'Safe',
                  safe,
                  (safePct * 100),
                ),
                const SizedBox(height: 6), // Spacing between items
                _legendItem(
                  AppColors.warning,
                  'Expiring',
                  expiring,
                  (expiringPct * 100),
                ),
                const SizedBox(height: 6), // Spacing between items
                _legendItem(
                  AppColors.error,
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

  Widget _legendItem(Color color, String title, int count, double pct) {
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
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            overflow: TextOverflow.ellipsis, // Add ellipsis for long text
            maxLines: 1,
          ),
        ),
        const Spacer(),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text('($count)', style: TextStyle(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _labelRow(BuildContext context, String label, int count, int total) {
    final pct = total == 0 ? 0.0 : (count / total * 100);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surfaceVariant.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count items',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 84,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No Statistics Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to see your stats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant.withOpacity(0.75),
                ),
          ),
        ],
      ),
    );
  }
}
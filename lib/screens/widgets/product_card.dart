import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pao_tracker/models/product_item.dart';
import 'package:pao_tracker/models/category.dart';
import 'package:pao_tracker/utils/colors.dart';

class ProductCard extends StatelessWidget {
  final ProductItem product;
  final Category? category;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Category Indicator (if not shown in placeholder)
                    if (category != null &&
                        (product.photoPath != null &&
                            product.photoPath!.isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            category!.icon,
                            size: 12,
                            color: category!.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              category!.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                        // PAO Label chip
                        if (product.label.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.label,
                              style: TextStyle(
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
    final hasPhoto = product.photoPath != null && product.photoPath!.isNotEmpty;
    const double size = 56.0; // Increased size for photos
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
      // No photo, show the original status indicator OR category icon
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
    // If we have a category, use its color and icon
    final bgColor =
        category?.color.withOpacity(0.15) ??
        expiryStatus.color.withOpacity(0.15);
    final iconColor = category?.color ?? expiryStatus.color;
    final iconData = category?.icon ?? expiryStatus.icon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }

  _ExpiryStatus _getExpiryStatus(int remainingDays, BuildContext context) {
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
      return _ExpiryStatus(
        message: '$remainingDays days left',
        color: Theme.of(context).colorScheme.primary,
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

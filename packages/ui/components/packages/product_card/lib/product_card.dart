import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:price_tag/price_tag.dart';
import 'package:rating_stars/rating_stars.dart';

/// Product card shared by the catalog grid, dashboard carousels and
/// favorites list.
///
/// Image handling is byte-based ([imageBytes]) so the card stays agnostic of
/// the per-platform storage (file path on mobile, data URI on web); when no
/// image exists it falls back to the category icon.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.name,
    required this.subtitle,
    required this.priceValue,
    required this.locale,
    required this.currencyCode,
    required this.categoryIcon,
    super.key,
    this.imageBytes,
    this.rating,
    this.ratingCount,
    this.stockText,
    this.outOfStock = false,
    this.badge,
    this.trailing,
    this.onTap,
  });

  final String name;

  /// Already-translated secondary line (category · condition).
  final String subtitle;

  final double priceValue;
  final String locale;
  final String currencyCode;
  final IconData categoryIcon;
  final Uint8List? imageBytes;
  final double? rating;
  final int? ratingCount;

  /// Already-translated stock line; rendered in error color when
  /// [outOfStock] is true.
  final String? stockText;

  final bool outOfStock;

  /// Optional status badge slot (paused, out of stock, deleted by owner).
  final Widget? badge;

  /// Optional trailing action slot (favorite toggle).
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ProductThumbnail(imageBytes: imageBytes, categoryIcon: categoryIcon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (rating != null)
                  RatingStars(rating: rating!, count: ratingCount, size: 14),
                const SizedBox(height: AppSpacing.xs),
                PriceTag(
                  value: priceValue,
                  locale: locale,
                  currencyCode: currencyCode,
                ),
                if (stockText != null)
                  Text(
                    stockText!,
                    style: AppTypography.caption.copyWith(
                      color: outOfStock
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                if (badge != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  badge!,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageBytes,
    required this.categoryIcon,
  });

  final Uint8List? imageBytes;
  final IconData categoryIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageBytes == null
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  categoryIcon,
                  size: 32,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : Image.memory(imageBytes!, fit: BoxFit.cover),
      ),
    );
  }
}

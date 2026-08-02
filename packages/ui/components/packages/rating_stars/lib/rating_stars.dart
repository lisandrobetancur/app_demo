import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Five-star rating row.
///
/// Read-only when [onRatingSelected] is null (product cards, detail header);
/// interactive in the review form, where [starKeys] gives each star its
/// stable key from the feature constants.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    super.key,
    this.count,
    this.size = 16,
    this.onRatingSelected,
    this.starKeys,
  });

  /// Average (read-only mode) or selected value (interactive mode).
  final double rating;

  /// Optional review count rendered after the stars.
  final int? count;

  final double size;

  /// When set, tapping star `n` reports `n + 1`.
  final ValueChanged<int>? onRatingSelected;

  /// Stable keys for the five stars (interactive mode).
  final List<Key>? starKeys;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < 5; index++)
          _Star(
            key: starKeys != null && index < starKeys!.length
                ? starKeys![index]
                : null,
            filled: rating >= index + 0.5,
            size: size,
            onTap: onRatingSelected == null
                ? null
                : () => onRatingSelected!(index + 1),
          ),
        if (count != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($count)',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.filled,
    required this.size,
    required this.onTap,
    super.key,
  });

  final bool filled;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(
      filled ? AppIcons.star : AppIcons.starOutline,
      size: size,
      color: AppColors.secondary,
    );
    if (onTap == null) {
      return icon;
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: icon,
      ),
    );
  }
}

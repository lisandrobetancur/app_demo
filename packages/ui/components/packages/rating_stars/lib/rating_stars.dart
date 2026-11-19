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
    this.starSemanticsIds,
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

  /// Identifiers for black-box automation of the five stars (interactive
  /// mode), in order: the first one is the one-star rating.
  final List<String>? starSemanticsIds;

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
            semanticsId:
                starSemanticsIds != null && index < starSemanticsIds!.length
                ? starSemanticsIds![index]
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
    required this.semanticsId,
    super.key,
  });

  final bool filled;
  final double size;
  final VoidCallback? onTap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    Widget icon = Icon(
      filled ? AppIcons.star : AppIcons.starOutline,
      size: size,
      color: AppColors.secondary,
    );
    if (semanticsId != null) {
      // Inside the InkWell, so it merges into the star's tappable node.
      icon = Semantics(identifier: semanticsId, child: icon);
    }
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

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_radius.dart';

/// Shimmer wrapper used by every loading state.
///
/// Only rendered while a view is in its loading state, so no animation
/// outlives the data. Honors `FAST_ANIMATIONS` through [AppDurations].
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.shimmerBaseDark
          : AppColors.shimmerBaseLight,
      highlightColor: isDark
          ? AppColors.shimmerHighlightDark
          : AppColors.shimmerHighlightLight,
      period: AppDurations.shimmerPeriod == Duration.zero
          ? const Duration(milliseconds: 1)
          : AppDurations.shimmerPeriod,
      enabled: AppDurations.shimmerPeriod != Duration.zero,
      child: child,
    );
  }
}

/// Solid placeholder block used inside [AppShimmer] skeletons.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    required this.height,
    super.key,
    this.width = double.infinity,
    this.radius = AppRadius.card,
  });

  final double height;
  final double width;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: radius,
    ),
  );
}

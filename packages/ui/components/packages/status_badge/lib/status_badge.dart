import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Semantic tone of a [StatusBadge].
enum StatusBadgeTone {
  success,
  warning,
  error,
  info,
  neutral;

  bool get isSuccess => this == StatusBadgeTone.success;

  bool get isWarning => this == StatusBadgeTone.warning;

  bool get isError => this == StatusBadgeTone.error;

  bool get isInfo => this == StatusBadgeTone.info;

  bool get isNeutral => this == StatusBadgeTone.neutral;
}

/// Small pill communicating a state (order status, publication status,
/// product condition). Callers pass the translated label; the tone drives
/// the colors.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.tone, super.key});

  final String label;
  final StatusBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = switch (tone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      StatusBadgeTone.info => AppColors.info,
      StatusBadgeTone.neutral => scheme.onSurfaceVariant,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.badge,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

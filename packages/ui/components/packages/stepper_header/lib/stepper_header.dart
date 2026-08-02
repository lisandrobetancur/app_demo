import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Progress header for multi-step flows (checkout, password recovery).
///
/// Completed steps show a check, the current step is highlighted and future
/// steps stay muted. Purely presentational: the owning view drives the index.
class StepperHeader extends StatelessWidget {
  const StepperHeader({
    required this.steps,
    required this.currentIndex,
    super.key,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (int index = 0; index < steps.length; index++) ...<Widget>[
        if (index > 0)
          Expanded(
            child: Divider(
              color: index <= currentIndex
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        _StepDot(
          label: steps[index],
          index: index,
          isDone: index < currentIndex,
          isCurrent: index == currentIndex,
        ),
      ],
    ],
  );
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.index,
    required this.isDone,
    required this.isCurrent,
  });

  final String label;
  final int index;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background = isDone || isCurrent
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final Color foreground = isDone || isCurrent
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 14,
            backgroundColor: background,
            child: isDone
                ? Icon(AppIcons.check, size: 16, color: foreground)
                : Text(
                    '${index + 1}',
                    style: AppTypography.caption.copyWith(color: foreground),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

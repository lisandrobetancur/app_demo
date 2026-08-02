import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Quantity selector bounded by stock.
///
/// The increase button disables at [max] and the decrease button at [min],
/// so a controller never receives an out-of-range value from the UI.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.max,
    required this.onChanged,
    super.key,
    this.min = 1,
    this.enabled = true,
    this.decreaseKey,
    this.increaseKey,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final int min;
  final bool enabled;
  final Key? decreaseKey;
  final Key? increaseKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: AppRadius.field,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: decreaseKey,
            icon: const Icon(AppIcons.remove, size: 18),
            onPressed: enabled && value > min
                ? () => onChanged(value - 1)
                : null,
            visualDensity: VisualDensity.compact,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('$value', style: AppTypography.cardTitle),
          ),
          IconButton(
            key: increaseKey,
            icon: const Icon(AppIcons.add, size: 18),
            onPressed: enabled && value < max
                ? () => onChanged(value + 1)
                : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

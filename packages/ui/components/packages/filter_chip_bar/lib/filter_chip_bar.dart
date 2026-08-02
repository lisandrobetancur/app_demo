import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One active-filter chip.
class FilterChipItem {
  const FilterChipItem({
    required this.label,
    required this.onRemoved,
    required this.chipKey,
  });

  final String label;
  final VoidCallback onRemoved;
  final Key chipKey;
}

/// Horizontal bar of active filter chips with a trailing "clear all" action.
///
/// Hidden (zero-height) when there are no active filters.
class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    required this.chips,
    required this.clearAllLabel,
    required this.onClearAll,
    super.key,
    this.clearAllKey,
  });

  final List<FilterChipItem> chips;
  final String clearAllLabel;
  final VoidCallback onClearAll;
  final Key? clearAllKey;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final FilterChipItem chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: InputChip(
                key: chip.chipKey,
                label: Text(chip.label),
                onDeleted: chip.onRemoved,
              ),
            ),
          TextButton(
            key: clearAllKey,
            onPressed: onClearAll,
            child: Text(clearAllLabel),
          ),
        ],
      ),
    );
  }
}

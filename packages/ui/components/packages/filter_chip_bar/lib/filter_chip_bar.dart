import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One active-filter chip.
class FilterChipItem {
  const FilterChipItem({
    required this.label,
    required this.onRemoved,
    required this.chipKey,
    this.semanticsId,
  });

  final String label;
  final VoidCallback onRemoved;
  final Key chipKey;

  /// Identifier for black-box automation. Goes on the chip's label, which
  /// merges into the chip's own node.
  final String? semanticsId;
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
    this.clearAllSemanticsId,
  });

  final List<FilterChipItem> chips;
  final String clearAllLabel;
  final VoidCallback onClearAll;
  final Key? clearAllKey;

  /// Identifier of the "clear all" button, on its own node.
  final String? clearAllSemanticsId;

  Widget _labelled(String? id, Widget child) =>
      id == null ? child : Semantics(identifier: id, child: child);

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
                label: _labelled(chip.semanticsId, Text(chip.label)),
                onDeleted: chip.onRemoved,
              ),
            ),
          TextButton(
            key: clearAllKey,
            onPressed: onClearAll,
            child: _labelled(clearAllSemanticsId, Text(clearAllLabel)),
          ),
        ],
      ),
    );
  }
}

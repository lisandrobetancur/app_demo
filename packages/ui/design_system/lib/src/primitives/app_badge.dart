import 'package:flutter/material.dart';

/// Count badge stacked over a child (cart icon, notification bell).
///
/// Hidden while [count] is zero.
class AppBadge extends StatelessWidget {
  const AppBadge({required this.count, required this.child, super.key});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Badge.count(count: count, isLabelVisible: count > 0, child: child);
}

import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Standard card: themed [Card] plus consistent padding and optional tap.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return Card(child: content);
    }
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: content,
      ),
    );
  }
}

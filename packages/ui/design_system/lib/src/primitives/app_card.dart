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
    this.semanticsId,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Identifier for black-box automation (Appium, Maestro, Playwright); see
  /// `AppButton.semanticsId`.
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);
    if (semanticsId != null) {
      // Inside the card: [Card] is a semantics container, so the identifier
      // merges into the card's own node — the one with the tap, when there is
      // one. Wrapped around the card it would land on an empty parent.
      content = Semantics(identifier: semanticsId, child: content);
    }
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

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'semantic_region.dart';

/// Standard modal bottom sheet with themed shape and consistent padding.
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    Key? sheetKey,
    String? sheetSemanticsId,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final Widget sheet = SafeArea(
        child: Padding(
          key: sheetKey,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom:
                AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: child,
        ),
      );
      if (sheetSemanticsId == null) {
        return sheet;
      }
      return SemanticRegion(identifier: sheetSemanticsId, child: sheet);
    },
  );
}

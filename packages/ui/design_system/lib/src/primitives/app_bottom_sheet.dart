import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Standard modal bottom sheet with themed shape and consistent padding.
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    Key? sheetKey,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => SafeArea(
      child: Padding(
        key: sheetKey,
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: child,
      ),
    ),
  );
}

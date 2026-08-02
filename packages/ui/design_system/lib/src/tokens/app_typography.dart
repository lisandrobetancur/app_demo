import 'package:flutter/material.dart';

/// Typography tokens.
///
/// Built on top of Material 3 defaults; only weights and sizes with semantic
/// meaning for the app are pinned here.
class AppTypography {
  const AppTypography._();

  static const TextStyle displayTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Applies the pinned styles on top of a base Material text theme.
  static TextTheme textTheme(TextTheme base) => base.copyWith(
    headlineSmall: base.headlineSmall?.merge(displayTitle),
    titleLarge: base.titleLarge?.merge(sectionTitle),
    titleMedium: base.titleMedium?.merge(cardTitle),
    bodyMedium: base.bodyMedium?.merge(body),
    bodySmall: base.bodySmall?.merge(caption),
  );
}

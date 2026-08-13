import 'package:flutter/material.dart';

/// Color tokens.
///
/// No literal color exists outside this file: features and components always
/// reference the theme's `ColorScheme` or these semantic tokens.
class AppColors {
  const AppColors._();

  /// Brand seed used to derive both color schemes.
  static const Color primary = Color(0xFF0F766E);

  /// Secondary accent (highlights, offers).
  static const Color secondary = Color(0xFFF59E0B);

  /// Success feedback (order confirmed, coupon applied).
  static const Color success = Color(0xFF16A34A);

  /// Warning feedback (low stock, paused publication).
  static const Color warning = Color(0xFFD97706);

  /// Error feedback.
  static const Color error = Color(0xFFDC2626);

  /// Informational feedback.
  static const Color info = Color(0xFF2563EB);

  /// Page background in the light theme.
  ///
  /// Material 3 would otherwise paint pages in `scheme.surface`, which carries
  /// a tint of the brand seed. This keeps the background plain white and lets
  /// the tinted surfaces — app bar, cards, sheets — read as raised against it.
  static const Color backgroundLight = Color(0xFFFFFFFF);

  /// Shimmer base tone (light theme).
  static const Color shimmerBaseLight = Color(0xFFE5E7EB);

  /// Shimmer highlight tone (light theme).
  static const Color shimmerHighlightLight = Color(0xFFF9FAFB);

  /// Shimmer base tone (dark theme).
  static const Color shimmerBaseDark = Color(0xFF374151);

  /// Shimmer highlight tone (dark theme).
  static const Color shimmerHighlightDark = Color(0xFF4B5563);
}

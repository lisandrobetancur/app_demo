import 'package:flutter/widgets.dart';

/// Spacing tokens (4pt scale).
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Default page padding used by `AppScaffold`.
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// Default gap between form fields.
  static const SizedBox formGap = SizedBox(height: lg);

  /// Default gap between list sections.
  static const SizedBox sectionGap = SizedBox(height: xl);

  /// Maximum content width on large (web) layouts.
  static const double maxContentWidth = 1200;

  /// Breakpoint above which the app uses the web/desktop layout.
  static const double webBreakpoint = 768;
}

import 'package:flutter/widgets.dart';

/// Corner radius tokens.
class AppRadius {
  const AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double xl = 24;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius field = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  static const BorderRadius badge = BorderRadius.all(Radius.circular(xl));
}

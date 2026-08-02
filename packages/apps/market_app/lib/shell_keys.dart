import 'package:flutter/foundation.dart';

/// Widget keys owned by the shell (navigation chrome only).
class ShellKeys {
  const ShellKeys._();

  static const Key navigationBar = Key('shell_navigation_bar');
  static const Key navigationRail = Key('shell_navigation_rail');
  static const Key tabDashboard = Key('shell_tab_dashboard');
  static const Key tabCatalog = Key('shell_tab_catalog');
  static const Key tabCart = Key('shell_tab_cart');
  static const Key tabOrders = Key('shell_tab_orders');
  static const Key tabProfile = Key('shell_tab_profile');
}

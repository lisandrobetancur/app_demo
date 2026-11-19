/// Semantics identifiers owned by the shell (navigation chrome only).
///
/// The counterpart of `shell_keys.dart` for tools that cannot see a Flutter
/// `Key` — Appium and Maestro on mobile, Playwright on the web — reaching the
/// accessibility layer as Android's `resource-id`, iOS's
/// `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// A tab has the same identifier in the bottom bar (narrow layouts) and in the
/// side rail (wide layouts, the web on a desktop): only one of the two is ever
/// on screen, and a test should not care which.
class ShellSemanticIds {
  const ShellSemanticIds._();

  static const String navigationBar = 'shell_navigation_bar';
  static const String navigationRail = 'shell_navigation_rail';
  static const String tabDashboard = 'shell_tab_dashboard';
  static const String tabCatalog = 'shell_tab_catalog';
  static const String tabCart = 'shell_tab_cart';
  static const String tabOrders = 'shell_tab_orders';
  static const String tabProfile = 'shell_tab_profile';
}

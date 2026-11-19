/// Semantics identifiers of the dashboard feature.
///
/// The counterpart of `dashboard_keys.dart` for tools that cannot see a
/// Flutter `Key`: Appium and Maestro on mobile, Playwright on the web. Each one
/// reaches the platform's accessibility layer as Android's `resource-id`,
/// iOS's `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform.
class DashboardSemanticIds {
  const DashboardSemanticIds._();

  static const String view = 'dashboard_view';
  static const String greetingText = 'dashboard_greeting_text';
  static const String refreshButton = 'dashboard_refresh_button';
  static const String notificationsButton = 'dashboard_notifications_button';
  static const String logoutButton = 'dashboard_logout_button';
  static const String logoutDialog = 'dashboard_logout_dialog';
  static const String logoutConfirmButton =
      'dashboard_logout_dialog_confirm_button';
  static const String logoutCancelButton =
      'dashboard_logout_dialog_cancel_button';
  static const String categoryCarousel = 'dashboard_category_carousel';
  static const String recentProductsCarousel =
      'dashboard_recent_products_carousel';
  static const String goToCatalogButton = 'dashboard_go_to_catalog_button';
  static const String goToCreateProductButton =
      'dashboard_go_to_create_product_button';
  static const String goToCartButton = 'dashboard_go_to_cart_button';
  static const String goToFavoritesButton = 'dashboard_go_to_favorites_button';
  static const String goToMyProductsButton =
      'dashboard_go_to_my_products_button';
  static const String retryButton = 'dashboard_retry_button';

  /// `dashboard_state_<loading|data|empty|error>`.
  static String state(String state) => 'dashboard_state_$state';

  /// `dashboard_summary_card_<active_products|cart_items|cart_total|month_orders>`.
  /// One node whose text holds the value and its label.
  static String summaryCard(String metric) => 'dashboard_summary_card_$metric';

  /// `dashboard_category_item_<category id>`.
  static String categoryItem(String id) => 'dashboard_category_item_$id';

  /// `dashboard_recent_item_<product id>`.
  static String recentItem(String id) => 'dashboard_recent_item_$id';
}

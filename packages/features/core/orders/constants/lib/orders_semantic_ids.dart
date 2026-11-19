/// Semantics identifiers of the orders feature, grouped per view.
///
/// The counterpart of `orders_keys.dart` for tools that cannot see a Flutter
/// `Key`: Appium and Maestro on mobile, Playwright on the web. Each one reaches
/// the platform's accessibility layer as Android's `resource-id`, iOS's
/// `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform. Items of a
/// list carry their id, never their position.

/// Semantics identifiers of the orders list view.
class OrdersListSemanticIds {
  const OrdersListSemanticIds._();

  static const String view = 'orders_list_view';
  static const String titleText = 'orders_list_title_text';
  static const String searchInput = 'orders_search_input';
  static const String statusFilters = 'orders_status_filters';
  static const String retryButton = 'orders_retry_button';

  /// `orders_state_<loading|data|empty|error>`.
  static String state(String state) => 'orders_state_$state';

  /// `orders_status_filter_<all|created|paid|shipped|delivered|cancelled>`.
  /// Carries the selected state.
  static String statusFilter(String value) =>
      'orders_status_filter_${value.toLowerCase()}';

  /// `orders_item_<order id>`: one node whose text holds the order number,
  /// status, date, item count and total.
  static String item(String id) => 'orders_item_$id';
}

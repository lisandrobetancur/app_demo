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

/// Semantics identifiers of the order detail view.
class OrderDetailSemanticIds {
  const OrderDetailSemanticIds._();

  static const String view = 'order_detail_view';
  static const String titleText = 'order_detail_title_text';
  static const String orderNumberText = 'order_detail_order_number_text';
  static const String dateText = 'order_detail_date_text';

  /// One node holding every stage's label — or "cancelled". Which stage was
  /// reached is shown only by icon and weight, not exposed to accessibility.
  static const String timeline = 'order_detail_timeline';
  static const String addressText = 'order_detail_address_text';
  static const String paymentText = 'order_detail_payment_text';

  /// The money values alone, without their labels.
  static const String subtotalText = 'order_detail_subtotal_text';
  static const String discountText = 'order_detail_discount_text';
  static const String taxText = 'order_detail_tax_text';
  static const String totalText = 'order_detail_total_text';
  static const String cancelButton = 'order_detail_cancel_button';
  static const String cancelDialog = 'order_detail_cancel_dialog';
  static const String cancelConfirmButton =
      'order_detail_cancel_dialog_confirm_button';
  static const String cancelKeepButton =
      'order_detail_cancel_dialog_cancel_button';
  static const String reorderButton = 'order_detail_reorder_button';

  /// The snackbar confirming an action (cancelled, re-ordered, …).
  static const String messageText = 'order_detail_message_text';
  static const String retryButton = 'order_detail_retry_button';

  /// `order_detail_state_<loading|data|empty|error>`.
  static String state(String state) => 'order_detail_state_$state';

  /// `order_detail_item_<order item id>`: "quantity × product" and the line
  /// total.
  static String item(String id) => 'order_detail_item_$id';
}

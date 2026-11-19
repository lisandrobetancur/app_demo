/// Semantics identifiers of the cart feature, grouped per view.
///
/// The counterpart of `cart_keys.dart` for tools that cannot see a Flutter
/// `Key`: Appium and Maestro on mobile, Playwright on the web. Each one reaches
/// the platform's accessibility layer as Android's `resource-id`, iOS's
/// `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform. Items of a
/// list carry their id, never their position.

/// Semantics identifiers of the cart view.
class CartSemanticIds {
  const CartSemanticIds._();

  static const String view = 'cart_view';
  static const String titleText = 'cart_title_text';
  static const String clearButton = 'cart_clear_button';
  static const String clearDialog = 'cart_clear_dialog';
  static const String clearConfirmButton = 'cart_clear_dialog_confirm_button';
  static const String clearCancelButton = 'cart_clear_dialog_cancel_button';
  static const String itemsList = 'cart_items_list';

  /// The snackbar shown after removing a line. Its undo action has no
  /// identifier: SnackBarAction takes its label as a plain string, so there
  /// is nowhere to put one without replacing the widget.
  static const String itemRemovedText = 'cart_item_removed_text';
  static const String couponInput = 'cart_coupon_input';
  static const String applyCouponButton = 'cart_apply_coupon_button';
  static const String couponErrorText = 'cart_coupon_error_text';
  static const String couponAppliedText = 'cart_coupon_applied_text';
  static const String removeCouponButton = 'cart_remove_coupon_button';

  /// The money values alone, without their labels.
  static const String subtotalText = 'cart_subtotal_text';
  static const String discountText = 'cart_discount_text';
  static const String taxText = 'cart_tax_text';
  static const String totalText = 'cart_total_text';
  static const String checkoutButton = 'cart_checkout_button';
  static const String emptyGoToCatalogButton =
      'cart_empty_go_to_catalog_button';
  static const String retryButton = 'cart_retry_button';

  /// `cart_state_<loading|data|empty|error>`.
  static String state(String state) => 'cart_state_$state';

  /// `cart_item_<line id>`: the line's card, whose text holds the product
  /// name, unit price and any unavailable notice.
  static String item(String id) => 'cart_item_$id';

  /// `cart_item_quantity_stepper_<line id>`.
  static String itemQuantityStepper(String id) =>
      'cart_item_quantity_stepper_$id';

  /// `cart_item_quantity_text_<line id>`.
  static String itemQuantityText(String id) => 'cart_item_quantity_text_$id';

  /// `cart_decrease_quantity_button_<line id>`.
  static String decreaseQuantityButton(String id) =>
      'cart_decrease_quantity_button_$id';

  /// `cart_increase_quantity_button_<line id>`.
  static String increaseQuantityButton(String id) =>
      'cart_increase_quantity_button_$id';

  /// `cart_item_total_text_<line id>`: the line total, money only.
  static String itemTotalText(String id) => 'cart_item_total_text_$id';

  /// `cart_remove_item_button_<line id>`.
  static String removeItemButton(String id) => 'cart_remove_item_button_$id';
}

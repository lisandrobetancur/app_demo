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
  static const String itemRemovedText = 'cart_removed_item_text';
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

  // A line's parts stay out of the `cart_item_` prefix, so that
  // `[flt-semantics-identifier^="cart_item_"]` counts lines and nothing else.

  /// `cart_quantity_stepper_<line id>`.
  static String itemQuantityStepper(String id) => 'cart_quantity_stepper_$id';

  /// `cart_quantity_text_<line id>`.
  static String itemQuantityText(String id) => 'cart_quantity_text_$id';

  /// `cart_decrease_quantity_button_<line id>`.
  static String decreaseQuantityButton(String id) =>
      'cart_decrease_quantity_button_$id';

  /// `cart_increase_quantity_button_<line id>`.
  static String increaseQuantityButton(String id) =>
      'cart_increase_quantity_button_$id';

  /// `cart_line_total_text_<line id>`: the line total, money only.
  static String itemTotalText(String id) => 'cart_line_total_text_$id';

  /// `cart_remove_item_button_<line id>`.
  static String removeItemButton(String id) => 'cart_remove_item_button_$id';
}

/// Semantics identifiers of the checkout flow (all three steps).
class CheckoutSemanticIds {
  const CheckoutSemanticIds._();

  static const String view = 'checkout_view';
  static const String titleText = 'checkout_title_text';
  static const String stepIndicator = 'checkout_step_indicator';
  static const String retryButton = 'checkout_retry_button';

  // Step 1 · delivery.
  /// "Choose an address", or "no addresses yet" when there are none.
  static const String addressPromptText = 'checkout_address_prompt_text';
  static const String addAddressButton = 'checkout_add_address_button';
  static const String addressFormSheet = 'checkout_address_form_sheet';
  static const String addressLabelInput = 'checkout_address_label_input';
  static const String addressLine1Input = 'checkout_address_line1_input';
  static const String addressCityInput = 'checkout_address_city_input';

  /// Department, state or region, depending on the country.
  static const String addressRegionInput = 'checkout_address_region_input';
  static const String addressNotesInput = 'checkout_address_notes_input';
  static const String addressSaveButton = 'checkout_address_save_button';

  // Step 2 · payment.
  static const String cardNumberInput = 'checkout_card_number_input';
  static const String cardHolderInput = 'checkout_card_holder_input';
  static const String cardExpiryInput = 'checkout_card_expiry_input';
  static const String cardCvvInput = 'checkout_card_cvv_input';

  // Step 3 · summary.
  static const String errorText = 'checkout_error_text';
  static const String summaryAddressText = 'checkout_summary_address_text';
  static const String summaryPaymentText = 'checkout_summary_payment_text';

  /// The money values alone, without their labels.
  static const String subtotalText = 'checkout_subtotal_text';
  static const String discountText = 'checkout_discount_text';
  static const String taxText = 'checkout_tax_text';
  static const String totalText = 'checkout_total_text';

  // Navigation.
  static const String backButton = 'checkout_back_button';
  static const String nextButton = 'checkout_next_button';
  static const String confirmButton = 'checkout_confirm_button';

  /// `checkout_state_<loading|data|error>`.
  static String state(String state) => 'checkout_state_$state';

  /// `checkout_address_option_<address id>`.
  static String addressOption(String id) => 'checkout_address_option_$id';

  /// `checkout_payment_method_<card|cash|transfer>`. Carries the selected
  /// state.
  static String paymentMethod(String value) => 'checkout_payment_method_$value';

  /// `checkout_summary_item_<cart line id>`: "quantity × product" and the
  /// line total.
  static String summaryItem(String id) => 'checkout_summary_item_$id';
}

/// Semantics identifiers of the order confirmation shown after checkout.
class CheckoutSuccessSemanticIds {
  const CheckoutSuccessSemanticIds._();

  static const String view = 'checkout_success_view';
  static const String headlineText = 'checkout_success_headline_text';
  static const String orderNumberText = 'checkout_success_order_number_text';
  static const String goToOrderButton = 'checkout_success_go_to_order_button';
  static const String goToHomeButton = 'checkout_success_go_to_home_button';
}

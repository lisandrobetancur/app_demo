import 'package:flutter/foundation.dart';

/// Keys of the cart view (F11).
class CartKeys {
  const CartKeys._();

  static const Key view = Key('cart_view');
  static const Key itemsList = Key('cart_items_list');
  static const Key undoRemoveButton = Key('undo_remove_button');
  static const Key couponInput = Key('coupon_input');
  static const Key applyCouponButton = Key('apply_coupon_button');
  static const Key removeCouponButton = Key('remove_coupon_button');
  static const Key couponErrorText = Key('coupon_error_text');
  static const Key subtotalText = Key('cart_subtotal_text');
  static const Key discountText = Key('cart_discount_text');
  static const Key taxText = Key('cart_tax_text');
  static const Key totalText = Key('cart_total_text');
  static const Key clearCartButton = Key('clear_cart_button');
  static const Key clearCartDialog = Key('clear_cart_dialog');
  static const Key checkoutButton = Key('checkout_button');

  /// `cart_state_<estado>`.
  static Key state(String state) => Key('cart_state_$state');

  /// `cart_item_<id>` (cart line id).
  static Key item(String id) => Key('cart_item_$id');

  /// `increase_quantity_button_<id>`.
  static Key increaseQuantityButton(String id) =>
      Key('increase_quantity_button_$id');

  /// `decrease_quantity_button_<id>`.
  static Key decreaseQuantityButton(String id) =>
      Key('decrease_quantity_button_$id');

  /// `remove_item_button_<id>`.
  static Key removeItemButton(String id) => Key('remove_item_button_$id');
}

/// Keys of the checkout flow (F12).
class CheckoutKeys {
  const CheckoutKeys._();

  static const Key view = Key('checkout_view');
  static const Key stepIndicator = Key('checkout_step_indicator');
  static const Key addAddressButton = Key('add_address_button');
  static const Key cardNumberInput = Key('card_number_input');
  static const Key cardHolderInput = Key('card_holder_input');
  static const Key cardExpiryInput = Key('card_expiry_input');
  static const Key cardCvvInput = Key('card_cvv_input');
  static const Key nextButton = Key('checkout_next_button');
  static const Key backButton = Key('checkout_back_button');
  static const Key confirmButton = Key('checkout_confirm_button');
  static const Key successView = Key('checkout_success_view');
  static const Key orderNumberText = Key('order_number_text');
  static const Key goToOrderButton = Key('go_to_order_button');
  static const Key goToHomeButton = Key('go_to_home_button');

  /// `address_option_<id>`.
  static Key addressOption(String id) => Key('address_option_$id');

  /// `payment_method_<value>`.
  static Key paymentMethod(String value) => Key('payment_method_$value');
}

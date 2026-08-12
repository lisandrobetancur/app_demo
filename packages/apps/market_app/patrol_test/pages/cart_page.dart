import 'package:cart_constants/cart_constants.dart';
import 'package:design_system/design_system.dart';
import 'package:patrol/patrol.dart';

import 'base_page.dart';

/// F11 · Cart.
class CartPage extends BasePage {
  const CartPage(super.$);

  @override
  PatrolFinder get root => $(CartKeys.view);

  PatrolFinder get itemsList => $(CartKeys.itemsList);

  PatrolFinder get couponInput => $(CartKeys.couponInput);

  PatrolFinder get applyCouponButton => $(CartKeys.applyCouponButton);

  PatrolFinder get removeCouponButton => $(CartKeys.removeCouponButton);

  PatrolFinder get couponErrorText => $(CartKeys.couponErrorText);

  PatrolFinder get subtotalText => $(CartKeys.subtotalText);

  PatrolFinder get discountText => $(CartKeys.discountText);

  PatrolFinder get taxText => $(CartKeys.taxText);

  PatrolFinder get totalText => $(CartKeys.totalText);

  PatrolFinder get clearCartButton => $(CartKeys.clearCartButton);

  PatrolFinder get checkoutButton => $(CartKeys.checkoutButton);

  PatrolFinder get undoRemoveButton => $(CartKeys.undoRemoveButton);

  PatrolFinder state(String name) => $(CartKeys.state(name));

  /// A cart line by its id.
  PatrolFinder item(String cartItemId) => $(CartKeys.item(cartItemId));

  PatrolFinder increaseQuantityButton(String cartItemId) =>
      $(CartKeys.increaseQuantityButton(cartItemId));

  PatrolFinder decreaseQuantityButton(String cartItemId) =>
      $(CartKeys.decreaseQuantityButton(cartItemId));

  PatrolFinder removeItemButton(String cartItemId) =>
      $(CartKeys.removeItemButton(cartItemId));

  Future<void> enterCoupon(String code) =>
      act('coupon_typed_$code', () => couponInput.enterText(code));

  Future<void> applyCoupon() =>
      act('coupon_applied', () => applyCouponButton.tap());

  Future<void> removeCoupon() =>
      act('coupon_removed', () => removeCouponButton.tap());

  Future<void> goToCheckout() =>
      act('checkout_opened', () => checkoutButton.tap());

  Future<void> undoRemove() =>
      act('remove_undone', () => undoRemoveButton.tap());

  /// Disabled while a line is unavailable or the cart is empty.
  bool get isCheckoutEnabled =>
      $.tester.widget<AppButton>(checkoutButton.finder).onPressed != null;
}

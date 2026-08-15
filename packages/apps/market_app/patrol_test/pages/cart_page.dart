import 'package:cart_constants/cart_constants.dart';
import 'package:design_system/design_system.dart';
import 'package:patrol/patrol.dart';

import '../support/money.dart';
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

  Future<void> enterCoupon(String code) => couponInput.enterText(code);

  Future<void> applyCoupon() => applyCouponButton.tap();

  Future<void> removeCoupon() => removeCouponButton.tap();

  Future<void> goToCheckout() => checkoutButton.tap();

  Future<void> undoRemove() => undoRemoveButton.tap();

  /// Disabled while a line is unavailable or the cart is empty.
  bool get isCheckoutEnabled =>
      $.tester.widget<AppButton>(checkoutButton.finder).onPressed != null;

  // --- Rendered totals, read back as numbers ---
  //
  // The cart is the one screen where "the widget is there" says nothing: the
  // whole point of the block is the arithmetic. These expose the amounts so a
  // step can check the rule; whether they add up is not the page's call.

  double get subtotal => Money.parse(valueIn(subtotalText));

  /// Rendered with a leading `-`, so this comes back negative. The steps
  /// compare against its magnitude.
  double get discount => Money.parse(valueIn(discountText));

  double get tax => Money.parse(valueIn(taxText));

  double get total => Money.parse(valueIn(totalText));
}

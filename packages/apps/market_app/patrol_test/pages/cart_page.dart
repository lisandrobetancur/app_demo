import 'package:cart_constants/cart_constants.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_kit/patrol_kit.dart';


/// F11 · Cart.
class CartPage extends BasePage {
  const CartPage(super.$);

  // --- Locators ------------------------------------------------------------

  static final Loc _view = Loc.widgetKey(CartKeys.view);
  static final Loc _itemsList = Loc.widgetKey(CartKeys.itemsList);
  static final Loc _couponInput = Loc.widgetKey(CartKeys.couponInput);
  static final Loc _applyCouponButton = Loc.widgetKey(
    CartKeys.applyCouponButton,
  );
  static final Loc _removeCouponButton = Loc.widgetKey(
    CartKeys.removeCouponButton,
  );
  static final Loc _couponErrorText = Loc.widgetKey(CartKeys.couponErrorText);
  static final Loc _subtotalText = Loc.widgetKey(CartKeys.subtotalText);
  static final Loc _discountText = Loc.widgetKey(CartKeys.discountText);
  static final Loc _taxText = Loc.widgetKey(CartKeys.taxText);
  static final Loc _totalText = Loc.widgetKey(CartKeys.totalText);
  static final Loc _clearCartButton = Loc.widgetKey(CartKeys.clearCartButton);
  static final Loc _checkoutButton = Loc.widgetKey(CartKeys.checkoutButton);
  static final Loc _undoRemoveButton = Loc.widgetKey(CartKeys.undoRemoveButton);

  // Parameterised locators: the same strategy, resolved per id.
  static Loc _state(String name) => Loc.widgetKey(CartKeys.state(name));
  static Loc _item(String id) => Loc.widgetKey(CartKeys.item(id));

  // --- Elements ------------------------------------------------------------

  @override
  PatrolFinder get root => _view.resolve($);

  UiElement get itemsList => element(_itemsList);

  UiElement get couponInput => element(_couponInput);

  UiElement get applyCouponButton => element(_applyCouponButton);

  UiElement get removeCouponButton => element(_removeCouponButton);

  UiElement get couponErrorText => element(_couponErrorText);

  UiElement get subtotalText => element(_subtotalText);

  UiElement get discountText => element(_discountText);

  UiElement get taxText => element(_taxText);

  UiElement get totalText => element(_totalText);

  UiElement get clearCartButton => element(_clearCartButton);

  UiElement get checkoutButton => element(_checkoutButton);

  UiElement get undoRemoveButton => element(_undoRemoveButton);

  UiElement state(String name) => element(_state(name));

  /// A cart line by its id.
  UiElement item(String cartItemId) => element(_item(cartItemId));

  UiElement increaseQuantityButton(String cartItemId) =>
      element(Loc.widgetKey(CartKeys.increaseQuantityButton(cartItemId)));

  UiElement decreaseQuantityButton(String cartItemId) =>
      element(Loc.widgetKey(CartKeys.decreaseQuantityButton(cartItemId)));

  UiElement removeItemButton(String cartItemId) =>
      element(Loc.widgetKey(CartKeys.removeItemButton(cartItemId)));

  // --- Actions -------------------------------------------------------------

  Future<void> enterCoupon(String code) => couponInput.type(code);

  Future<void> applyCoupon() => applyCouponButton.click();

  Future<void> removeCoupon() => removeCouponButton.click();

  Future<void> goToCheckout() => checkoutButton.click();

  Future<void> undoRemove() => undoRemoveButton.click();

  // --- Reads ---------------------------------------------------------------

  /// Disabled while a line is unavailable or the cart is empty.
  bool get isCheckoutEnabled => checkoutButton.isEnabled;

  // The rendered totals, read back as numbers.
  //
  // The cart is the one screen where "the widget is there" says nothing: the
  // whole point of the block is the arithmetic. These expose the amounts so a
  // step can check the rule; whether they add up is not the page's call.

  double get subtotal => Money.parse(subtotalText.text);

  /// Rendered with a leading `-`, so this comes back negative. The steps
  /// compare against its magnitude.
  double get discount => Money.parse(discountText.text);

  double get tax => Money.parse(taxText.text);

  double get total => Money.parse(totalText.text);
}

/// Route table of the cart feature.
class CartRoutes {
  const CartRoutes._();

  static const String cartPath = '/cart';
  static const String cartName = 'Cart Home';

  static const String checkoutPath = '/cart/checkout';
  static const String checkoutName = 'Cart Checkout';

  static const String checkoutSuccessPath = '/cart/checkout-success/:orderId';
  static const String checkoutSuccessName = 'Cart Checkout Success';

  /// Path parameter of the success route.
  static const String orderIdParam = 'orderId';
}

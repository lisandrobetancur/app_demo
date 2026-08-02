part of com.demo.market.cart.core;

/// Riverpod handle for [CartNavigator].
final NotifierProvider<CartNavigator, void> cartNavigator =
    NotifierProvider<CartNavigator, void>(CartNavigator.new);

/// Navigation intents of the cart feature.
class CartNavigator extends FeatureNavigator {
  void goToCart() => navigation.goNamed(CartRoutes.cartName);

  void goToCheckout() => navigation.pushNamed(CartRoutes.checkoutName);

  void goToCheckoutSuccess(String orderId) => navigation.goNamed(
    CartRoutes.checkoutSuccessName,
    pathParameters: <String, String>{CartRoutes.orderIdParam: orderId},
  );

  /// Cross-feature destinations, by path only.
  void goToOrderDetail(String orderId) =>
      navigation.go('/orders/detail/$orderId');

  void goToDashboard() => navigation.go('/dashboard');

  void goToCatalog() => navigation.go('/catalog');

  void back() => navigation.pop();
}

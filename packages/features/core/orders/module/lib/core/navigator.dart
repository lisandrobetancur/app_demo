part of com.demo.market.orders.core;

/// Riverpod handle for [OrdersNavigator].
final NotifierProvider<OrdersNavigator, void> ordersNavigator =
    NotifierProvider<OrdersNavigator, void>(OrdersNavigator.new);

/// Navigation intents of the orders feature.
class OrdersNavigator extends FeatureNavigator {
  void goToList() => navigation.goNamed(OrdersRoutes.listName);

  void goToDetail(String orderId) => navigation.pushNamed(
    OrdersRoutes.detailName,
    pathParameters: <String, String>{OrdersRoutes.orderIdParam: orderId},
  );

  /// Cross-feature destination (cart feature, by path).
  void goToCart() => navigation.go('/cart');

  void back() => navigation.pop();
}

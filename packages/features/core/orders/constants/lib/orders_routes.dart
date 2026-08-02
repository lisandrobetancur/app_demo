/// Route table of the orders feature.
class OrdersRoutes {
  const OrdersRoutes._();

  static const String listPath = '/orders';
  static const String listName = 'Orders List';

  static const String detailPath = '/orders/detail/:orderId';
  static const String detailName = 'Orders Detail';

  /// Path parameter of the detail route.
  static const String orderIdParam = 'orderId';

  /// Builds the concrete detail location for deep links.
  static String detailLocation(String orderId) => '/orders/detail/$orderId';
}

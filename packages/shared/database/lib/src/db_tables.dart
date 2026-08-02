/// Canonical table names of the market schema.
///
/// The schema has a single owner (this package); features reference tables
/// through these constants so cross-feature SQL (checkout, cancellation)
/// never duplicates literals.
class DbTables {
  const DbTables._();

  static const String addresses = 'addresses';
  static const String cartItems = 'cart_items';
  static const String categories = 'categories';
  static const String coupons = 'coupons';
  static const String favorites = 'favorites';
  static const String notifications = 'notifications';
  static const String orderItems = 'order_items';
  static const String orders = 'orders';
  static const String products = 'products';
  static const String reviews = 'reviews';
  static const String searchHistory = 'search_history';
  static const String users = 'users';

  /// Deletion order that respects foreign keys (children before parents).
  static const List<String> deletionOrder = <String>[
    searchHistory,
    notifications,
    reviews,
    orderItems,
    orders,
    coupons,
    addresses,
    cartItems,
    favorites,
    products,
    categories,
    users,
  ];
}

part of com.demo.market.dashboard.core;

/// Riverpod handle for [DashboardNavigator].
final NotifierProvider<DashboardNavigator, void> dashboardNavigator =
    NotifierProvider<DashboardNavigator, void>(DashboardNavigator.new);

/// Navigation intents of the dashboard. Every destination belongs to another
/// feature, so navigation happens by route path only.
class DashboardNavigator extends FeatureNavigator {
  void goToCatalog() => navigation.go('/catalog');

  void goToCreateProduct() => navigation.go('/catalog/publish');

  void goToMyProducts() => navigation.go('/catalog/my-products');

  void goToFavorites() => navigation.go('/catalog/favorites');

  void goToCart() => navigation.go('/cart');

  void goToNotifications() => navigation.go('/notifications');

  void goToLogin() => navigation.go('/authentication/login');

  void goToProductDetail(String productId) =>
      navigation.go('/catalog/detail/$productId');
}

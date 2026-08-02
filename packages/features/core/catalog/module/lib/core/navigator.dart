part of com.demo.market.catalog.core;

/// Riverpod handle for [CatalogNavigator].
final NotifierProvider<CatalogNavigator, void> catalogNavigator =
    NotifierProvider<CatalogNavigator, void>(CatalogNavigator.new);

/// Navigation intents of the catalog feature.
class CatalogNavigator extends FeatureNavigator {
  void goToList() => navigation.goNamed(CatalogRoutes.listName);

  void goToDetail(String productId) => navigation.pushNamed(
    CatalogRoutes.detailName,
    pathParameters: <String, String>{CatalogRoutes.productIdParam: productId},
  );

  void goToCreate() => navigation.pushNamed(CatalogRoutes.createName);

  void goToEdit(String productId) => navigation.pushNamed(
    CatalogRoutes.editName,
    pathParameters: <String, String>{CatalogRoutes.productIdParam: productId},
  );

  void goToMyProducts() => navigation.pushNamed(CatalogRoutes.myProductsName);

  void goToFavorites() => navigation.pushNamed(CatalogRoutes.favoritesName);

  void goToReviewForm(String productId) => navigation.pushNamed(
    CatalogRoutes.reviewFormName,
    pathParameters: <String, String>{CatalogRoutes.productIdParam: productId},
  );

  /// Cross-feature destination (cart feature, by path).
  void goToCart() => navigation.go('/cart');

  void back() => navigation.pop();
}

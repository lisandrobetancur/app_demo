/// Route table of the catalog feature.
class CatalogRoutes {
  const CatalogRoutes._();

  static const String listPath = '/catalog';
  static const String listName = 'Catalog List';

  static const String detailPath = '/catalog/detail/:productId';
  static const String detailName = 'Catalog Product Detail';

  /// Path parameter shared by detail/edit/review routes.
  static const String productIdParam = 'productId';

  static const String createPath = '/catalog/publish';
  static const String createName = 'Catalog Product Create';

  static const String editPath = '/catalog/edit/:productId';
  static const String editName = 'Catalog Product Edit';

  static const String myProductsPath = '/catalog/my-products';
  static const String myProductsName = 'Catalog My Products';

  static const String favoritesPath = '/catalog/favorites';
  static const String favoritesName = 'Catalog Favorites';

  static const String reviewFormPath = '/catalog/review/:productId';
  static const String reviewFormName = 'Catalog Review Form';

  /// Builds the concrete detail location for deep links / sharing.
  static String detailLocation(String productId) =>
      '/catalog/detail/$productId';
}

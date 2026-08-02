/// Limits and fixed values of the catalog feature.
class CatalogLimits {
  const CatalogLimits._();

  /// Products fetched per page (infinite scroll).
  static const int pageSize = 20;

  /// Search suggestions shown from history.
  static const int searchSuggestions = 5;

  /// Product name length range.
  static const int nameMinLength = 3;
  static const int nameMaxLength = 60;

  /// Product description length range.
  static const int descriptionMinLength = 10;
  static const int descriptionMaxLength = 500;

  /// Review comment maximum length.
  static const int reviewCommentMaxLength = 300;

  /// Price slider bounds (COP).
  static const double priceRangeMax = 150000000;
}

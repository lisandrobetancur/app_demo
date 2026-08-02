/// Catalog sort options. Every option maps to a deterministic `ORDER BY`
/// (always with a stable tie-breaker on `id`).
enum ProductSort {
  recent,
  priceAsc,
  priceDesc,
  bestRated;

  bool get isRecent => this == ProductSort.recent;

  bool get isPriceAsc => this == ProductSort.priceAsc;

  bool get isPriceDesc => this == ProductSort.priceDesc;

  bool get isBestRated => this == ProductSort.bestRated;

  /// Translation key of the display label.
  String get labelKey => switch (this) {
    ProductSort.recent => 'catalog.sorts.recent',
    ProductSort.priceAsc => 'catalog.sorts.price_asc',
    ProductSort.priceDesc => 'catalog.sorts.price_desc',
    ProductSort.bestRated => 'catalog.sorts.best_rated',
  };
}

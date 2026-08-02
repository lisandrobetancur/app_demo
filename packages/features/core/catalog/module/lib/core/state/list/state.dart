part of com.demo.market.catalog.core.state.list;

/// Immutable state of the catalog list (F07).
class ListState {
  const ListState({
    this.products = const <Product>[],
    this.categories = const <Category>[],
    this.filters = const ProductFilters(),
    this.suggestions = const <String>[],
    this.favoriteIds = const <String>{},
    this.status = ViewStatus.loading,
    this.resultsCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<Product> products;
  final List<Category> categories;
  final ProductFilters filters;

  /// Last search terms offered as suggestions under the search input.
  final List<String> suggestions;

  final Set<String> favoriteIds;
  final ViewStatus status;
  final int resultsCount;
  final bool hasMore;
  final bool isLoadingMore;

  ListState copyWith({
    List<Product>? products,
    List<Category>? categories,
    ProductFilters? filters,
    List<String>? suggestions,
    Set<String>? favoriteIds,
    ViewStatus? status,
    int? resultsCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) => ListState(
    products: products ?? this.products,
    categories: categories ?? this.categories,
    filters: filters ?? this.filters,
    suggestions: suggestions ?? this.suggestions,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    status: status ?? this.status,
    resultsCount: resultsCount ?? this.resultsCount,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  bool operator ==(Object other) =>
      other is ListState &&
      other.status == status &&
      other.filters == filters &&
      other.resultsCount == resultsCount &&
      other.hasMore == hasMore &&
      other.isLoadingMore == isLoadingMore &&
      _iterableEquals(other.products, products) &&
      _iterableEquals(other.categories, categories) &&
      _iterableEquals(other.suggestions, suggestions) &&
      other.favoriteIds.length == favoriteIds.length &&
      other.favoriteIds.containsAll(favoriteIds);

  @override
  int get hashCode => Object.hash(
    status,
    filters,
    resultsCount,
    hasMore,
    isLoadingMore,
    Object.hashAll(products),
    Object.hashAll(categories),
    Object.hashAll(suggestions),
    Object.hashAllUnordered(favoriteIds),
  );

  @override
  String toString() =>
      'ListState: products:${products.length}/$resultsCount '
      '${status.name} filters:${filters.activeCount}';

  static bool _iterableEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

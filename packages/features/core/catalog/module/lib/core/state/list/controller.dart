part of com.demo.market.catalog.core.state.list;

/// Controller of the catalog list: search with debounce, filters, sorting
/// and 20-by-20 infinite scroll.
class ListViewModel extends ViewModel<ListState> {
  ListViewModel({ListState? state}) : super(state ?? const ListState());

  @override
  void postInit() {
    service = ref.read(catalogServiceProvider);
    navigatorNotifier = ref.read(catalogNavigator.notifier);
    runPostBuild(_initialize);
  }

  late ICatalogService service;
  late CatalogNavigator navigatorNotifier;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
  }

  String? get _userId => ref.read(authSessionProvider)?.id;

  Future<void> _initialize() async {
    final Object? key = mountedKey;
    try {
      final List<Category> categories = await service.getCategories();
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(categories: categories);
    } on Object catch (error, stackTrace) {
      log.error('catalog.list.categories', error, stackTrace);
    }
    await Future.wait(<Future<void>>[loadProducts(), refreshSuggestions()]);
  }

  /// Full reload with the current filters (also used by pull-to-refresh).
  Future<void> loadProducts() async {
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final List<Product> products = await service.getProducts(
        filters: state.filters,
        limit: CatalogLimits.pageSize,
        offset: 0,
      );
      final int total = await service.countProducts(filters: state.filters);
      final Set<String> favorites = _userId == null
          ? const <String>{}
          : await service.favoriteIds(_userId!);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        products: products,
        favoriteIds: favorites,
        resultsCount: total,
        hasMore: products.length < total,
        status: products.isEmpty ? ViewStatus.empty : ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.list.loadProducts', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  /// Next page for the infinite scroll.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || !state.status.isData) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    final Object? key = mountedKey;
    try {
      final List<Product> page = await service.getProducts(
        filters: state.filters,
        limit: CatalogLimits.pageSize,
        offset: state.products.length,
      );
      if (key != mountedKey) {
        return;
      }
      final List<Product> merged = <Product>[...state.products, ...page];
      state = state.copyWith(
        products: merged,
        isLoadingMore: false,
        hasMore: merged.length < state.resultsCount && page.isNotEmpty,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.list.loadMore', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Debounced (300 ms) search; records the term for suggestions.
  void setSearchTerm(String term) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.debounce, () => _applySearch(term));
  }

  Future<void> _applySearch(String term) async {
    state = state.copyWith(filters: state.filters.copyWith(query: term));
    if (term.trim().isNotEmpty && _userId != null) {
      await service.recordSearch(userId: _userId!, term: term);
      await refreshSuggestions();
    }
    await loadProducts();
  }

  /// Applies a suggestion immediately (no debounce).
  Future<void> applySuggestion(String term) async {
    _debounce?.cancel();
    await _applySearch(term);
  }

  Future<void> refreshSuggestions() async {
    if (_userId == null) {
      return;
    }
    final Object? key = mountedKey;
    final List<String> suggestions = await service.recentSearches(
      userId: _userId!,
      limit: CatalogLimits.searchSuggestions,
    );
    if (key != mountedKey) {
      return;
    }
    state = state.copyWith(suggestions: suggestions);
  }

  Future<void> applyFilters(ProductFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadProducts();
  }

  Future<void> setSort(ProductSort sort) =>
      applyFilters(state.filters.copyWith(sort: sort));

  Future<void> toggleCategory(String categoryId) async {
    final Set<String> next = <String>{...state.filters.categoryIds};
    if (!next.remove(categoryId)) {
      next.add(categoryId);
    }
    await applyFilters(state.filters.copyWith(categoryIds: next));
  }

  Future<void> toggleCondition(ProductCondition condition) async {
    final Set<ProductCondition> next = <ProductCondition>{
      ...state.filters.conditions,
    };
    if (!next.remove(condition)) {
      next.add(condition);
    }
    await applyFilters(state.filters.copyWith(conditions: next));
  }

  Future<void> setPriceRange(double? min, double? max) async {
    if (min == null && max == null) {
      await applyFilters(state.filters.copyWith(clearPriceRange: true));
      return;
    }
    await applyFilters(state.filters.copyWith(minPrice: min, maxPrice: max));
  }

  Future<void> setOnlyInStock(bool value) =>
      applyFilters(state.filters.copyWith(onlyInStock: value));

  Future<void> clearFilters() => applyFilters(state.filters.cleared());

  Future<void> toggleFavorite(String productId) async {
    if (_userId == null) {
      return;
    }
    final bool added = await service.toggleFavorite(
      userId: _userId!,
      productId: productId,
    );
    final Set<String> next = <String>{...state.favoriteIds};
    if (added) {
      next.add(productId);
    } else {
      next.remove(productId);
    }
    state = state.copyWith(favoriteIds: next);
  }

  void openDetail(String productId) => navigatorNotifier.goToDetail(productId);
}

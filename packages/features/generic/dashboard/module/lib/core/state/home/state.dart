part of com.demo.market.dashboard.core.state.home;

/// Immutable state of the dashboard (F06).
class HomeState {
  const HomeState({
    this.summary = const DashboardSummary.zero(),
    this.categories = const <Category>[],
    this.recentProducts = const <Product>[],
    this.status = ViewStatus.loading,
  });

  final DashboardSummary summary;
  final List<Category> categories;
  final List<Product> recentProducts;
  final ViewStatus status;

  HomeState copyWith({
    DashboardSummary? summary,
    List<Category>? categories,
    List<Product>? recentProducts,
    ViewStatus? status,
  }) => HomeState(
    summary: summary ?? this.summary,
    categories: categories ?? this.categories,
    recentProducts: recentProducts ?? this.recentProducts,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is HomeState &&
      other.summary == summary &&
      other.status == status &&
      other.categories.length == categories.length &&
      other.recentProducts.length == recentProducts.length &&
      _sameList(other.categories, categories) &&
      _sameList(other.recentProducts, recentProducts);

  @override
  int get hashCode => Object.hash(
    summary,
    status,
    Object.hashAll(categories),
    Object.hashAll(recentProducts),
  );

  @override
  String toString() =>
      'HomeState: ${status.name} recents:${recentProducts.length}';

  static bool _sameList(List<Object?> a, List<Object?> b) {
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

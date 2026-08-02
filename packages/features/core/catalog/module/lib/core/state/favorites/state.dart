part of com.demo.market.catalog.core.state.favorites;

/// Immutable state of the favorites screen (F14).
class FavoritesState {
  const FavoritesState({
    this.products = const <Product>[],
    this.status = ViewStatus.loading,
    this.isMovingAll = false,
    this.lastEventKey,
    this.lastEventArg = '',
  });

  final List<Product> products;
  final ViewStatus status;
  final bool isMovingAll;

  /// One-shot translation key consumed by the view as a snackbar.
  final String? lastEventKey;

  /// Optional argument of the snackbar message (e.g. moved count).
  final String lastEventArg;

  /// Favorites that can go straight to the cart.
  List<Product> get available => products
      .where(
        (Product product) => product.status.isActive && !product.isOutOfStock,
      )
      .toList();

  FavoritesState copyWith({
    List<Product>? products,
    ViewStatus? status,
    bool? isMovingAll,
    String? lastEventKey,
    String? lastEventArg,
    bool clearEvent = false,
  }) => FavoritesState(
    products: products ?? this.products,
    status: status ?? this.status,
    isMovingAll: isMovingAll ?? this.isMovingAll,
    lastEventKey: clearEvent ? null : lastEventKey ?? this.lastEventKey,
    lastEventArg: clearEvent ? '' : lastEventArg ?? this.lastEventArg,
  );

  @override
  bool operator ==(Object other) =>
      other is FavoritesState &&
      other.status == status &&
      other.isMovingAll == isMovingAll &&
      other.lastEventKey == lastEventKey &&
      other.lastEventArg == lastEventArg &&
      other.products.length == products.length &&
      _sameProducts(other.products, products);

  @override
  int get hashCode => Object.hash(
    status,
    isMovingAll,
    lastEventKey,
    lastEventArg,
    Object.hashAll(products),
  );

  @override
  String toString() =>
      'FavoritesState: ${products.length} items ${status.name}';

  static bool _sameProducts(List<Product> a, List<Product> b) {
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

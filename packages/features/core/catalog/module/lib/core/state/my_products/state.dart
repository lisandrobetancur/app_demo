part of com.demo.market.catalog.core.state.my_products;

/// Immutable state of the my-publications list (F10).
class MyProductsState {
  const MyProductsState({
    this.products = const <Product>[],
    this.status = ViewStatus.loading,
    this.busyProductId,
  });

  final List<Product> products;
  final ViewStatus status;

  /// Product with an in-flight action (status toggle, delete, stock).
  final String? busyProductId;

  MyProductsState copyWith({
    List<Product>? products,
    ViewStatus? status,
    String? busyProductId,
    bool clearBusy = false,
  }) => MyProductsState(
    products: products ?? this.products,
    status: status ?? this.status,
    busyProductId: clearBusy ? null : busyProductId ?? this.busyProductId,
  );

  @override
  bool operator ==(Object other) =>
      other is MyProductsState &&
      other.status == status &&
      other.busyProductId == busyProductId &&
      other.products.length == products.length &&
      _sameProducts(other.products, products);

  @override
  int get hashCode =>
      Object.hash(status, busyProductId, Object.hashAll(products));

  @override
  String toString() =>
      'MyProductsState: ${products.length} items ${status.name}';

  static bool _sameProducts(List<Product> a, List<Product> b) {
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

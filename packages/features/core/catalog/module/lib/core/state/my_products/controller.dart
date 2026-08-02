part of com.demo.market.catalog.core.state.my_products;

/// Controller of the my-publications list.
class MyProductsViewModel extends ViewModel<MyProductsState> {
  MyProductsViewModel({MyProductsState? state})
    : super(state ?? const MyProductsState());

  @override
  void postInit() {
    service = ref.read(catalogServiceProvider);
    navigatorNotifier = ref.read(catalogNavigator.notifier);
    runPostBuild(load);
  }

  late ICatalogService service;
  late CatalogNavigator navigatorNotifier;

  Future<void> load() async {
    final String? ownerId = ref.read(authSessionProvider)?.id;
    if (ownerId == null) {
      state = state.copyWith(status: ViewStatus.empty);
      return;
    }
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final List<Product> products = await service.myProducts(ownerId);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        products: products,
        status: products.isEmpty ? ViewStatus.empty : ViewStatus.data,
        clearBusy: true,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.myProducts.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  /// Pause ↔ reactivate.
  Future<void> toggleStatus(Product product) => _mutate(product.id, () {
    final ProductStatus next = product.status.isPaused
        ? ProductStatus.active
        : ProductStatus.paused;
    return service.setProductStatus(productId: product.id, status: next);
  });

  /// Logical deletion: gone from the catalog, kept in order history.
  Future<void> deleteProduct(Product product) => _mutate(
    product.id,
    () => service.setProductStatus(
      productId: product.id,
      status: ProductStatus.deleted,
    ),
  );

  /// Quick stock adjustment from the list.
  Future<void> adjustStock(Product product, int stock) => _mutate(
    product.id,
    () => service.updateStock(productId: product.id, stock: stock),
  );

  void goToCreate() => navigatorNotifier.goToCreate();

  void goToEdit(String productId) => navigatorNotifier.goToEdit(productId);

  Future<void> _mutate(String productId, Future<void> Function() action) async {
    state = state.copyWith(busyProductId: productId);
    final Object? key = mountedKey;
    try {
      await action();
      ref.invalidate(listViewModelProvider);
      if (key != mountedKey) {
        return;
      }
      await load();
    } on Object catch (error, stackTrace) {
      log.error('catalog.myProducts.mutate', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(clearBusy: true);
    }
  }
}

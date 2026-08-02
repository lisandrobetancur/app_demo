part of com.demo.market.catalog.core.state.favorites;

/// Controller of the favorites screen.
class FavoritesViewModel extends ViewModel<FavoritesState> {
  FavoritesViewModel({FavoritesState? state})
    : super(state ?? const FavoritesState());

  @override
  void postInit() {
    service = ref.read(catalogServiceProvider);
    navigatorNotifier = ref.read(catalogNavigator.notifier);
    runPostBuild(load);
  }

  late ICatalogService service;
  late CatalogNavigator navigatorNotifier;

  String? get _userId => ref.read(authSessionProvider)?.id;

  Future<void> load() async {
    if (_userId == null) {
      state = state.copyWith(status: ViewStatus.empty);
      return;
    }
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final List<Product> products = await service.favoriteProducts(_userId!);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        products: products,
        status: products.isEmpty ? ViewStatus.empty : ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.favorites.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  /// Un-favorite from the list (immediate feedback).
  Future<void> removeFavorite(Product product) async {
    if (_userId == null) {
      return;
    }
    await service.toggleFavorite(userId: _userId!, productId: product.id);
    await load();
  }

  /// Adds one favorite to the cart and removes it from favorites.
  Future<void> moveToCart(Product product) async {
    if (_userId == null || product.isOutOfStock || !product.status.isActive) {
      return;
    }
    final Object? key = mountedKey;
    try {
      await ref
          .read(cartServiceProvider)
          .addToCart(userId: _userId!, productId: product.id);
      await service.toggleFavorite(userId: _userId!, productId: product.id);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(lastEventKey: 'catalog.favorites.moved_one');
      await load();
    } on Object catch (error, stackTrace) {
      log.error('catalog.favorites.moveToCart', error, stackTrace);
    }
  }

  /// Adds every available favorite to the cart.
  Future<void> moveAllToCart() async {
    final List<Product> available = state.available;
    if (_userId == null || available.isEmpty) {
      return;
    }
    state = state.copyWith(isMovingAll: true);
    final Object? key = mountedKey;
    try {
      for (final Product product in available) {
        await ref
            .read(cartServiceProvider)
            .addToCart(userId: _userId!, productId: product.id);
        await service.toggleFavorite(userId: _userId!, productId: product.id);
      }
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isMovingAll: false,
        lastEventKey: 'catalog.favorites.moved_many',
        lastEventArg: '${available.length}',
      );
      await load();
    } on Object catch (error, stackTrace) {
      log.error('catalog.favorites.moveAllToCart', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isMovingAll: false);
    }
  }

  void consumeEvent() => state = state.copyWith(clearEvent: true);

  void openDetail(String productId) => navigatorNotifier.goToDetail(productId);
}

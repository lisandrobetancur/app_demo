part of com.demo.market.catalog.core.state.detail;

/// Controller of the product detail.
class DetailViewModel extends ViewModel<DetailState> {
  DetailViewModel({DetailState? state}) : super(state ?? const DetailState());

  @override
  void postInit() {
    service = ref.read(catalogServiceProvider);
    navigatorNotifier = ref.read(catalogNavigator.notifier);
  }

  late ICatalogService service;
  late CatalogNavigator navigatorNotifier;

  String? get _userId => ref.read(authSessionProvider)?.id;

  /// Loads (or reloads) the product identified by [productId]. An unknown id
  /// resolves to the empty (not found) state — deep links never blank-screen.
  Future<void> load(String productId) async {
    state = const DetailState();
    final Object? key = mountedKey;
    try {
      final Product? product = await service.getProduct(productId);
      if (product == null || product.status.isDeleted) {
        if (key != mountedKey) {
          return;
        }
        state = state.copyWith(status: ViewStatus.empty);
        return;
      }
      final List<Review> reviews = await service.reviewsFor(productId);
      bool favorite = false;
      bool reviewable = false;
      Review? ownReview;
      if (_userId != null) {
        favorite = (await service.favoriteIds(_userId!)).contains(productId);
        reviewable = await service.canReview(
          userId: _userId!,
          productId: productId,
        );
        ownReview = await service.myReview(
          userId: _userId!,
          productId: productId,
        );
      }
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        product: product,
        reviews: reviews,
        isFavorite: favorite,
        canReview: reviewable,
        myReview: ownReview,
        clearMyReview: ownReview == null,
        status: ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.detail.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  void setQuantity(int quantity) => state = state.copyWith(quantity: quantity);

  Future<void> addToCart() async {
    final Product? product = state.product;
    if (product == null || _userId == null || product.isOutOfStock) {
      return;
    }
    state = state.copyWith(isAddingToCart: true, clearEvent: true);
    final Object? key = mountedKey;
    try {
      await ref
          .read(cartServiceProvider)
          .addToCart(
            userId: _userId!,
            productId: product.id,
            quantity: state.quantity,
          );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isAddingToCart: false,
        lastEventKey: 'catalog.detail.added_to_cart',
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.detail.addToCart', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isAddingToCart: false,
        lastEventKey: 'catalog.detail.add_to_cart_error',
      );
    }
  }

  Future<void> toggleFavorite() async {
    final Product? product = state.product;
    if (product == null || _userId == null) {
      return;
    }
    final bool added = await service.toggleFavorite(
      userId: _userId!,
      productId: product.id,
    );
    state = state.copyWith(isFavorite: added);
  }

  /// Builds the `market://` deep link of this product for the share action.
  String shareLink() {
    final Product? product = state.product;
    if (product == null) {
      return '';
    }
    return DeepLinks.toDeepLink(CatalogRoutes.detailLocation(product.id));
  }

  void markShared() =>
      state = state.copyWith(lastEventKey: 'catalog.detail.link_copied');

  void consumeEvent() => state = state.copyWith(clearEvent: true);

  void goToEdit() {
    final Product? product = state.product;
    if (product != null) {
      navigatorNotifier.goToEdit(product.id);
    }
  }

  void goToReviewForm() {
    final Product? product = state.product;
    if (product != null) {
      navigatorNotifier.goToReviewForm(product.id);
    }
  }
}

part of com.demo.market.catalog.core.state.review_form;

/// Controller of the review form.
class ReviewFormViewModel extends ViewModel<ReviewFormState> {
  ReviewFormViewModel({ReviewFormState? state})
    : super(state ?? const ReviewFormState());

  @override
  void postInit() {
    service = ref.read(catalogServiceProvider);
    navigatorNotifier = ref.read(catalogNavigator.notifier);
  }

  late ICatalogService service;
  late CatalogNavigator navigatorNotifier;

  String? get _userId => ref.read(authSessionProvider)?.id;

  Future<void> start(String productId) async {
    state = const ReviewFormState();
    final Object? key = mountedKey;
    try {
      final Product? product = await service.getProduct(productId);
      if (product == null || _userId == null) {
        if (key != mountedKey) {
          return;
        }
        state = state.copyWith(status: ViewStatus.empty);
        return;
      }
      final bool allowed = await service.canReview(
        userId: _userId!,
        productId: productId,
      );
      final Review? mine = await service.myReview(
        userId: _userId!,
        productId: productId,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        productId: productId,
        productName: product.name,
        canReview: allowed,
        isEditing: mine != null,
        rating: mine?.rating ?? 0,
        comment: mine?.comment ?? '',
        status: allowed ? ViewStatus.data : ViewStatus.empty,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.reviewForm.start', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  void setRating(int rating) =>
      state = state.copyWith(rating: rating, clearError: true);

  void setComment(String comment) =>
      state = state.copyWith(comment: comment, clearError: true);

  Future<void> submit() async {
    if (!state.canSubmit || _userId == null) {
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.upsertReview(
        userId: _userId!,
        productId: state.productId,
        rating: state.rating,
        comment: state.comment,
      );
      // The detail aggregates (average, count, own review) must refresh.
      ref.invalidate(detailViewModelProvider);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isSubmitting: false);
      navigatorNotifier.back();
    } on Object catch (error, stackTrace) {
      log.error('catalog.reviewForm.submit', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorKey: 'catalog.review_form.save_error',
      );
    }
  }
}

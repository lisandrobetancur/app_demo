part of com.demo.market.catalog.core.state.detail;

/// Immutable state of the product detail (F08).
class DetailState {
  const DetailState({
    this.product,
    this.reviews = const <Review>[],
    this.quantity = 1,
    this.isFavorite = false,
    this.canReview = false,
    this.myReview,
    this.status = ViewStatus.loading,
    this.isAddingToCart = false,
    this.lastEventKey,
  });

  final Product? product;
  final List<Review> reviews;
  final int quantity;
  final bool isFavorite;

  /// True when the viewer received this product in a DELIVERED order.
  final bool canReview;

  final Review? myReview;
  final ViewStatus status;
  final bool isAddingToCart;

  /// One-shot translation key consumed by the view as a snackbar
  /// (added-to-cart, link-copied).
  final String? lastEventKey;

  /// The viewer owns this publication (sell-side actions instead of CTA).
  bool isOwnedBy(String? userId) =>
      product != null && userId != null && product!.ownerId == userId;

  DetailState copyWith({
    Product? product,
    List<Review>? reviews,
    int? quantity,
    bool? isFavorite,
    bool? canReview,
    Review? myReview,
    ViewStatus? status,
    bool? isAddingToCart,
    String? lastEventKey,
    bool clearEvent = false,
    bool clearMyReview = false,
  }) => DetailState(
    product: product ?? this.product,
    reviews: reviews ?? this.reviews,
    quantity: quantity ?? this.quantity,
    isFavorite: isFavorite ?? this.isFavorite,
    canReview: canReview ?? this.canReview,
    myReview: clearMyReview ? null : myReview ?? this.myReview,
    status: status ?? this.status,
    isAddingToCart: isAddingToCart ?? this.isAddingToCart,
    lastEventKey: clearEvent ? null : lastEventKey ?? this.lastEventKey,
  );

  @override
  bool operator ==(Object other) =>
      other is DetailState &&
      other.product == product &&
      other.quantity == quantity &&
      other.isFavorite == isFavorite &&
      other.canReview == canReview &&
      other.myReview == myReview &&
      other.status == status &&
      other.isAddingToCart == isAddingToCart &&
      other.lastEventKey == lastEventKey &&
      other.reviews.length == reviews.length;

  @override
  int get hashCode => Object.hash(
    product,
    quantity,
    isFavorite,
    canReview,
    myReview,
    status,
    isAddingToCart,
    lastEventKey,
    reviews.length,
  );

  @override
  String toString() =>
      'DetailState: ${product?.id} qty:$quantity ${status.name}';
}

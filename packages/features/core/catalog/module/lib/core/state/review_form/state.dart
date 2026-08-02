part of com.demo.market.catalog.core.state.review_form;

/// Immutable state of the review form (F15).
class ReviewFormState {
  const ReviewFormState({
    this.productId = '',
    this.productName = '',
    this.rating = 0,
    this.comment = '',
    this.canReview = false,
    this.isEditing = false,
    this.status = ViewStatus.loading,
    this.isSubmitting = false,
    this.errorKey,
  });

  final String productId;
  final String productName;
  final int rating;
  final String comment;

  /// Gate: only buyers with a DELIVERED order may review, once.
  final bool canReview;

  /// True when editing an existing own review.
  final bool isEditing;

  final ViewStatus status;
  final bool isSubmitting;
  final String? errorKey;

  bool get canSubmit => !isSubmitting && canReview && rating >= 1;

  ReviewFormState copyWith({
    String? productId,
    String? productName,
    int? rating,
    String? comment,
    bool? canReview,
    bool? isEditing,
    ViewStatus? status,
    bool? isSubmitting,
    String? errorKey,
    bool clearError = false,
  }) => ReviewFormState(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    canReview: canReview ?? this.canReview,
    isEditing: isEditing ?? this.isEditing,
    status: status ?? this.status,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is ReviewFormState &&
      other.productId == productId &&
      other.productName == productName &&
      other.rating == rating &&
      other.comment == comment &&
      other.canReview == canReview &&
      other.isEditing == isEditing &&
      other.status == status &&
      other.isSubmitting == isSubmitting &&
      other.errorKey == errorKey;

  @override
  int get hashCode => Object.hash(
    productId,
    productName,
    rating,
    comment,
    canReview,
    isEditing,
    status,
    isSubmitting,
    errorKey,
  );

  @override
  String toString() =>
      'ReviewFormState: $productId rating:$rating ${status.name}';
}

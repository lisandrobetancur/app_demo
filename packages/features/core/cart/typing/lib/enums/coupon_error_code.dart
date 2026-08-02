/// Differentiated coupon validation failures.
enum CouponErrorCode {
  notFound,
  expired,
  inactive,
  minAmountNotReached;

  bool get isNotFound => this == CouponErrorCode.notFound;

  bool get isExpired => this == CouponErrorCode.expired;

  bool get isInactive => this == CouponErrorCode.inactive;

  bool get isMinAmountNotReached => this == CouponErrorCode.minAmountNotReached;

  /// Translation key of the inline error.
  String get messageKey => switch (this) {
    CouponErrorCode.notFound => 'cart.coupon_errors.not_found',
    CouponErrorCode.expired => 'cart.coupon_errors.expired',
    CouponErrorCode.inactive => 'cart.coupon_errors.inactive',
    CouponErrorCode.minAmountNotReached =>
      'cart.coupon_errors.min_amount_not_reached',
  };
}

/// Exception carrying a [CouponErrorCode].
class CouponException implements Exception {
  const CouponException(this.code);

  final CouponErrorCode code;

  @override
  String toString() => 'CouponException: ${code.name}';
}

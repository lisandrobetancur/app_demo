part of com.demo.market.cart.core.state.cart;

/// Immutable state of the cart (F11).
class CartState {
  const CartState({
    this.lines = const <CartLine>[],
    this.status = ViewStatus.loading,
    this.appliedCoupon,
    this.couponInput = '',
    this.couponErrorKey,
    this.isApplyingCoupon = false,
    this.removedLine,
  });

  final List<CartLine> lines;
  final ViewStatus status;
  final Coupon? appliedCoupon;
  final String couponInput;
  final String? couponErrorKey;
  final bool isApplyingCoupon;

  /// Last removed line, kept for the undo snackbar window.
  final CartLine? removedLine;

  /// Reactive totals (subtotal, discount, 19% VAT, total).
  CartTotals get totals => CartTotals.compute(
    lines: lines,
    taxRate: CartLimits.taxRate,
    coupon: appliedCoupon,
  );

  /// A line went out of stock or its product is gone: checkout is blocked.
  bool get hasBlockingLines => lines.any((CartLine line) => line.isUnavailable);

  bool get canCheckout =>
      status.isData && lines.isNotEmpty && !hasBlockingLines;

  CartState copyWith({
    List<CartLine>? lines,
    ViewStatus? status,
    Coupon? appliedCoupon,
    String? couponInput,
    String? couponErrorKey,
    bool? isApplyingCoupon,
    CartLine? removedLine,
    bool clearCoupon = false,
    bool clearCouponError = false,
    bool clearRemovedLine = false,
  }) => CartState(
    lines: lines ?? this.lines,
    status: status ?? this.status,
    appliedCoupon: clearCoupon ? null : appliedCoupon ?? this.appliedCoupon,
    couponInput: couponInput ?? this.couponInput,
    couponErrorKey: clearCouponError
        ? null
        : couponErrorKey ?? this.couponErrorKey,
    isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
    removedLine: clearRemovedLine ? null : removedLine ?? this.removedLine,
  );

  @override
  bool operator ==(Object other) =>
      other is CartState &&
      other.status == status &&
      other.appliedCoupon == appliedCoupon &&
      other.couponInput == couponInput &&
      other.couponErrorKey == couponErrorKey &&
      other.isApplyingCoupon == isApplyingCoupon &&
      other.removedLine == removedLine &&
      _sameLines(other.lines, lines);

  @override
  int get hashCode => Object.hash(
    status,
    appliedCoupon,
    couponInput,
    couponErrorKey,
    isApplyingCoupon,
    removedLine,
    Object.hashAll(lines),
  );

  @override
  String toString() =>
      'CartState: ${lines.length} lines ${status.name} '
      'coupon:${appliedCoupon?.code}';

  static bool _sameLines(List<CartLine> a, List<CartLine> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

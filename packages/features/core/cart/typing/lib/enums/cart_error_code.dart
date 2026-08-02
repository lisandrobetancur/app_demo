/// Cart/checkout failures.
enum CartErrorCode {
  /// A line exceeds the available stock at confirmation time.
  outOfStock,

  /// Checkout attempted with an empty cart.
  emptyCart;

  bool get isOutOfStock => this == CartErrorCode.outOfStock;

  bool get isEmptyCart => this == CartErrorCode.emptyCart;

  /// Translation key of the error message.
  String get messageKey => switch (this) {
    CartErrorCode.outOfStock => 'cart.errors.out_of_stock',
    CartErrorCode.emptyCart => 'cart.errors.empty_cart',
  };
}

/// Exception carrying a [CartErrorCode].
class CartException implements Exception {
  const CartException(this.code);

  final CartErrorCode code;

  @override
  String toString() => 'CartException: ${code.name}';
}

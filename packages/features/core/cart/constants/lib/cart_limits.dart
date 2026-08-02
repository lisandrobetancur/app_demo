/// Limits and fixed business values of the cart feature.
class CartLimits {
  const CartLimits._();

  /// VAT applied on the discounted subtotal.
  static const double taxRate = 0.19;

  /// Checkout steps: delivery, payment, summary.
  static const int checkoutSteps = 3;
}

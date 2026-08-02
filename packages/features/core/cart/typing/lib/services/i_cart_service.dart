import '../enums/payment_method.dart';
import '../models/cart_line.dart';
import '../models/coupon.dart';

/// Cart contract: lines, coupons and the transactional checkout.
abstract interface class ICartService {
  /// Cart lines of [userId] with current product data, oldest added first.
  Future<List<CartLine>> linesFor(String userId);

  /// Adds [quantity] of a product (merging with an existing line, capped by
  /// stock). Used by catalog, favorites and re-order flows.
  Future<void> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  });

  /// Sets the quantity of a line (must stay within 1..stock).
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  });

  /// Removes a line. The UI offers undo via [addToCart].
  Future<void> removeLine(String cartItemId);

  /// Empties the cart of [userId].
  Future<void> clear(String userId);

  /// Validates a coupon against the current [subtotal]. Throws
  /// `CouponException` with a differentiated code on failure.
  Future<Coupon> validateCoupon({
    required String code,
    required double subtotal,
  });

  /// Confirms the purchase in **one transaction**: creates the order and its
  /// item snapshots, decrements stock, empties the cart and writes the
  /// notification. Returns the new order id. Throws `CartException` when
  /// the cart is empty or a line exceeds stock (nothing is written then).
  Future<String> checkout({
    required String userId,
    required PaymentMethod paymentMethod,
    String? addressId,
    String? couponCode,
  });

  /// Recomputes the shared badge providers (count and total) for [userId].
  Future<void> refreshBadge(String userId);
}

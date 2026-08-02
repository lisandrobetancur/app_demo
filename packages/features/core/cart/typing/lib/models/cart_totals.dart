import 'package:equatable/equatable.dart';

import 'cart_line.dart';
import 'coupon.dart';

/// Reactive cart totals: subtotal − discount, then VAT on the result.
class CartTotals extends Equatable {
  const CartTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  /// Computes totals from the lines, an optional [coupon] and the [taxRate].
  factory CartTotals.compute({
    required List<CartLine> lines,
    required double taxRate,
    Coupon? coupon,
  }) {
    double subtotal = 0;
    for (final CartLine line in lines) {
      subtotal += line.lineTotal;
    }
    final double discount = coupon?.discountFor(subtotal) ?? 0;
    final double taxable = subtotal - discount;
    final double tax = taxable * taxRate;
    return CartTotals(
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: taxable + tax,
    );
  }

  const CartTotals.zero() : subtotal = 0, discount = 0, tax = 0, total = 0;

  final double subtotal;
  final double discount;
  final double tax;
  final double total;

  @override
  List<Object?> get props => <Object?>[subtotal, discount, tax, total];
}

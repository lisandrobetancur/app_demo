import 'package:equatable/equatable.dart';

/// A row of the `coupons` table.
class Coupon extends Equatable {
  const Coupon({
    required this.code,
    required this.discountPct,
    required this.minAmount,
    required this.validUntil,
    required this.isActive,
  });

  factory Coupon.fromMap(Map<String, Object?> map) => Coupon(
    code: map['code']! as String,
    discountPct: (map['discount_pct']! as num).toDouble(),
    minAmount: (map['min_amount']! as num).toDouble(),
    validUntil: DateTime.fromMillisecondsSinceEpoch(map['valid_until']! as int),
    isActive: (map['is_active']! as int) == 1,
  );

  final String code;
  final double discountPct;
  final double minAmount;
  final DateTime validUntil;
  final bool isActive;

  /// Discount amount for the given [subtotal].
  double discountFor(double subtotal) => subtotal * discountPct / 100;

  @override
  List<Object?> get props => <Object?>[
    code,
    discountPct,
    minAmount,
    validUntil,
    isActive,
  ];
}

import 'package:equatable/equatable.dart';

import '../enums/order_status.dart';
import 'order_item.dart';

/// A row of `orders` plus its items and the address label for display.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.userId,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethodDbValue,
    required this.status,
    required this.createdAt,
    this.addressId,
    this.addressLabel = '',
    this.couponCode,
    this.items = const <OrderItem>[],
  });

  factory Order.fromMap(
    Map<String, Object?> map, {
    List<OrderItem> items = const <OrderItem>[],
  }) => Order(
    id: map['id']! as String,
    userId: map['user_id']! as String,
    subtotal: (map['subtotal']! as num).toDouble(),
    discount: (map['discount']! as num).toDouble(),
    tax: (map['tax']! as num).toDouble(),
    total: (map['total']! as num).toDouble(),
    paymentMethodDbValue: map['payment_method']! as String,
    status: OrderStatus.parse(map['status']! as String),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    addressId: map['address_id'] as String?,
    addressLabel: (map['address_label'] as String?) ?? '',
    couponCode: map['coupon_code'] as String?,
    items: items,
  );

  final String id;
  final String userId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethodDbValue;
  final OrderStatus status;
  final DateTime createdAt;
  final String? addressId;
  final String addressLabel;
  final String? couponCode;
  final List<OrderItem> items;

  /// Short human-facing order number derived from the id.
  String get number =>
      id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();

  Order copyWith({OrderStatus? status, List<OrderItem>? items}) => Order(
    id: id,
    userId: userId,
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: total,
    paymentMethodDbValue: paymentMethodDbValue,
    status: status ?? this.status,
    createdAt: createdAt,
    addressId: addressId,
    addressLabel: addressLabel,
    couponCode: couponCode,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    subtotal,
    discount,
    tax,
    total,
    paymentMethodDbValue,
    status,
    createdAt,
    addressId,
    addressLabel,
    couponCode,
    items,
  ];
}

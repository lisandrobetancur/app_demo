import 'package:equatable/equatable.dart';

/// A row of `order_items`: an immutable snapshot of name and unit price at
/// purchase time.
class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
    id: map['id']! as String,
    orderId: map['order_id']! as String,
    productId: map['product_id']! as String,
    name: map['name']! as String,
    unitPrice: (map['unit_price']! as num).toDouble(),
    quantity: map['quantity']! as int,
  );

  final String id;
  final String orderId;
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'name': name,
    'unit_price': unitPrice,
    'quantity': quantity,
  };

  @override
  List<Object?> get props => <Object?>[
    id,
    orderId,
    productId,
    name,
    unitPrice,
    quantity,
  ];
}

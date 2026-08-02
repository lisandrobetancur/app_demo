import 'package:catalog_typing/catalog_typing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One cart row joined with its product.
///
/// The product data reflects the *current* catalog (price, stock, status),
/// so the UI can flag lines that went out of stock or were removed by their
/// owner before checkout.
class CartLine extends Equatable {
  const CartLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.stock,
    required this.quantity,
    required this.productStatus,
    required this.addedAt,
    this.categoryCode = '',
    this.imageBytes,
  });

  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int stock;
  final int quantity;
  final ProductStatus productStatus;
  final DateTime addedAt;
  final String categoryCode;
  final Uint8List? imageBytes;

  double get lineTotal => unitPrice * quantity;

  /// The line blocks checkout: product gone or not enough stock.
  bool get isUnavailable => !productStatus.isActive || stock < quantity;

  CartLine copyWith({int? quantity}) => CartLine(
    id: id,
    productId: productId,
    productName: productName,
    unitPrice: unitPrice,
    stock: stock,
    quantity: quantity ?? this.quantity,
    productStatus: productStatus,
    addedAt: addedAt,
    categoryCode: categoryCode,
    imageBytes: imageBytes,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    productId,
    productName,
    unitPrice,
    stock,
    quantity,
    productStatus,
    addedAt,
    categoryCode,
    imageBytes?.length,
  ];
}

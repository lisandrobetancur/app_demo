import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../enums/product_condition.dart';
import '../enums/product_status.dart';

/// A product row plus the joined display data the UI needs (category code,
/// owner name, rating aggregate and preloaded image bytes).
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.condition,
    required this.status,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.categoryCode = '',
    this.ownerName = '',
    this.ratingAverage,
    this.ratingCount = 0,
    this.imagePath,
    this.imageBytes,
  });

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: map['id']! as String,
    name: map['name']! as String,
    description: map['description']! as String,
    price: (map['price']! as num).toDouble(),
    stock: map['stock']! as int,
    categoryId: map['category_id']! as String,
    condition: ProductCondition.parse(map['condition']! as String),
    status: ProductStatus.parse(map['status']! as String),
    ownerId: map['owner_id']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    categoryCode: (map['category_code'] as String?) ?? '',
    ownerName: (map['owner_name'] as String?) ?? '',
    ratingAverage: (map['rating_average'] as num?)?.toDouble(),
    ratingCount: (map['rating_count'] as int?) ?? 0,
    imagePath: map['image_path'] as String?,
  );

  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final ProductCondition condition;
  final ProductStatus status;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String categoryCode;
  final String ownerName;
  final double? ratingAverage;
  final int ratingCount;

  /// Image reference (file path on mobile, data URI on web).
  final String? imagePath;

  /// Image bytes preloaded by the service so widgets stay platform-agnostic.
  final Uint8List? imageBytes;

  bool get isOutOfStock => stock <= 0;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category_id': categoryId,
    'image_path': imagePath,
    'condition': condition.dbValue,
    'status': status.dbValue,
    'owner_id': ownerId,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    ProductCondition? condition,
    ProductStatus? status,
    DateTime? updatedAt,
    String? categoryCode,
    String? ownerName,
    double? ratingAverage,
    int? ratingCount,
    String? imagePath,
    Uint8List? imageBytes,
  }) => Product(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    stock: stock ?? this.stock,
    categoryId: categoryId ?? this.categoryId,
    condition: condition ?? this.condition,
    status: status ?? this.status,
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    categoryCode: categoryCode ?? this.categoryCode,
    ownerName: ownerName ?? this.ownerName,
    ratingAverage: ratingAverage ?? this.ratingAverage,
    ratingCount: ratingCount ?? this.ratingCount,
    imagePath: imagePath ?? this.imagePath,
    imageBytes: imageBytes ?? this.imageBytes,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    description,
    price,
    stock,
    categoryId,
    condition,
    status,
    ownerId,
    createdAt,
    updatedAt,
    categoryCode,
    ownerName,
    ratingAverage,
    ratingCount,
    imagePath,
    imageBytes?.length,
  ];
}

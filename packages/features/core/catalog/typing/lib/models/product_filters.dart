import 'package:equatable/equatable.dart';

import '../enums/product_condition.dart';
import '../enums/product_sort.dart';

/// Active catalog filters. Immutable; every change produces a new instance.
class ProductFilters extends Equatable {
  const ProductFilters({
    this.query = '',
    this.categoryIds = const <String>{},
    this.minPrice,
    this.maxPrice,
    this.conditions = const <ProductCondition>{},
    this.onlyInStock = false,
    this.sort = ProductSort.recent,
  });

  final String query;
  final Set<String> categoryIds;
  final double? minPrice;
  final double? maxPrice;
  final Set<ProductCondition> conditions;
  final bool onlyInStock;
  final ProductSort sort;

  bool get hasPriceRange => minPrice != null || maxPrice != null;

  /// Number of active filter dimensions (search and sort excluded).
  int get activeCount =>
      categoryIds.length +
      conditions.length +
      (hasPriceRange ? 1 : 0) +
      (onlyInStock ? 1 : 0);

  bool get hasAnyFilter => activeCount > 0;

  ProductFilters copyWith({
    String? query,
    Set<String>? categoryIds,
    double? minPrice,
    double? maxPrice,
    Set<ProductCondition>? conditions,
    bool? onlyInStock,
    ProductSort? sort,
    bool clearPriceRange = false,
  }) => ProductFilters(
    query: query ?? this.query,
    categoryIds: categoryIds ?? this.categoryIds,
    minPrice: clearPriceRange ? null : minPrice ?? this.minPrice,
    maxPrice: clearPriceRange ? null : maxPrice ?? this.maxPrice,
    conditions: conditions ?? this.conditions,
    onlyInStock: onlyInStock ?? this.onlyInStock,
    sort: sort ?? this.sort,
  );

  /// Everything cleared except the sort choice.
  ProductFilters cleared() => ProductFilters(sort: sort);

  @override
  List<Object?> get props => <Object?>[
    query,
    categoryIds,
    minPrice,
    maxPrice,
    conditions,
    onlyInStock,
    sort,
  ];
}

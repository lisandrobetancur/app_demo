/// Product condition stored in the `condition` column.
enum ProductCondition {
  brandNew('NEW'),
  used('USED');

  const ProductCondition(this.dbValue);

  final String dbValue;

  bool get isNew => this == ProductCondition.brandNew;

  bool get isUsed => this == ProductCondition.used;

  /// Translation key of the display label.
  String get labelKey => switch (this) {
    ProductCondition.brandNew => 'catalog.conditions.new',
    ProductCondition.used => 'catalog.conditions.used',
  };

  static ProductCondition parse(String raw) =>
      ProductCondition.values.firstWhere(
        (ProductCondition value) => value.dbValue == raw,
        orElse: () => ProductCondition.brandNew,
      );
}

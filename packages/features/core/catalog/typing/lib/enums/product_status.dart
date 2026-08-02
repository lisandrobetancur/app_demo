/// Publication status stored in the `status` column.
///
/// Deletion is logical: a `deleted` product disappears from the catalog but
/// its snapshots remain in historical orders.
enum ProductStatus {
  active('ACTIVE'),
  paused('PAUSED'),
  deleted('DELETED');

  const ProductStatus(this.dbValue);

  final String dbValue;

  bool get isActive => this == ProductStatus.active;

  bool get isPaused => this == ProductStatus.paused;

  bool get isDeleted => this == ProductStatus.deleted;

  /// Translation key of the display label.
  String get labelKey => switch (this) {
    ProductStatus.active => 'catalog.statuses.active',
    ProductStatus.paused => 'catalog.statuses.paused',
    ProductStatus.deleted => 'catalog.statuses.deleted',
  };

  static ProductStatus parse(String raw) => ProductStatus.values.firstWhere(
    (ProductStatus value) => value.dbValue == raw,
    orElse: () => ProductStatus.active,
  );
}

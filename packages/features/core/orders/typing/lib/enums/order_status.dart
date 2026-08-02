/// Order lifecycle stored in `orders.status`.
enum OrderStatus {
  created('CREATED'),
  paid('PAID'),
  shipped('SHIPPED'),
  delivered('DELIVERED'),
  cancelled('CANCELLED');

  const OrderStatus(this.dbValue);

  final String dbValue;

  bool get isCreated => this == OrderStatus.created;

  bool get isPaid => this == OrderStatus.paid;

  bool get isShipped => this == OrderStatus.shipped;

  bool get isDelivered => this == OrderStatus.delivered;

  bool get isCancelled => this == OrderStatus.cancelled;

  /// Cancellation is allowed only before shipping.
  bool get isCancellable => isCreated || isPaid;

  /// Translation key of the display label.
  String get labelKey => 'orders.statuses.${name.toLowerCase()}';

  static OrderStatus parse(String raw) => OrderStatus.values.firstWhere(
    (OrderStatus value) => value.dbValue == raw,
    orElse: () => OrderStatus.created,
  );
}

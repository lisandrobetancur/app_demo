/// Local notification types stored in the `notifications` table.
enum NotificationType {
  orderCreated('ORDER_CREATED'),
  orderStatus('ORDER_STATUS'),
  priceDrop('PRICE_DROP'),
  welcome('WELCOME');

  const NotificationType(this.dbValue);

  /// Value persisted in the `type` column.
  final String dbValue;

  bool get isOrderCreated => this == NotificationType.orderCreated;

  bool get isOrderStatus => this == NotificationType.orderStatus;

  bool get isPriceDrop => this == NotificationType.priceDrop;

  bool get isWelcome => this == NotificationType.welcome;

  static NotificationType parse(String raw) =>
      NotificationType.values.firstWhere(
        (NotificationType value) => value.dbValue == raw,
        orElse: () => NotificationType.welcome,
      );
}

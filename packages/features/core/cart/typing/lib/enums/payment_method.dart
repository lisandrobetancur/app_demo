/// Simulated payment methods stored in `orders.payment_method`.
///
/// Card data is validated in the UI but **never persisted** — only the
/// chosen method reaches the database.
enum PaymentMethod {
  card('CARD'),
  cash('CASH'),
  transfer('TRANSFER');

  const PaymentMethod(this.dbValue);

  final String dbValue;

  bool get isCard => this == PaymentMethod.card;

  bool get isCash => this == PaymentMethod.cash;

  bool get isTransfer => this == PaymentMethod.transfer;

  /// Translation key of the display label.
  String get labelKey => switch (this) {
    PaymentMethod.card => 'cart.payment_methods.card',
    PaymentMethod.cash => 'cart.payment_methods.cash',
    PaymentMethod.transfer => 'cart.payment_methods.transfer',
  };

  static PaymentMethod parse(String raw) => PaymentMethod.values.firstWhere(
    (PaymentMethod value) => value.dbValue == raw,
    orElse: () => PaymentMethod.card,
  );
}

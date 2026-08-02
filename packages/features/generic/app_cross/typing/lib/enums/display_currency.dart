/// Display currency chosen in settings.
///
/// Prices are always *stored* in COP; switching currency only changes how
/// they are rendered, using a fixed deterministic conversion rate.
enum DisplayCurrency {
  cop('COP', 1),
  usd('USD', 0.00025);

  const DisplayCurrency(this.code, this.factorFromCop);

  /// ISO code used by the number formatter.
  final String code;

  /// Fixed conversion factor (1 COP → this currency). Deterministic by
  /// design: the demo has no exchange-rate source.
  final double factorFromCop;

  bool get isCop => this == DisplayCurrency.cop;

  bool get isUsd => this == DisplayCurrency.usd;

  /// Converts a stored COP amount into this display currency.
  double display(double copAmount) => copAmount * factorFromCop;

  static DisplayCurrency parse(String raw) => DisplayCurrency.values.firstWhere(
    (DisplayCurrency value) => value.code == raw,
    orElse: () => DisplayCurrency.cop,
  );
}

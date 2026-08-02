import 'package:intl/intl.dart';

/// Money and date formatting helpers.
///
/// All price rendering in the app goes through [formatPrice] so the display
/// currency can be switched from settings without touching the stored values
/// (prices are always stored in the base currency).
class Formatters {
  const Formatters._();

  /// Formats [value] as currency for the given [locale] and [currencyCode].
  static String formatPrice(
    double value, {
    required String locale,
    required String currencyCode,
  }) {
    final NumberFormat format = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: _symbolFor(currencyCode),
      decimalDigits: currencyCode == 'COP' ? 0 : 2,
    );
    return format.format(value);
  }

  /// Formats [date] as a short readable date for the given [locale].
  static String formatDate(DateTime date, {required String locale}) =>
      DateFormat.yMMMd(locale).format(date);

  /// Formats [date] as date and time for the given [locale].
  static String formatDateTime(DateTime date, {required String locale}) =>
      DateFormat.yMMMd(locale).add_jm().format(date);

  static String _symbolFor(String currencyCode) => switch (currencyCode) {
    'COP' => r'$',
    'USD' => r'US$',
    'EUR' => '€',
    _ => currencyCode,
  };
}

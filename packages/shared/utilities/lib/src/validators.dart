/// Form validation helpers.
///
/// Validators return `null` when the value is valid, or a translation key
/// (never a literal message) when invalid, so the UI stays fully localized.
class Validators {
  const Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$',
  );

  static final RegExp _letterRegExp = RegExp('[A-Za-z]');

  static final RegExp _digitRegExp = RegExp('[0-9]');

  /// Valid email shape.
  static bool isValidEmail(String value) => _emailRegExp.hasMatch(value.trim());

  /// Password policy: at least 8 characters, one letter and one digit.
  static bool isValidPassword(String value) =>
      value.length >= 8 &&
      _letterRegExp.hasMatch(value) &&
      _digitRegExp.hasMatch(value);

  /// Length range check on the trimmed value.
  static bool hasLengthBetween(
    String value, {
    required int min,
    required int max,
  }) {
    final int length = value.trim().length;
    return length >= min && length <= max;
  }

  /// Parses a non-negative price from user input; returns `null` if invalid.
  static double? parsePrice(String value) {
    final double? parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return null;
    }
    return parsed;
  }

  /// Parses a non-negative integer stock from user input.
  static int? parseStock(String value) {
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }
}

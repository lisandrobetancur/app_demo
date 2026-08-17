import 'package:flutter_test/flutter_test.dart';

/// Reading money back out of the UI.
///
/// An assertion on a price is only worth writing if it checks the *number*.
/// `expect(subtotalText.exists, isTrue)` passes on a cart that renders
/// `$ 0`, which is exactly the bug worth catching — so the totals are parsed
/// back into doubles and compared against the rule the app claims to follow.
///
/// The app renders every price through `Formatters.formatPrice`, which is
/// locale-aware. The suite pins the locale (`--web-locale=es-ES`, and
/// `startLocale: es` in the launcher), so the separators are known: `.`
/// groups thousands and `,` marks decimals. [parseMoney] deliberately does
/// not care whether the currency symbol comes before or after the number,
/// because that *is* locale-dependent and not worth coupling to.
class Money {
  const Money._();

  /// Currency amounts are compared with a tolerance of one whole unit.
  ///
  /// Not sloppiness: the display currency (COP) renders with zero decimals,
  /// so the string on screen is already rounded. Comparing the parsed value
  /// against an exactly computed `double` would fail on the rounding alone.
  static const double tolerance = 1;

  /// Parses a rendered price back into a number.
  ///
  /// Handles the leading `-` the cart puts on the discount row, and tolerates
  /// the non-breaking space `intl` inserts next to the symbol.
  ///
  /// Throws [FormatException] when [rendered] holds no digits at all, which
  /// means the locator pointed at the wrong widget — a silent `0` there would
  /// turn a broken test into a passing one.
  static double parse(String rendered) {
    final bool isNegative = rendered.trimLeft().startsWith('-');
    final String digitsOnly = rendered.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (digitsOnly.isEmpty) {
      throw FormatException('No number in the rendered price "$rendered"');
    }
    // `.` groups, `,` marks decimals in the pinned locale.
    final String normalized = digitsOnly.replaceAll('.', '').replaceAll(
      ',',
      '.',
    );
    final double? value = double.tryParse(normalized);
    if (value == null) {
      throw FormatException('Cannot read a price from "$rendered"');
    }
    return isNegative ? -value : value;
  }

  /// Matcher for a currency amount, with the rounding tolerance applied.
  static Matcher closeToAmount(double expected) =>
      closeTo(expected, tolerance);
}

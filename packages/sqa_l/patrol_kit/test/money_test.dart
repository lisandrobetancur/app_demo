import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// Unit tests for the price parser the E2E assertions depend on.
///
/// It is the one piece of the suite with logic of its own — everything else
/// is a locator or a step — and it is also the piece whose failure is
/// silent: a parser that returns `0` instead of throwing turns a real
/// assertion into one that always passes. These run headless, so CI keeps
/// them honest without a browser.
void main() {
  group('Money.parse', () {
    test('reads a COP amount however the locale places the symbol', () {
      // `intl` puts the symbol before the number in some locales and after it
      // in others, and separates it with a non-breaking space. Neither is
      // worth coupling the parser to.
      expect(Money.parse('\$ 62.500.000'), 62500000);
      expect(Money.parse('62.500.000 \$'), 62500000);
    });

    test('reads the discount row, which renders with a leading minus', () {
      expect(Money.parse('-\$ 6.250.000'), -6250000);
    });

    test('reads a zero amount', () {
      expect(Money.parse('\$ 0'), 0);
    });

    test('reads a currency with decimals', () {
      // In the pinned locale `.` groups and `,` marks decimals.
      expect(Money.parse('US\$ 1.234,56'), closeTo(1234.56, 0.001));
      expect(Money.parse('-US\$ 1.234,56'), closeTo(-1234.56, 0.001));
    });

    test('throws when there is no number to read', () {
      // The failure that matters: a locator pointing at the wrong widget must
      // blow up, not quietly yield 0 and let an assertion pass.
      expect(() => Money.parse(''), throwsFormatException);
      expect(() => Money.parse('Orden'), throwsFormatException);
      expect(() => Money.parse('   '), throwsFormatException);
    });
  });

  group('Money.closeToAmount', () {
    test('absorbs the rounding of a whole-unit currency', () {
      expect(62500000.4, Money.closeToAmount(62500000));
    });

    test('still rejects a genuinely different amount', () {
      expect(62500002.0, isNot(Money.closeToAmount(62500000)));
    });
  });
}

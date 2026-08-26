import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'assert_d.dart';

/// One expectation, stated but not yet checked.
///
/// The unit `should` takes. Building one costs nothing — it only remembers
/// *how* to check, so `should` decides *when*. That is what lets several be
/// checked together instead of the first one deciding whether the rest ever
/// run.
///
/// The laziness is the whole point of holding a closure rather than a value.
/// Reading can throw — `Money.parse` rejects a price it cannot read,
/// `UiElement.text` rejects a locator that matched no text — and an eager
/// argument would throw while the argument list was still being built, before
/// `should` had a chance to collect anything. A lazy read is
/// for the same reason.
@immutable
class Consequence {
  const Consequence(this.what, this._check);

  /// The rule in business terms — "the total is the base plus tax". Becomes
  /// both the entry in the report and the reason on the failure.
  final String what;

  final void Function(AssertD collector) _check;

  /// Checks this expectation into [collector].
  ///
  /// A failed *expectation* is collected. An error raised while **reading**
  /// the value is not: that is a broken test rather than a failed
  /// expectation, and it propagates immediately — the same line AssertD draws
  /// everywhere else.
  void evaluateWith(AssertD collector) => _check(collector);
}

/// States an expectation about a value.
///
/// ```dart
/// seeThat('the buyer name', () => nameField.text, equals('Jane'))
/// ```
Consequence seeThat(String what, Object? Function() actual, Matcher matcher) =>
    Consequence(
      what,
      (AssertD collector) =>
          collector.softExpect(actual(), matcher, reason: what),
    );

/// States that a widget is in the tree.
///
/// Asserted through the finder rather than a bool, so a failure names the
/// widget it looked for instead of reporting `false`.
///
/// *Present*, not *visible*: a widget scrolled below the fold is legitimately
/// in the results and still needs scrolling to reach. Use [seeThatIsVisible]
/// when being on screen is the actual claim.
Consequence seeThatIsPresent(String what, PatrolFinder finder) => Consequence(
  what,
  (AssertD collector) =>
      collector.assertThatWidget(finder, describedAs: what).isPresent(),
);

/// States that a widget is on screen, not merely in the tree.
Consequence seeThatIsVisible(String what, PatrolFinder finder) => Consequence(
  what,
  (AssertD collector) =>
      collector.assertThatWidget(finder, describedAs: what).isVisible(),
);

/// States that a widget is absent from the tree.
Consequence seeThatIsAbsent(String what, PatrolFinder finder) => Consequence(
  what,
  (AssertD collector) =>
      collector.assertThatWidget(finder, describedAs: what).isNotPresent(),
);

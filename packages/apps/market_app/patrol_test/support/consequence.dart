import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'assert_d.dart';

/// One expectation, stated but not yet checked.
///
/// The unit `should` takes. Building one costs nothing: the value is read
/// only when `should` evaluates it, which is what lets several of them be
/// checked together instead of the first one deciding whether the rest ever
/// run.
///
/// That laziness is the whole reason [actual] is a function rather than a
/// value. Reading a value can throw — `Money.parse` rejects a price it cannot
/// read, `UiElement.text` rejects a locator that matched no text — and an
/// eager argument would throw while the argument list was still being built,
/// before `should` had a chance to collect anything. Serenity's `the(FIELD)`
/// is lazy for the same reason.
@immutable
class Consequence {
  const Consequence(this.what, this.actual, this.matcher);

  /// The rule in business terms — "el total suma la base más el IVA". Becomes
  /// both the entry in the report and the reason on the failure.
  final String what;

  /// Reads the value under test, when asked.
  final Object? Function() actual;

  final Matcher matcher;

  /// Checks this expectation into [collector].
  ///
  /// A failed *expectation* is collected. An error raised while **reading**
  /// the value is not: that is a broken test rather than a failed
  /// expectation, and it propagates immediately — the same line AssertD draws
  /// everywhere else.
  void evaluateWith(AssertD collector) =>
      collector.softExpect(actual(), matcher, reason: what);
}

/// States an expectation for [should] to check.
///
/// ```dart
/// seeThat('el nombre del comprador', () => nameField.text, equals('Juan'))
/// ```
Consequence seeThat(
  String what,
  Object? Function() actual,
  Matcher matcher,
) => Consequence(what, actual, matcher);

// ignore_for_file: avoid_catches_without_on_clauses
//
// AssertD
// ---------------------------------------------------------------------------
// A "soft assertions" collector for Flutter widget/integration tests, built
// with the Patrol testing framework in mind and modeled after AssertJ's
// `SoftAssertions` (https://assertj.github.io/doc/#assertj-core-soft-assertions).
//
// AssertJ parity cheat-sheet (Java -> Dart):
//
//   SoftAssertions softly = new SoftAssertions();          AssertD();
//   softly.assertThat(actual).isEqualTo(expected);         softly.assertThat(actual).isEqualTo(expected);
//   softly.assertThat(actual).as("reason").isTrue();       softly.assertThat(actual).describedAs('reason').isTrue();
//   softly.assertAll();                                    softly.assertAll();
//   SoftAssertions.assertSoftly(softly -> { ... });         await AssertD.assertSoftly((softly) async { ... });
//
// Design goals over the original class:
//   1. A fluent, AssertJ-style entry point (`assertThat`) instead of a bare
//      `softExpect(actual, matcher, reason: ...)` call, while still exposing
//      `softExpect`/`softCheck` for raw `matcher`-package expressions.
//   2. `assertSoftly`, mirroring AssertJ's closure-based helper: it
//      guarantees `assertAll()` runs (even if the block throws early),
//      exactly like AssertJ's own overload does with a try/finally.
//   3. A failure report format that mirrors AssertJ/JUnit's
//      "Multiple Failures (n failures)" / "-- failure N --" layout, and
//      keeps the original stack trace of each failure instead of discarding
//      it, so a soft-assertion crash still points at the real call site.
//   4. `checkTextsVisible` (successor to `checkStrings`) is written against
//      `patrol_finders`' `PatrolTester` (the `$` object you get from
//      `patrolTest`/`patrolWidgetTest`) instead of a bespoke scroll
//      extension, so scrolling reuses Patrol's own
//      `PatrolTester.scrollUntilVisible` / `PatrolFinder.scrollTo` retry and
//      settle logic rather than reinventing it. It also fixes the original
//      "scroll every N items counted from the end of the list" heuristic,
//      which could skip scrolling entirely for short lists or divide by a
//      user-supplied `0`.
//   5. `checkStrings` is kept as a `@Deprecated` shim so existing call sites
//      keep compiling while you migrate.

import 'dart:async';

import 'package:flutter/foundation.dart' show Key;
import 'package:flutter/rendering.dart' show AxisDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'assert_report.dart';

/// Mirrors AssertJ's `Assertions.entry(key, value)` factory, used with
/// [SoftMapAssertExt.contains]: `softly.assertThat(map).contains(entry(2, 'a'))`.
/// It's a thin wrapper over Dart's own [MapEntry] constructor.
MapEntry<K, V> entry<K, V>(K key, V value) => MapEntry<K, V>(key, value);

/// Substitutes `%s` placeholders in [template] with [args], in order,
/// mirroring the minimal subset of `String.format` that AssertJ's
/// `.as(description, args...)` relies on in practice.
String _formatDescription(String template, List<Object?> args) {
  String result = template;
  for (final Object? arg in args) {
    result = result.replaceFirst('%s', '$arg');
  }
  return result;
}

/// Collects assertion failures instead of throwing on the first one,
/// mirroring AssertJ's `SoftAssertions`.
///
/// Typical usage inside a Patrol test:
///
/// ```dart
/// patrolWidgetTest('shows all balances', ($) async {
///   await $.pumpWidgetAndSettle(const MyApp());
///
///   await AssertD.assertSoftly(($$) async {
///     $$.assertThat($.text('Total balance').evaluate().length)
///         .describedAs('total balance label')
///         .isEqualTo(1);
///
///     await $$.checkTextsVisible(
///       tester: $,
///       step: 'home screen',
///       texts: const ['Savings', 'Investments', 'Retirement'],
///       scrollView: find.byType(Scrollable),
///     );
///   });
///   // Throws one aggregated TestFailure here if anything above failed.
/// });
/// ```
class AssertD {
  final List<SoftFailure> _failures = <SoftFailure>[];

  /// All failures collected so far, without clearing them or throwing.
  /// Equivalent to AssertJ's `softly.errorsCollected()`.
  List<SoftFailure> get failures => List<SoftFailure>.unmodifiable(_failures);

  /// Equivalent to AssertJ's `softly.wasSuccess()` (negated).
  bool get hasFailures => _failures.isNotEmpty;

  int get failureCount => _failures.length;

  // ---------------------------------------------------------------------
  // AssertJ-style closure entry point
  // ---------------------------------------------------------------------

  /// Runs [block] with a fresh [AssertD] and always calls
  /// [assertAll] afterwards -- even if [block] itself throws -- mirroring
  /// AssertJ's `SoftAssertions.assertSoftly(softly -> { ... })`.
  ///
  /// Prefer this over manually new-ing a [AssertD] and remembering
  /// to call [assertAll] at the end of the test.
  static Future<void> assertSoftly(
    FutureOr<void> Function(AssertD softly) block,
  ) async {
    final AssertD softly = AssertD();
    try {
      await block(softly);
    } finally {
      softly.assertAll();
    }
  }

  // ---------------------------------------------------------------------
  // Fluent entry points (AssertJ's `assertThat(...)`)
  // ---------------------------------------------------------------------

  /// Fluent soft-assertion on any value, e.g.
  /// `softly.assertThat(balance).describedAs('balance').isEqualTo(100);`.
  SoftValueAssert<T> assertThat<T>(T actual, {String? describedAs}) =>
      SoftValueAssert<T>._(actual, this, label: describedAs);

  /// Fluent soft-assertion on a [Finder], e.g.
  /// `softly.assertThatFinder(find.text('OK')).existsOnce();`.
  SoftFinderAssert assertThatFinder(Finder finder, {String? describedAs}) =>
      SoftFinderAssert._(finder, this, label: describedAs);

  /// Fluent soft-assertion on a [PatrolFinder], which is what a page object
  /// in a Patrol suite actually holds. Unlike [assertThatFinder] it can wait:
  /// `await softly.assertThatWidget(page.cartView).becomesVisible();`.
  SoftPatrolFinderAssert assertThatWidget(
    PatrolFinder finder, {
    String? describedAs,
  }) => SoftPatrolFinderAssert._(finder, this, label: describedAs);

  // ---------------------------------------------------------------------
  // Low-level collectors
  // ---------------------------------------------------------------------

  /// Runs `expect(actual, matcher, reason: reason)` and, on failure,
  /// records it instead of throwing. This is the original class' primary
  /// API and remains the building block every fluent helper above uses.
  void softExpect(dynamic actual, dynamic matcher, {required String reason}) {
    softCheck(
      () => expect(actual, matcher, reason: reason),
      reason: reason,
      expected: describeExpectation(matcher),
      actual: describeValue(actual),
    );
  }

  /// Runs an arbitrary [check] (typically a call to `expect(...)`, a
  /// Patrol/`matcher`-package assertion, or a custom `Matcher`) and records
  /// its [TestFailure] instead of throwing, so it participates in the same
  /// aggregated report as [softExpect] and the fluent helpers.
  ///
  /// Use this when a single `actual`/`matcher` pair isn't expressive enough
  /// -- e.g. asserting on several properties of a widget in one go.
  void softCheck(
    void Function() check, {
    String? reason,
    String? expected,
    String? actual,
  }) {
    bool passed = true;
    try {
      check();
    } on TestFailure catch (failure, stackTrace) {
      passed = false;
      _record(reason, failure, stackTrace);
    } on PatrolFinderException catch (error, stackTrace) {
      passed = false;
      _record(reason, TestFailure('$error'), stackTrace);
    } finally {
      // Reported whether it passed or failed: otherwise a step that verified
      // four rules and one that verified none both just look green.
      reportAssertion(
        name: reason ?? 'assertion',
        passed: passed,
        expected: expected,
        actual: actual,
      );
    }
  }

  /// Async twin of [softCheck], and the one that matters in a Patrol suite.
  ///
  /// Patrol's waits are asynchronous and, when they give up, throw
  /// [PatrolTimeoutException] — not [TestFailure]. A collector that only
  /// caught `TestFailure` would let every `waitUntilVisible` failure escape
  /// as a hard error, which is the one thing soft assertions exist to avoid.
  /// Both are recorded here; anything else (a `StateError`, a type error)
  /// propagates, because that is a broken test rather than a failed
  /// expectation.
  Future<void> softCheckAsync(
    Future<void> Function() check, {
    String? reason,
    String? expected,
    String? actual,
  }) async {
    bool passed = true;
    try {
      await check();
    } on TestFailure catch (failure, stackTrace) {
      passed = false;
      _record(reason, failure, stackTrace);
    } on PatrolTimeoutException catch (error, stackTrace) {
      passed = false;
      _record(reason, TestFailure('$error'), stackTrace);
    } on PatrolFinderException catch (error, stackTrace) {
      passed = false;
      _record(reason, TestFailure('$error'), stackTrace);
    } finally {
      reportAssertion(
        name: reason ?? 'assertion',
        passed: passed,
        expected: expected,
        actual: actual,
      );
    }
  }

  void _record(String? reason, TestFailure failure, StackTrace stackTrace) {
    _failures.add(
      SoftFailure(
        reason: reason ?? failure.message ?? 'Soft assertion failed',
        failure: failure,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Throws a single aggregated [TestFailure] if any soft assertion failed,
  /// formatted like AssertJ/JUnit's `MultipleFailuresError`:
  ///
  /// ```
  /// Multiple Failures (2 failures)
  /// -- failure 1 --
  /// ...
  /// -- failure 2 --
  /// ...
  /// ```
  ///
  /// Does nothing if there are no failures. Clears the collected failures
  /// either way, so a [AssertD] instance can be reused across steps.
  void assertAll() {
    if (_failures.isEmpty) return;

    final int count = _failures.length;
    final StringBuffer buffer = StringBuffer()
      ..writeln(
        'Multiple Failures ($count ${count == 1 ? 'failure' : 'failures'})',
      );

    for (int i = 0; i < _failures.length; i++) {
      final SoftFailure failure = _failures[i];
      buffer
        ..writeln('-- failure ${i + 1} --')
        ..writeln(failure.failure.message ?? failure.reason)
        ..writeln(failure.stackTrace);
    }

    _failures.clear();
    throw TestFailure(buffer.toString());
  }

  // ---------------------------------------------------------------------
  // Patrol-flavored batch helper (successor to `checkStrings`)
  // ---------------------------------------------------------------------

  /// Soft-asserts that every string in [texts] is found in the widget tree,
  /// scrolling [scrollView] into view with Patrol's own retry/settle logic
  /// when a given text isn't immediately visible.
  ///
  /// - [tester] is the `$` object from `patrolTest`/`patrolWidgetTest`
  ///   (`PatrolTester` or `PatrolIntegrationTester`, since the latter is a
  ///   `PatrolTester`).
  /// - [step] labels the screen/step under test in failure messages, e.g.
  ///   `'home screen'`.
  /// - [matcher] defaults to `findsOneWidget`; pass `findsNothing` to assert
  ///   absence, or `findsWidgets` to allow duplicates.
  /// - [scrollView], when provided, is scrolled via
  ///   `PatrolTester.scrollUntilVisible` for every text that isn't already
  ///   on screen. A scroll failure (text genuinely missing, or view not
  ///   scrollable) does not abort the batch: the subsequent [softExpect]
  ///   reports the real, per-item failure instead.
  /// - Each failure reason is tagged with its position, e.g.
  ///   `[home screen] (2/5) expected text 'Savings' not found`, matching
  ///   AssertJ's practice of numbering soft-assertion failures.
  ///
  /// Calls [assertAll] at the end, so failures surface immediately as one
  /// aggregated [TestFailure] if this is the last thing your test does with
  /// this [AssertD] instance. Pass a shared instance (e.g. inside
  /// [assertSoftly]) if you want to keep collecting failures across
  /// multiple calls before asserting.
  Future<void> checkTextsVisible({
    required PatrolTester tester,
    required List<String> texts,
    required String step,
    Matcher matcher = findsOneWidget,
    bool findTextContaining = true,
    Finder? scrollView,
    AxisDirection? scrollDirection,
    Duration? scrollSettleTimeout,
    bool flush = true,
  }) async {
    for (int i = 0; i < texts.length; i++) {
      final String text = texts[i];
      final Finder finder = findTextContaining
          ? find.textContaining(text, findRichText: true)
          : find.text(text, findRichText: true);

      if (scrollView != null) {
        try {
          await tester.scrollUntilVisible(
            finder: finder,
            view: scrollView,
            scrollDirection: scrollDirection,
            settleBetweenScrollsTimeout: scrollSettleTimeout,
          );
        } on Exception {
          // Swallow scrolling failures here: if the text truly isn't in the
          // tree, softExpect below reports a precise, per-item failure
          // instead of aborting the whole batch on the first missing item.
        }
      }

      softExpect(
        finder,
        matcher,
        reason:
            "[$step] (${i + 1}/${texts.length}) expected text '$text' not found",
      );
    }

    // Flushing here is right for a one-shot call, but wrong inside a shared
    // collector: it would throw mid-block and discard the failures gathered
    // by everything after it. Callers that keep collecting pass `flush:
    // false` and let their own boundary decide when to raise.
    if (flush) {
      assertAll();
    }
  }

  /// Deprecated shim for the original `checkStrings` signature -- migrate
  /// call sites to [checkTextsVisible], which uses Patrol's scrolling APIs
  /// instead of a bespoke `scrollOnElement` extension and a `countTrigger`
  /// heuristic that could divide by zero or skip scrolling on short lists.
  @Deprecated('Use checkTextsVisible with a Patrol PatrolTester instead.')
  Future<void> checkStrings({
    required PatrolTester tester,
    required List<String> strings,
    required String step,
    dynamic scrollKey,
    Matcher? matcher,
    bool findTextContaining = true,
  }) => checkTextsVisible(
    tester: tester,
    texts: strings,
    step: step,
    matcher: matcher ?? findsOneWidget,
    findTextContaining: findTextContaining,
    scrollView: scrollKey == null ? null : find.byKey(scrollKey as Key),
  );
}

/// Fluent, AssertJ-flavored soft-assertion on a single value, returned by
/// [AssertD.assertThat]. Every method records a failure (via the
/// owning [AssertD]) instead of throwing, and returns `this` so
/// calls can be chained, e.g.:
///
/// ```dart
/// softly.assertThat(response.statusCode)
///     .describedAs('status code')
///     .isEqualTo(200);
/// ```
class SoftValueAssert<T> {
  SoftValueAssert._(this._actual, this._softly, {String? label})
    : _label = label;

  final T _actual;
  final AssertD _softly;
  String? _label;

  /// Sets the failure description, mirroring AssertJ's
  /// `.as(String description, Object... args)`. [args], if given, are
  /// substituted for `%s` placeholders in [description] in order --
  /// e.g. `describedAs("%s's age should be 100", [person.name])`.
  /// (Named `describedAs` rather than AssertJ's `as` because `as` is a
  /// built-in identifier in Dart and reads as the cast operator.)
  SoftValueAssert<T> describedAs(
    String description, [
    List<Object?> args = const <Object?>[],
  ]) {
    _label = _formatDescription(description, args);
    return this;
  }

  /// Escape hatch for any `matcher`-package [Matcher], e.g.
  /// `.matches(inInclusiveRange(0, 100))`.
  SoftValueAssert<T> matches(Matcher matcher, {String? because}) {
    _softly.softExpect(
      _actual,
      matcher,
      reason: because ?? _label ?? 'Expected <$_actual> to match $matcher',
    );
    return this;
  }

  SoftValueAssert<T> isEqualTo(Object? expected) => matches(equals(expected));

  SoftValueAssert<T> isNotEqualTo(Object? expected) =>
      matches(isNot(equals(expected)));

  // NOTE: these four intentionally go through `equals(true/false/null)`
  // instead of the matcher package's own `isTrue`/`isFalse`/`isNull`/
  // `isNotNull` constants. Those constants share their exact name with
  // this class' own methods, and inside an instance method an unqualified
  // name resolves against `this`'s members before the top-level scope --
  // so `matches(isTrue)` inside `isTrue()` would tear off the method
  // itself (wrong type for `matches`) instead of grabbing the matcher.
  // `equals(...)` has no same-named method here, so it can't be shadowed.
  SoftValueAssert<T> isTrue() => matches(equals(true));

  SoftValueAssert<T> isFalse() => matches(equals(false));

  SoftValueAssert<T> isNull() => matches(equals(null));

  SoftValueAssert<T> isNotNull() => matches(isNot(equals(null)));

  /// Kept as `containsValue` (rather than AssertJ's overloaded `contains`)
  /// for the same shadowing reason, and to stay unambiguous now that
  /// [SoftIterableAssertExt] adds its own `contains` for `Iterable` values.
  SoftValueAssert<T> containsValue(Object? element) =>
      matches(contains(element));

  /// AssertJ's `assertThat(x).isIn(collection)`: asserts that [values]
  /// contains this assertion's actual value.
  SoftValueAssert<T> isIn(Iterable<Object?> values) {
    _softly.softExpect(
      values.contains(_actual),
      true,
      reason: _label ?? 'Expected <$_actual> to be in $values',
    );
    return this;
  }

  /// AssertJ's `assertThat(x).isNotIn(collection)`.
  SoftValueAssert<T> isNotIn(Iterable<Object?> values) {
    _softly.softExpect(
      values.contains(_actual),
      false,
      reason: _label ?? 'Expected <$_actual> to not be in $values',
    );
    return this;
  }
}

/// Fluent, AssertJ-flavored soft-assertion on a [Finder], returned by
/// [AssertD.assertThatFinder]. Mirrors the intent of AssertJ's
/// widget/element assertions (`exists()`, `doesNotExist()`, ...).
class SoftFinderAssert {
  SoftFinderAssert._(this._finder, this._softly, {String? label})
    : _label = label;

  final Finder _finder;
  final AssertD _softly;
  String? _label;

  SoftFinderAssert describedAs(
    String description, [
    List<Object?> args = const <Object?>[],
  ]) {
    _label = _formatDescription(description, args);
    return this;
  }

  SoftFinderAssert exists() => _check(findsWidgets, 'to exist');

  SoftFinderAssert existsOnce() =>
      _check(findsOneWidget, 'to exist exactly once');

  SoftFinderAssert existsNTimes(int n) =>
      _check(findsNWidgets(n), 'to exist $n times');

  SoftFinderAssert doesNotExist() => _check(findsNothing, 'to not exist');

  SoftFinderAssert _check(Matcher matcher, String expectation) {
    _softly.softExpect(
      _finder,
      matcher,
      reason: _label ?? 'Expected widget matched by $_finder $expectation',
    );
    return this;
  }
}

/// Fluent soft-assertion on a [PatrolFinder], returned by
/// [AssertD.assertThatWidget].
///
/// This is where Patrol differs from plain `flutter_test`, in two ways worth
/// knowing:
///
///  * **It can wait.** An integration test races the UI, so asserting a
///    widget's presence the instant a step ends usually means asserting on a
///    frame that has not arrived. [becomesVisible] and [becomesPresent] use
///    Patrol's own retry-and-settle waits, and record a timeout as a soft
///    failure instead of throwing.
///  * **Present is not visible.** `findsOneWidget` matches a widget that is
///    in the tree but scrolled off-screen, while Patrol's waits require it to
///    be hit-testable. That distinction cost this suite an afternoon: a
///    button below the fold reported "Found 0 widgets", which reads as
///    missing rather than as out of view. [isPresent] and [isVisible] name
///    the two cases apart so an assertion says which one it means.
class SoftPatrolFinderAssert {
  SoftPatrolFinderAssert._(this._finder, this._softly, {String? label})
    : _label = label;

  final PatrolFinder _finder;
  final AssertD _softly;
  String? _label;

  SoftPatrolFinderAssert describedAs(
    String description, [
    List<Object?> args = const <Object?>[],
  ]) {
    _label = _formatDescription(description, args);
    return this;
  }

  /// Waits until the widget is visible (hit-testable), recording a soft
  /// failure if it never is.
  Future<SoftPatrolFinderAssert> becomesVisible({Duration? timeout}) async {
    await _softly.softCheckAsync(
      () => _finder.waitUntilVisible(timeout: timeout),
      reason: _label ?? 'Expected $_finder to become visible',
    );
    return this;
  }

  /// Waits until the widget exists in the tree, visible or not.
  Future<SoftPatrolFinderAssert> becomesPresent({Duration? timeout}) async {
    await _softly.softCheckAsync(
      () => _finder.waitUntilExists(timeout: timeout),
      reason: _label ?? 'Expected $_finder to exist',
    );
    return this;
  }

  /// In the tree right now — which says nothing about whether it is on
  /// screen.
  SoftPatrolFinderAssert isPresent() =>
      _check(_finder, findsWidgets, 'to be present');

  /// On screen and hit-testable right now.
  SoftPatrolFinderAssert isVisible() =>
      _check(_finder.hitTestable(), findsWidgets, 'to be visible');

  SoftPatrolFinderAssert isNotPresent() =>
      _check(_finder, findsNothing, 'to be absent');

  SoftPatrolFinderAssert isNotVisible() =>
      _check(_finder.hitTestable(), findsNothing, 'to be off screen');

  SoftPatrolFinderAssert existsOnce() =>
      _check(_finder, findsOneWidget, 'to be present exactly once');

  SoftPatrolFinderAssert existsNTimes(int n) =>
      _check(_finder, findsNWidgets(n), 'to be present $n times');

  SoftPatrolFinderAssert _check(
    Finder finder,
    Matcher matcher,
    String expectation,
  ) {
    _softly.softExpect(
      finder,
      matcher,
      reason: _label ?? 'Expected widget matched by $_finder $expectation',
    );
    return this;
  }
}

/// A single recorded soft-assertion failure: the human-readable [reason]
/// supplied at the call site, the underlying flutter_test [TestFailure],
/// and the [StackTrace] captured at the moment it was caught (discarded by
/// the original implementation, which made failures hard to trace back to
/// their call site once aggregated).
class SoftFailure {
  SoftFailure({
    required this.reason,
    required this.failure,
    required this.stackTrace,
  });

  final String reason;
  final TestFailure failure;
  final StackTrace stackTrace;
}

// ---------------------------------------------------------------------------
// Type-specific fluent assertions (AssertJ's per-type assertThat overloads)
// ---------------------------------------------------------------------------
//
// AssertJ dispatches `assertThat(x)` to a type-specific assert class
// (`ListAssert`, `MapAssert`, `CharacterAssert`, ...) at compile time via
// method overloading, which Dart doesn't have. Extension methods are the
// idiomatic Dart equivalent: `AssertD.assertThat<T>` always returns
// a plain `SoftValueAssert<T>`, and these extensions add extra methods to
// it *only* when its type argument matches (`Iterable<E>`, `Map<K, V>`,
// `String`, or a `Comparable`) -- so `softly.assertThat(list).contains(x)`
// resolves correctly as long as `list`'s static type is some `Iterable<E>`.
//
// One real difference from Java: AssertJ's `contains`/`startsWith`/
// `containsSequence` etc. take `T...` varargs. Dart has no varargs, so
// these take a required first element plus an optional trailing list for
// any extra ones, e.g. `containsSequence('2', '3')` matches the Java call
// exactly, while `contains(frodo, [sam])` needs the extra values wrapped
// in a list.

/// Adds AssertJ's `ListAssert`/`IterableAssert`-style methods to
/// `softly.assertThat(someIterable)`.
extension SoftIterableAssertExt<E> on SoftValueAssert<Iterable<E>> {
  SoftValueAssert<Iterable<E>> isEmpty() {
    _softly.softExpect(
      _actual.isEmpty,
      true,
      reason: _label ?? 'Expected $_actual to be empty',
    );
    return this;
  }

  SoftValueAssert<Iterable<E>> isNotEmpty() {
    _softly.softExpect(
      _actual.isNotEmpty,
      true,
      reason: _label ?? 'Expected $_actual to not be empty',
    );
    return this;
  }

  SoftValueAssert<Iterable<E>> hasSize(int expected) {
    _softly.softExpect(
      _actual.length,
      equals(expected),
      reason: _label ?? 'Expected $_actual to have size $expected',
    );
    return this;
  }

  /// Asserts [_actual] contains [first] and every element of [more], in
  /// any order. `assertThat(list).contains('1')` matches the Java call
  /// exactly; for several values, wrap the extras: `contains(frodo, [sam])`.
  SoftValueAssert<Iterable<E>> contains(E first, [Iterable<E>? more]) {
    final List<Object?> expected = <Object?>[first, ...?more];
    final List<Object?> missing = expected
        .where((Object? e) => !_actual.contains(e))
        .toList();
    _softly.softExpect(
      missing.isEmpty,
      true,
      reason:
          _label ?? 'Expected $_actual to contain $expected, missing $missing',
    );
    return this;
  }

  /// Asserts [_actual] contains none of [first] or [more].
  SoftValueAssert<Iterable<E>> doesNotContain(E first, [Iterable<E>? more]) {
    final List<Object?> unwanted = <Object?>[first, ...?more];
    final List<Object?> present = unwanted.where(_actual.contains).toList();
    _softly.softExpect(
      present.isEmpty,
      true,
      reason: _label ?? 'Expected $_actual to not contain $present',
    );
    return this;
  }

  SoftValueAssert<Iterable<E>> doesNotContainNull() {
    _softly.softExpect(
      _actual.contains(null),
      false,
      reason: _label ?? 'Expected $_actual to not contain null',
    );
    return this;
  }

  /// Asserts [_actual] starts with [first] followed by [more], in order.
  /// `assertThat(list).startsWith('1')` matches the Java call exactly.
  SoftValueAssert<Iterable<E>> startsWith(E first, [Iterable<E>? more]) {
    final List<Object?> expected = <Object?>[first, ...?more];
    final List<Object?> actualPrefix = _actual.take(expected.length).toList();
    _softly.softExpect(
      actualPrefix,
      equals(expected),
      reason: _label ?? 'Expected $_actual to start with $expected',
    );
    return this;
  }

  /// Asserts [_actual] contains [first], [second], and [more] as a
  /// *contiguous* run, in order -- AssertJ's `containsSequence` (as
  /// opposed to `containsSubsequence`, which allows gaps).
  /// `assertThat(list).containsSequence('2', '3')` matches the Java call
  /// exactly.
  SoftValueAssert<Iterable<E>> containsSequence(
    E first,
    E second, [
    Iterable<E>? more,
  ]) {
    final List<Object?> sequence = <Object?>[first, second, ...?more];
    final List<Object?> list = _actual.toList();
    bool found = false;
    for (
      int start = 0;
      start <= list.length - sequence.length && !found;
      start++
    ) {
      found = true;
      for (int i = 0; i < sequence.length; i++) {
        if (list[start + i] != sequence[i]) {
          found = false;
          break;
        }
      }
    }
    _softly.softExpect(
      found,
      true,
      reason: _label ?? 'Expected $_actual to contain sequence $sequence',
    );
    return this;
  }
}

/// Adds AssertJ's `MapAssert`-style methods to `softly.assertThat(someMap)`.
extension SoftMapAssertExt<K, V> on SoftValueAssert<Map<K, V>> {
  SoftValueAssert<Map<K, V>> isEmpty() {
    _softly.softExpect(
      _actual.isEmpty,
      true,
      reason: _label ?? 'Expected $_actual to be empty',
    );
    return this;
  }

  SoftValueAssert<Map<K, V>> isNotEmpty() {
    _softly.softExpect(
      _actual.isNotEmpty,
      true,
      reason: _label ?? 'Expected $_actual to not be empty',
    );
    return this;
  }

  SoftValueAssert<Map<K, V>> containsKey(K key) {
    _softly.softExpect(
      _actual.containsKey(key),
      true,
      reason: _label ?? 'Expected $_actual to contain key $key',
    );
    return this;
  }

  /// `assertThat(map).doesNotContainKeys(10)` matches the Java call
  /// exactly; pass extras via [more]: `doesNotContainKeys(10, [20])`.
  SoftValueAssert<Map<K, V>> doesNotContainKeys(K first, [Iterable<K>? more]) {
    final List<Object?> unwanted = <Object?>[first, ...?more];
    final List<Object?> present = unwanted.where(_actual.containsKey).toList();
    _softly.softExpect(
      present.isEmpty,
      true,
      reason: _label ?? 'Expected $_actual to not contain keys $present',
    );
    return this;
  }

  /// `assertThat(map).contains(entry(2, 'a'))`, using the top-level
  /// [entry] helper.
  SoftValueAssert<Map<K, V>> contains(MapEntry<K, V> expectedEntry) {
    final bool matchFound = _actual.entries.any(
      (MapEntry<Object?, Object?> e) =>
          e.key == expectedEntry.key && e.value == expectedEntry.value,
    );
    _softly.softExpect(
      matchFound,
      true,
      reason: _label ?? 'Expected $_actual to contain entry $expectedEntry',
    );
    return this;
  }
}

/// Adds AssertJ's `StringAssert`-style methods to
/// `softly.assertThat(someString)`.
extension SoftStringAssertExt on SoftValueAssert<String> {
  SoftValueAssert<String> isEmpty() {
    _softly.softExpect(
      _actual.isEmpty,
      true,
      reason: _label ?? 'Expected "$_actual" to be empty',
    );
    return this;
  }

  SoftValueAssert<String> isNotEmpty() {
    _softly.softExpect(
      _actual.isNotEmpty,
      true,
      reason: _label ?? 'Expected "$_actual" to not be empty',
    );
    return this;
  }

  SoftValueAssert<String> startsWith(String prefix) {
    _softly.softExpect(
      _actual.startsWith(prefix),
      true,
      reason: _label ?? 'Expected "$_actual" to start with "$prefix"',
    );
    return this;
  }

  SoftValueAssert<String> endsWith(String suffix) {
    _softly.softExpect(
      _actual.endsWith(suffix),
      true,
      reason: _label ?? 'Expected "$_actual" to end with "$suffix"',
    );
    return this;
  }

  SoftValueAssert<String> isEqualToIgnoringCase(String other) {
    _softly.softExpect(
      _actual.toLowerCase(),
      other.toLowerCase(),
      reason:
          _label ?? 'Expected "$_actual" to be equal to "$other" ignoring case',
    );
    return this;
  }

  /// Cosmetic no-op kept for fluent-chain parity with AssertJ's
  /// `CharacterAssert.inUnicode()`, which only changes how the value is
  /// rendered in failure messages. Dart's string interpolation is already
  /// Unicode-safe, so there's nothing to switch here.
  SoftValueAssert<String> inUnicode() => this;

  /// Approximates AssertJ's `Character.isLowerCase`: true for a value
  /// whose lowercase form equals itself and whose uppercase form differs
  /// from it (so digits/symbols, which have no case, are correctly `false`).
  SoftValueAssert<String> isLowerCase() {
    final bool isLower =
        _actual.toLowerCase() == _actual && _actual.toUpperCase() != _actual;
    _softly.softExpect(
      isLower,
      true,
      reason: _label ?? 'Expected "$_actual" to be lower case',
    );
    return this;
  }
}

/// Adds AssertJ's ordering assertions (`isGreaterThan`, ...) to any
/// `softly.assertThat(x)` where `x`'s type self-implements
/// `Comparable<T>` -- `String` (handy for single-character strings,
/// standing in for Java's `char`), `DateTime`, `Duration`, or your own
/// `Comparable` classes.
///
/// This deliberately does *not* cover `int`/`double`: they implement
/// `Comparable<num>`, not `Comparable<int>`/`Comparable<double>`, so they
/// don't satisfy the `T extends Comparable<T>` bound (verified with
/// `dart analyze` -- `int`/`double` fail with `type_argument_not_matching_bounds`
/// against this exact bound shape). [SoftNumAssertExt] below covers them
/// instead, via the (unrelated) `T extends num` bound.
///
/// Implemented via [Comparable.compareTo] rather than `package:matcher`'s
/// own `greaterThan`/`lessThan` matchers -- confirmed by actually running
/// these against a `String` that those matchers dynamically invoke `<`/`>`
/// operators on the value, which `String` doesn't implement (only
/// `compareTo`); the mismatch is swallowed by `expect()`'s internal
/// try/catch and silently reported as "didn't match" instead of a clear
/// error, so it's an easy trap to ship without noticing. `compareTo` is
/// the one comparison every `Comparable` is guaranteed to implement.
extension SoftComparableAssertExt<T extends Comparable<T>>
    on SoftValueAssert<T> {
  SoftValueAssert<T> isGreaterThan(T other) {
    _softly.softExpect(
      _actual.compareTo(other) > 0,
      true,
      reason: _label ?? 'Expected $_actual to be greater than $other',
    );
    return this;
  }

  SoftValueAssert<T> isGreaterThanOrEqualTo(T other) {
    _softly.softExpect(
      _actual.compareTo(other) >= 0,
      true,
      reason:
          _label ?? 'Expected $_actual to be greater than or equal to $other',
    );
    return this;
  }

  SoftValueAssert<T> isLessThan(T other) {
    _softly.softExpect(
      _actual.compareTo(other) < 0,
      true,
      reason: _label ?? 'Expected $_actual to be less than $other',
    );
    return this;
  }

  SoftValueAssert<T> isLessThanOrEqualTo(T other) {
    _softly.softExpect(
      _actual.compareTo(other) <= 0,
      true,
      reason: _label ?? 'Expected $_actual to be less than or equal to $other',
    );
    return this;
  }
}

/// Adds the same ordering assertions as [SoftComparableAssertExt], but for
/// `int`/`double`/`num`, e.g. `softly.assertThat(balance).isGreaterThan(0)`.
/// `num` *does* implement `<`/`>`/etc. natively, so these use them directly
/// rather than going through `compareTo`.
extension SoftNumAssertExt<T extends num> on SoftValueAssert<T> {
  SoftValueAssert<T> isGreaterThan(num other) {
    _softly.softExpect(
      _actual > other,
      true,
      reason: _label ?? 'Expected $_actual to be greater than $other',
    );
    return this;
  }

  SoftValueAssert<T> isGreaterThanOrEqualTo(num other) {
    _softly.softExpect(
      _actual >= other,
      true,
      reason:
          _label ?? 'Expected $_actual to be greater than or equal to $other',
    );
    return this;
  }

  SoftValueAssert<T> isLessThan(num other) {
    _softly.softExpect(
      _actual < other,
      true,
      reason: _label ?? 'Expected $_actual to be less than $other',
    );
    return this;
  }

  SoftValueAssert<T> isLessThanOrEqualTo(num other) {
    _softly.softExpect(
      _actual <= other,
      true,
      reason: _label ?? 'Expected $_actual to be less than or equal to $other',
    );
    return this;
  }
}

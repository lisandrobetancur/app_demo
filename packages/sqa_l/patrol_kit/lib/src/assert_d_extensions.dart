part of 'assert_d.dart';

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

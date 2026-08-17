import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// A locator, declared by hand.
///
/// The point of this layer is that **the strategy is a decision, not a
/// convention**. Every element says out loud how it is found — by key, by the
/// text the user reads, by widget type, by position inside a container — and
/// each one can be decided separately, in one line, without the surrounding
/// page caring.
///
/// That matters most where keys do not exist yet. On a mature app the first
/// pass is written with whatever is reachable:
///
/// ```dart
/// static final Loc submit = Loc.text('Iniciar sesión');
/// ```
///
/// and once a `Key` is added to that widget, one line changes:
///
/// ```dart
/// static final Loc submit = Loc.key('login_submit_button');
/// ```
///
/// Nothing else in the page, the steps or the tests moves.
///
/// A `Loc` composes `Finder`s from `flutter_test` and only becomes a
/// [PatrolFinder] in [resolve]. That keeps the composition on the API that is
/// stable across Patrol versions, and makes a locator inspectable before a
/// test ever runs.
@immutable
class Loc {
  const Loc(this.description, this.finder);

  // --- Base strategies -----------------------------------------------------

  /// By key, written as the raw string. The everyday case once the widget has
  /// one.
  factory Loc.key(String value) => Loc("key '$value'", find.byKey(Key(value)));

  /// By an already-declared [Key] — the constants packages expose theirs this
  /// way, so a renamed key still breaks at compile time.
  factory Loc.widgetKey(Key key) => Loc('key $key', find.byKey(key));

  /// By the exact text the user reads.
  ///
  /// The honest trade-off: it needs no cooperation from the app, and it
  /// breaks when the copy changes. On a localized app that also pins the test
  /// to one language — which is fine when the suite pins the locale, as this
  /// one does, and a liability when it does not.
  factory Loc.text(String text) => Loc('texto "$text"', find.text(text));

  /// By a fragment of the text, for composed or interpolated strings.
  factory Loc.textContaining(String fragment) =>
      Loc('texto que contiene "$fragment"', find.textContaining(fragment));

  /// By widget type. Precise when the type is the app's own
  /// (`Loc.type(ProductCard)`), ambiguous when it is Flutter's
  /// (`Loc.type(TextField)`) — pair it with [at] or [within].
  factory Loc.type(Type type) => Loc('widget $type', find.byType(type));

  /// By icon, for controls with no text at all.
  factory Loc.icon(IconData icon) =>
      Loc('icono ${icon.codePoint}', find.byIcon(icon));

  /// Escape hatch: any `flutter_test` finder, named so the report still reads.
  factory Loc.custom(Finder finder, String description) =>
      Loc(description, finder);

  /// How this locator reads in an error message. Composed strategies build it
  /// up ("texto \"Entrar\" dentro de key 'login_view'"), so a failure names
  /// the locator instead of dumping a finder.
  final String description;

  final Finder finder;

  // --- Refinements ---------------------------------------------------------

  /// The nth match. A last resort: it depends on render order, so it breaks
  /// when the layout is rearranged. Prefer [within].
  Loc at(int index) => Loc('$description [#$index]', finder.at(index));

  Loc get first => Loc('$description (primero)', finder.first);

  Loc get last => Loc('$description (último)', finder.last);

  /// Scoped to a container — the robust way to disambiguate a repeated
  /// widget, and the one that survives a redesign.
  Loc within(Loc ancestor) => Loc(
    '$description dentro de ${ancestor.description}',
    find.descendant(of: ancestor.finder, matching: finder),
  );

  /// The container that holds [descendant] — a row found by the text inside
  /// it, for instance.
  Loc containing(Loc descendant) => Loc(
    '$description que contiene ${descendant.description}',
    find.ancestor(of: descendant.finder, matching: finder),
  );

  /// Turns the declaration into something Patrol can act on.
  PatrolFinder resolve(PatrolIntegrationTester $) => $(finder);

  @override
  String toString() => description;
}

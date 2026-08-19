import 'package:flutter/foundation.dart';

/// The business taxonomy a scenario declares itself under.
///
/// Epics and features were plain strings, and that is exactly the problem the
/// tag vocabulary already solved: written by hand at each call site they
/// drift. "Authentication" and "Autenticación" become two features in the
/// report, each holding half the tests, and nothing anywhere says they were
/// meant to be one. Nobody notices, because both spellings are perfectly
/// valid strings.
///
/// So the names are declared once, in the project's own catalogue, and passed
/// as values — the way [Severity] already works. A literal in a scenario stops
/// compiling, which makes the compiler the thing that catches the typo instead
/// of a reader comparing two pages of a report.
///
/// The types live here, in the kit; the catalogue does not. Epics and features
/// are what a *product* is made of, so they belong to the project — see
/// `patrol_test/support/epics.dart` and `features.dart` in the app.

/// A top-level area of the product: what a whole group of features serves.
///
/// ```dart
/// abstract final class Epics {
///   static const Epic access = Epic('Access');
/// }
/// ```
@immutable
class Epic {
  const Epic(this.name);

  /// What the report shows, verbatim.
  final String name;

  @override
  bool operator ==(Object other) => other is Epic && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// One capability inside an epic — the level the report groups scenarios by.
///
/// A feature carries its own epic, declared once:
///
/// ```dart
/// abstract final class Features {
///   static const Feature login = Feature('Authentication', epic: Epics.access);
/// }
/// ```
///
/// That is the second half of the problem. When each scenario names both, the
/// pair is repeated at every call site and nothing stops one test filing
/// "Authentication" under `Access` and the next filing it under `Accounts` —
/// which is how a feature ends up in two places in the same report. Declared
/// on the feature, the pairing exists in exactly one line, and a scenario that
/// names the feature gets the right epic by construction.
@immutable
class Feature {
  const Feature(this.name, {required this.epic});

  /// What the report shows, verbatim.
  final String name;

  /// The epic this feature belongs under. Always the same one.
  final Epic epic;

  @override
  bool operator ==(Object other) =>
      other is Feature && other.name == name && other.epic == epic;

  @override
  int get hashCode => Object.hash(name, epic);

  @override
  String toString() => '${epic.name} / $name';
}

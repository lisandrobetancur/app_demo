import 'package:patrol/patrol.dart';

/// Base of every Page Object.
///
/// The contract of this layer, deliberately narrow:
///
///  * a page knows **where** things are (keys, never raw text) and **how** to
///    touch them (tap, type, read) — nothing else;
///  * a page never asserts business rules and never chains flows; that is the
///    steps layer's job;
///  * locators come from the feature's `constants/` package, so a renamed key
///    breaks the test at compile time instead of at run time.
abstract class BasePage {
  const BasePage(this.$);

  final PatrolIntegrationTester $;

  /// Root key of the view, used by [isVisible] and [waitUntilVisible].
  PatrolFinder get root;

  /// Whether the view is currently on screen.
  bool get isVisible => root.exists;

  /// Waits until the view is on screen; fails the test on timeout.
  Future<void> waitUntilVisible() => root.waitUntilVisible();
}

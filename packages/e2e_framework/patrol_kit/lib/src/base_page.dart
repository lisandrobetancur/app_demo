import 'package:patrol/patrol.dart';

import 'element.dart';
import 'locator.dart';

/// Base of every Page Object.
///
/// The contract of this layer, deliberately narrow:
///
///  * a page knows **where** things are and **how** to touch them — nothing
///    else;
///  * a page may compose **its own** interactions into the screen's flow — a
///    login page owns `login()`, built from its fields and its button — but
///    it never crosses into another screen and never asserts business rules;
///    whether the flow *worked* is the steps layer's claim to make;
///  * a page never reports: screenshots belong to the steps layer, which
///    knows what a given interaction was *for*;
///  * a page may **read** values (a price, a label, whether a button is
///    enabled) because only it knows where they live — but never decides
///    whether the value is correct. That is the steps layer's call.
///
/// Locators are declared, one per element, at the top of each page: see
/// [Loc]. The strategy is chosen per element and can be swapped in one line
/// — key, visible text, widget type, position inside a container — without
/// anything downstream moving.
abstract class BasePage {
  const BasePage(this.$);

  final PatrolIntegrationTester $;

  /// Root of the view, used by [isVisible] and [waitUntilVisible].
  ///
  /// A migrated page resolves it from its declared locator
  /// (`_view.resolve($)`); one not migrated yet still returns a finder
  /// directly. Both work — the layer is meant to be adopted a page at a time,
  /// not in one sweep.
  PatrolFinder get root;

  /// Binds a declared locator to the operations a test performs on it.
  UiElement element(Loc loc) => UiElement($, loc);

  /// Whether the view is currently on screen.
  bool get isVisible => root.exists;

  /// Waits until the view is on screen; fails the test on timeout.
  Future<void> waitUntilVisible() => root.waitUntilVisible();

  /// Every `Text` rendered under [finder], in tree order.
  ///
  /// Kept for the pages not yet migrated to [UiElement]; new code should go
  /// through `element(...).text`.
  List<String> textsIn(PatrolFinder finder) =>
      textsUnder($.tester, finder.finder);

  /// The text of a labelled row's value — the last `Text` under [finder].
  ///
  /// Throws [StateError] when the finder matches no text at all, rather than
  /// returning an empty string that would quietly satisfy a later assertion.
  String valueIn(PatrolFinder finder) {
    final List<String> texts = textsIn(finder);
    if (texts.isEmpty) {
      throw StateError('No Text under the finder — wrong locator?');
    }
    return texts.last;
  }
}

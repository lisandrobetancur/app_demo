import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Base of every Page Object.
///
/// The contract of this layer, deliberately narrow:
///
///  * a page knows **where** things are (keys, never raw text) and **how** to
///    touch them (tap, type, read) — nothing else;
///  * a page never asserts business rules, never chains flows and never
///    reports: screenshots belong to the steps layer, which knows what a
///    given interaction was *for*;
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

  /// Every `Text` rendered under [finder], in tree order.
  ///
  /// Reading values is as much a page's job as locating them: an assertion
  /// worth writing checks the number on screen, and only the page knows where
  /// that number lives. What a page must never do is decide whether the value
  /// is *correct* — that belongs to the steps layer.
  ///
  /// `matchRoot` is on because a key sits on the `Text` itself about as often
  /// as it sits on the row wrapping it; without it the first case reads as
  /// empty, which is the failure mode that quietly turns a broken locator
  /// into a passing assertion.
  List<String> textsIn(PatrolFinder finder) => $.tester
      .widgetList<Text>(
        find.descendant(
          of: finder.finder,
          matching: find.byType(Text),
          matchRoot: true,
        ),
      )
      .map((Text text) => text.data ?? '')
      .toList(growable: false);

  /// The text of a labelled row's value — the last `Text` under [finder].
  ///
  /// The totals rows render as `[label, value]`, so the value is the last one.
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'locator.dart';
import 'widget_probes.dart';

/// One element on screen, with the operations a test performs on it.
///
/// The vocabulary is deliberately the familiar one — click, type, clear,
/// isDisplayed, isEnabled — because that is what the team already knows from
/// WebDriver, and a wrapper that renames everything buys nothing.
///
/// Where the resemblance stops is on purpose. There is no `getAttribute` and
/// no `getCssValue`: Flutter paints on a canvas, there is no DOM to query,
/// and faking one would return strings to parse instead of the typed values
/// that are actually available. [widget] is the replacement, and it is the
/// better deal — `element.widget<ElevatedButton>().onPressed` breaks at compile
/// time when the widget changes, where `getAttribute("disabled")` would break
/// silently at run time, months later.
///
/// Named [UiElement] rather than `Element` because Flutter already owns that
/// name for the widget tree's nodes.
class UiElement {
  const UiElement(this.$, this.loc);

  final PatrolIntegrationTester $;

  /// How this element is found. Swapping the strategy is a one-line change in
  /// the page object; nothing here needs to know which one is in use.
  final Loc loc;

  /// Resolved on every access rather than cached: the tree is rebuilt
  /// constantly, and a finder held across a rebuild points at a corpse.
  PatrolFinder get finder => loc.resolve($);

  // --- Interaction ---------------------------------------------------------

  /// Taps the element. Patrol settles the tree afterwards.
  Future<void> click() => finder.tap();

  /// Types [text] into the element.
  ///
  /// Named `type` rather than `sendKeys` because it *replaces* the content
  /// instead of appending to it — which is what `enterText` does, and calling
  /// it `sendKeys` would promise the opposite.
  Future<void> type(String text) => finder.enterText(text);

  /// Empties the field.
  Future<void> clear() => finder.enterText('');

  /// Scrolls until the element is on screen.
  ///
  /// Pass [inside] when the element lives in a specific scrollable and the
  /// screen has more than one.
  Future<void> scrollTo({Loc? inside}) => finder.scrollTo(view: inside?.finder);

  // --- Reading -------------------------------------------------------------

  /// The visible text of the element, or of its last `Text` descendant.
  ///
  /// The fallback is what makes it work on both shapes a labelled row takes:
  /// a key on the `Text` itself, and a key on the row wrapping
  /// `[label, value]` — where the value is the last one.
  String get text {
    final List<String> found = texts;
    if (found.isEmpty) {
      throw StateError('No text under $loc — wrong locator?');
    }
    return found.last;
  }

  /// Every `Text` rendered by the element, in tree order.
  List<String> get texts => textsUnder($.tester, finder.finder);

  /// The widget itself, typed.
  ///
  /// This is what replaces `getAttribute` and `getCssValue`: read the real
  /// property off the real widget.
  ///
  /// ```dart
  /// element.widget<TextField>().obscureText     // instead of getAttribute("type")
  /// element.widget<Text>().style?.color          // instead of getCssValue("color")
  /// ```
  T widget<T extends Widget>() => $.tester.widget<T>(finder.finder);

  // --- State ---------------------------------------------------------------

  /// Whether the element is currently in the tree.
  bool get isDisplayed => finder.exists;

  /// Whether the element accepts interaction.
  ///
  /// "Enabled" lives on a different property for every widget, so it is read
  /// from [WidgetProbes] rather than guessed. An unregistered type **throws**
  /// instead of defaulting to `true`: a silent `true` would let an assertion
  /// pass on a premise nobody checked, which is the exact failure this layer
  /// exists to avoid.
  bool get isEnabled {
    final Widget target = widget<Widget>();
    final bool? enabled = WidgetProbes.readEnabled(target);
    if (enabled == null) {
      throw StateError(
        'There is no rule for whether ${target.runtimeType} is enabled '
        '($loc). Register one with '
        'WidgetProbes.enabled<${target.runtimeType}>(…), or state it here '
        'with isEnabledWhere<${target.runtimeType}>((w) => …).',
      );
    }
    return enabled;
  }

  /// Whether a selection control is on.
  ///
  /// Throws for a widget that has no notion of being selected, for the same
  /// reason as [isEnabled].
  bool get isSelected {
    final Widget target = widget<Widget>();
    final bool? selected = WidgetProbes.readSelected(target);
    if (selected == null) {
      throw StateError(
        '${target.runtimeType} exposes no selection state ($loc). '
        'Register one with WidgetProbes.selected<${target.runtimeType}>(…), '
        'or state it here with '
        'isSelectedWhere<${target.runtimeType}>((w) => …).',
      );
    }
    return selected;
  }

  /// States the enabled rule for a widget this layer does not know — a custom
  /// control, or `Radio`, whose selection depends on its type parameter.
  bool isEnabledWhere<T extends Widget>(bool Function(T widget) probe) =>
      probe(widget<T>());

  /// States the selection rule explicitly. The `Radio` case:
  ///
  /// ```dart
  /// option.isSelectedWhere<Radio<String>>((w) => w.groupValue == w.value);
  /// ```
  bool isSelectedWhere<T extends Widget>(bool Function(T widget) probe) =>
      probe(widget<T>());

  // --- Waiting -------------------------------------------------------------

  /// Waits until the element is on screen; fails the test on timeout.
  ///
  /// Flutter removes a whole class of waits that WebDriver needs: Patrol
  /// settles the tree after every interaction, so there is no polling for an
  /// animation to finish and no reason for a `sleep`.
  Future<void> waitVisible() => finder.waitUntilVisible();

  @override
  String toString() => '$loc';
}

/// Every `Text` under [finder], in tree order.
///
/// `matchRoot` is on because a key sits on the `Text` itself about as often
/// as it sits on the row wrapping it; without it the first case reads as
/// empty, which quietly turns a broken locator into a passing assertion.
List<String> textsUnder(WidgetTester tester, Finder finder) => tester
    .widgetList<Text>(
      find.descendant(of: finder, matching: find.byType(Text), matchRoot: true),
    )
    .map((Text text) => text.data ?? '')
    .toList(growable: false);

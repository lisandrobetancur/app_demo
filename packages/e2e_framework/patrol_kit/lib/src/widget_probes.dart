import 'package:flutter/material.dart';

/// How the kit learns what "enabled" and "selected" mean in *your* app.
///
/// There is no property every widget agrees on. A button is enabled when its
/// callback is not null; a text field has an `enabled` flag; a design system's
/// button may also be inert while it is loading, with the callback still in
/// place. A kit that hardcoded a list of types would work in exactly one
/// project — the one it was extracted from.
///
/// So the rule is registered rather than guessed. The kit ships the Flutter
/// built-ins; an app adds its own once, at launch:
///
/// ```dart
/// WidgetProbes.enabled<AppButton>((w) => w.onPressed != null && !w.isLoading);
/// WidgetProbes.selected<AppToggle>((w) => w.isOn);
/// ```
///
/// A later registration wins over an earlier one, so an app can override a
/// built-in whose default reading is wrong for its wrapper widgets.
///
/// A type nobody registered **throws** rather than defaulting to `true`. A
/// silent `true` would let an assertion pass on a premise nobody checked,
/// which is the failure this whole layer exists to avoid.
class WidgetProbes {
  const WidgetProbes._();

  static final List<_Rule> _enabled = <_Rule>[];
  static final List<_Rule> _selected = <_Rule>[];
  static bool _defaultsInstalled = false;

  /// States when a widget of type [T] counts as enabled.
  static void enabled<T extends Widget>(bool Function(T widget) probe) {
    _installDefaults();
    _enabled.insert(0, _ruleFor<T>(probe));
  }

  /// States when a widget of type [T] counts as selected.
  static void selected<T extends Widget>(bool Function(T widget) probe) {
    _installDefaults();
    _selected.insert(0, _ruleFor<T>(probe));
  }

  /// Forgets every registration, defaults included. For tests of the kit.
  static void reset() {
    _enabled.clear();
    _selected.clear();
    _defaultsInstalled = false;
  }

  /// Whether [widget] is enabled, or `null` when no rule covers its type.
  static bool? readEnabled(Widget widget) => _read(_enabled, widget);

  /// Whether [widget] is selected, or `null` when no rule covers its type.
  static bool? readSelected(Widget widget) => _read(_selected, widget);

  static bool? _read(List<_Rule> rules, Widget widget) {
    _installDefaults();
    for (final _Rule rule in rules) {
      if (rule.matches(widget)) {
        return rule.read(widget);
      }
    }
    return null;
  }

  /// The widgets Flutter ships, registered on first use.
  ///
  /// Installed lazily and only once, so an app's own registrations always land
  /// in front of these and take precedence.
  static void _installDefaults() {
    if (_defaultsInstalled) {
      return;
    }
    _defaultsInstalled = true;

    _enabled.addAll(<_Rule>[
      _ruleFor<ElevatedButton>((ElevatedButton w) => w.onPressed != null),
      _ruleFor<TextButton>((TextButton w) => w.onPressed != null),
      _ruleFor<OutlinedButton>((OutlinedButton w) => w.onPressed != null),
      _ruleFor<FilledButton>((FilledButton w) => w.onPressed != null),
      _ruleFor<IconButton>((IconButton w) => w.onPressed != null),
      _ruleFor<TextField>((TextField w) => w.enabled ?? true),
      _ruleFor<Checkbox>((Checkbox w) => w.onChanged != null),
      _ruleFor<Switch>((Switch w) => w.onChanged != null),
    ]);

    _selected.addAll(<_Rule>[
      // `value` is nullable on a tristate checkbox; an indeterminate box is
      // reported as not selected rather than as unknown.
      _ruleFor<Checkbox>((Checkbox w) => w.value ?? false),
      _ruleFor<Switch>((Switch w) => w.value),
      _ruleFor<CheckboxListTile>((CheckboxListTile w) => w.value ?? false),
      _ruleFor<SwitchListTile>((SwitchListTile w) => w.value),
    ]);
  }
}

/// One registered rule: which widgets it covers, and what it reads from them.
///
/// The match is `is T`, not a runtime-type equality, so it covers subclasses
/// and generic widgets like `Radio<String>` that an exact-type lookup would
/// miss.
@immutable
class _Rule {
  const _Rule(this.matches, this.read);

  final bool Function(Widget widget) matches;
  final bool Function(Widget widget) read;
}

/// Builds a rule for widgets of type [T].
///
/// A free function and not a constructor: Dart does not allow a constructor to
/// declare its own type parameters, and the rule needs [T] to close over the
/// `is`/`as` pair.
_Rule _ruleFor<T extends Widget>(bool Function(T widget) probe) =>
    _Rule((Widget w) => w is T, (Widget w) => probe(w as T));

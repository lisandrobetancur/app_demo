# patrol_kit

Reusable Patrol E2E scaffolding for Flutter apps: declarative locators, an
element API, soft assertions and Allure reporting.

Depends on Flutter and Patrol and on **nothing else** — no design system, no
app package, no project constants. That is the property the whole package
exists to preserve; a change that breaks it makes the kit reusable in exactly
one project.

## What a project supplies

| The kit brings | You bring |
|---|---|
| `BasePage`, `Loc`, `UiElement` | Your page objects |
| `BaseSteps`, `should`, `seeThat` | Your steps |
| `AssertD`, the report markers, `Money` | Your launcher and your seed data |
| Probes for Flutter's own widgets | One registration for your design system |

## Getting started

```yaml
dev_dependencies:
  patrol_kit: 0.1.0
```

**1. Teach it your widgets.** There is no property every widget agrees on, so
the rule is registered rather than guessed. Call this once, from your launcher:

```dart
WidgetProbes.enabled<AppButton>((w) => w.onPressed != null && !w.isLoading);
WidgetProbes.enabled<AppTextField>((w) => w.enabled);
```

A type nobody registered throws rather than defaulting to `true` — a silent
`true` would let an assertion pass on a premise nobody checked.

**2. Write a page.** Locators are declared in one block, one strategy per
element, and each can change on its own:

```dart
class LoginPage extends BasePage {
  static final Loc _view   = Loc.key('login_view');
  static final Loc _submit = Loc.text('Iniciar sesión');   // sin keys todavía

  @override
  PatrolFinder get root => _view.resolve($);

  UiElement get submitButton => element(_submit);
  Future<void> submit() => submitButton.click();
}
```

**3. Write a step.** `step()` delimits what the report shows, captures the
screen it left behind, and raises whatever the assertions collected:

```dart
class AuthSteps extends BaseSteps {
  Future<void> expectLoginRejected() =>
      step('Expect the login to be rejected', () async {
        should(
          seeThat('sigue en login',        () => _login.isVisible,     isTrue),
          seeThat('no llegó al dashboard', () => _dashboard.isVisible, isFalse),
        );
      });
}
```

Expectations written in **one call** are one claim and are checked whole — the
second runs even when the first fails. Written in **separate calls**, each is a
precondition for the next. Grouping is the only thing that decides it.

## The report

The kit prints markers to stdout as the suite runs; a converter turns them into
Allure results. Nothing here writes files or touches the network.

| Marker | From | Becomes |
|---|---|---|
| `PATROL_STEP` | `BaseSteps.step` | A business step, with Patrol's interactions nested under it |
| `PATROL_ASSERT` | `reportAssertion` | A leaf carrying `expected` / `actual` |
| `PATROL_SHOT` | `takeScreenshot` | An attachment on the step that produced it |
| `PATROL_META` / `PATROL_PARAM` | `scenario()` / `testParam()` | Labels, description and case data |

A step that ends badly is reported as **failed** or **broken**, never just red:
a `TestFailure` means the product misbehaved; anything else means the test could
not check at all. It is the distinction WebDriver suites live by — an assertion
failure versus a `NoSuchElementException`.

## Screenshots

Patrol ships no capture on web, so the kit rasterises a `RepaintBoundary` the
launcher wraps around the app and streams it as base64 in 800-character chunks —
a single long line gets mangled on the way out of the browser. Turn it off with
`--dart-define=E2E_SCREENSHOTS=false`.

## Locale

`Money.parse` reads prices back off the screen, and separators are
locale-dependent. It assumes the `es` convention (`.` groups, `,` decimals) and
is documented as such; pin the locale of your run so local and CI agree.

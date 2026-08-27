---
name: e2e-nuevo-escenario
description: Write or change an E2E scenario in this repo's Patrol suite. Use whenever the task is to add a test case, cover a user flow end to end, extend a page object or business step, or touch anything under packages/apps/market_app/patrol_test/. Carries the four layers, the report vocabulary, and the traps that make an E2E test pass while verifying nothing.
---

# Writing an E2E scenario

The suite lives in `packages/apps/market_app/patrol_test/`. It runs on three
platforms from one source, and everything it prints is read twice: once by
Patrol, and once by the report generator in
`packages/e2e_framework/e2e_test_reporter`. That second reader is why the
conventions below are not style.

Start by reading `scenarios/login_test.dart` end to end. It is the shortest
complete example of everything here.

## The four layers

```
scenarios/   WHAT is verified. One e2eTest per case. Spanish.
steps/       Business steps: perform and assert. Data arrives as parameters.
pages/       One screen each: locators and interactions. No assertions.
support/     Features, Epics, TestData, launchMarketApp.
```

The direction is one-way. A scenario calls steps; a step calls pages; a page
touches widgets. A page never asserts a business rule and never navigates
between screens — it may chain **its own** interactions (`LoginPage.login()`
fills and submits), which is the one relaxation of that rule.

### The page

```dart
class LoginPage extends BasePage {
  const LoginPage(super.$);

  static final Loc _view = Loc.widgetKey(LoginKeys.view);
  static final Loc _emailInput = Loc.widgetKey(LoginKeys.emailInput);

  @override
  PatrolFinder get root => _view.resolve($);

  UiElement get emailInput => element(_emailInput);

  Future<void> enterEmail(String email) => emailInput.type(email);
}
```

Locators are declared in one block at the top, one strategy per element, so a
locator can change strategy on its own. Prefer `Loc.widgetKey` against the keys
the feature already declares (`LoginKeys.emailInput`) — a rename then breaks at
compile time. `Loc.text` works but moves with the language, and this app is
localized. Other constructors: `.key`, `.semantics`, `.semanticsLabel`,
`.textContaining`, `.type`, `.icon`, `.custom`, refined with `.at(n)`,
`.first`, `.last`, `.within(other)`, `.containing(other)`.

### The step

```dart
Future<void> expectLoggedInAs(String fullName) =>
    step('El dashboard recibe a $fullName', () async {
      await _dashboard.waitUntilVisible();
      should(
        seeThat(
          'En el dashboard se saluda por su nombre al usuario',
          () => _dashboard.greetingText,
          contains(fullName),
        ),
      );
    });
```

Every step is wrapped in `step('name', body)` — the name becomes a node in the
report tree. Performing and asserting are separate steps when the same action
has two possible futures: `login()` is followed by `expectLoggedInAs()` in one
scenario and `expectLoginRejected()` in another, and that difference belongs to
the scenario, not to the step.

### The scenario

```dart
e2eTest(
  'Intento de inicio de sesión con contraseña incorrecta',
  tags: <String>[Tags.smoke, Tags.negative],
  (PatrolIntegrationTester $) async {
    scenario(
      feature: Features.authentication,
      severity: Severity.critical,
      description:
          'Una contraseña que no es la del usuario debe ser rechazada con '
          'el error genérico, sin revelar cuál de los dos campos falló.',
    );

    await launchMarketApp($);              // ← the app, THEN the data
    final Steps steps = Steps($);

    final DataRecord data = TestData.invalidLogin('wrongPassword');
    testParam('Usuario', data.string('email'));

    await steps.auth.login(
      email: data.string('email'),
      password: data.string('password'),
    );
    await steps.auth.expectLoginRejected();
    await steps.auth.expectGenericCredentialsError();
  },
);
```

## Vocabulary

All of it is closed — pick from the catalogue, do not invent a string.

| what | where | values |
|---|---|---|
| `Features` | `support/features.dart` | `authentication`, `catalog`, `checkout`, `coupons` |
| `Epics` | `support/epics.dart` | carried by the feature; only override for a genuine exception |
| `Severity` | kit | `blocker`, `critical`, `normal` (default), `minor`, `trivial` |
| `Tags` | kit | `Tags.smoke` (`'smoke_test'`), `regression`, `success`, `negative`, `wip` |

Note `Tags.smoke`, whose value is `smoke_test`. Adding a feature means adding a
`Feature` constant, not a literal at the call site — the report groups by it.

`Tags.wip` is the only tag `e2eTest` acts on by itself: the test registers as
skipped, so it reaches the report as a visible debt instead of disappearing.
`melos run e2eWebWip` compiles those tests without the skip.

## Data

`TestData` is a typed façade over `patrol_test/data/*.json`. Read named
records, never positional rows — `TestData.invalidLogin('wrongPassword')` still
reads its case after somebody inserts a fourth one above it.

The scenario reads the data and passes it down. A step that reaches into
`TestData` itself hides half the case from the file that defines it.

Adding a field means editing the JSON, adding a getter to `TestData`, and
extending `test/patrol_guards/data_wiring_test.dart`.

## Screenshots

No frame is taken unless the step asks for one. The default is
`Capture.onFailure`: a failing assertion photographs itself at the instant it
failed, captioned `step · failed · 14:32:07.481` — `failed` when the product is
wrong, `broken` when the test could not tell.

```dart
await shot();                      // one frame, captioned with step and time
await shot('El carrito con el cupón aplicado');
await capturing(                   // the moment that vanishes
  _login.submit,
  before: 'Las credenciales digitadas, antes de enviar',
  after: 'Lo que produjo el envío',
);
```

Name them wherever a step takes more than one: two unnamed frames of the same
step differ only by milliseconds, and a reader has to open both.

## Assertions

`should(seeThat(...))` is the only way a step asserts.

```dart
should(
  seeThat('El subtotal suma los productos', () => cart.subtotal, equals(expected)),
  seeThat('El total aplica el impuesto', () => cart.total, equals(withTax)),
);
```

Expectations written in **one call** are one claim: all of them are evaluated
and the failures are raised together, so the report shows both. Split into
separate calls, each becomes a precondition for the next. One expectation alone
behaves exactly like a plain `expect`.

Also available: `seeThatIsPresent`, `seeThatIsVisible`, `seeThatIsAbsent`,
which assert through the finder so a failure names the widget instead of
reporting `false`.

**A scenario with no `should` verifies nothing.** It will pass. The report will
show its steps and no assertions, and `assertion_summary` will flag it. That is
not a formality — a suite that only acts is green against a dead app.

## Traps

Each of these has already cost a build.

1. **`TestData` before `launchMarketApp($)`.** The data is in the asset bundle
   and the bundle does not exist until the app launches. The natural writing
   order — metadata, params, launch — is exactly the mistake. Guarded by
   `test_order_test.dart`, which reads the source rather than running it.
2. **A password in a step name.** Names are published: marker stream → HTML
   report → CI artifact → GitHub Pages. Write the email, never the password.
   `login()` obscures the field on screen; the name is the other half.
3. **Asserting only the negative side.** A disabled submit button is also what
   a dead app shows. `expectSubmitDisabledFor` exists next to
   `expectSubmitEnabledFor` for that reason: without the contrast the test
   cannot tell "validation works" from "nothing arrived".
4. **A tag that is not in `Tags`.** Filtering happens while the bundle is
   generated, so a filter naming an unknown tag selects nothing and the run
   reports zero tests — green, and empty.
5. **Reading a positional row.** `.rows[2]` re-points itself the day somebody
   inserts a row above it. Use `.record('key')`.
6. **Running `dart format` from the root.** Run it from inside the package:
   `cd packages/... && dart format . --line-length 80`.
7. **Assuming a screenshot names itself well.** `Capture.auto` used to
   photograph the *destination* of a navigating step, which is why captures are
   manual now.

## Before you call it done

```sh
melos run lint
melos run testFast      # includes the two guards under test/patrol_guards/
melos run e2eWeb        # ~1 min; the report is built as part of running
melos run openReportWeb
```

Open the report and check three things: the scenario appears under the right
feature, its steps read as sentences a non-author understands, and its
assertions are counted. A scenario in the report with zero assertions is not
finished.

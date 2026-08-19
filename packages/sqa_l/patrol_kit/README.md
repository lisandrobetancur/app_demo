# patrol_kit

Reusable Patrol E2E scaffolding for Flutter apps: declarative locators, an
element API, soft assertions and the report markers.

Depends on Flutter and Patrol and on **nothing else** — no design system, no
app package, no project constants. That is the property the whole package
exists to preserve; a change that breaks it makes the kit reusable in exactly
one project.

## What a project supplies

| The kit brings | You bring |
|---|---|
| `BasePage`, `Loc`, `UiElement` | Your page objects |
| `BaseSteps`, `should`, `seeThat` | Your steps |
| `AssertD`, the report markers, `Money` | Your launcher |
| `e2eTest`, `Tags`, `Log` | Which tags each test carries |
| `TestDataStore`, the JSON reader | Your `data/` folder |
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
  static final Loc _submit = Loc.text('Sign in');   // no keys yet

  @override
  PatrolFinder get root => _view.resolve($);

  UiElement get submitButton => element(_submit);
  Future<void> submit() => submitButton.click();
}
```

**3. Point it at your data.** Test data lives in JSON, with one parent file
listing the rest, so adding a data set is a line in one place:

```json
// patrol_test/data/index.json
{ "version": 1, "datasets": { "users": "users.json", "coupons": "coupons.json" } }
```

Declare the folder under `flutter: assets:` and load it once, in the launcher:

```dart
await TestDataStore.load();
final DataRecord ana = TestDataStore.dataset('users').record('demo');
ana.string('email');       // "ana@market.demo"
ana.integer('publications');
```

**4. Write a step.** `step()` delimits what the report shows, captures the
screen it left behind, and raises whatever the assertions collected:

```dart
class AuthSteps extends BaseSteps {
  Future<void> expectLoginRejected() =>
      step('Expect the login to be rejected', () async {
        should(
          seeThat('sigue en login',        () => _login.isVisible,     isTrue),
          seeThat('did not reach the dashboard', () => _dashboard.isVisible, isFalse),
        );
      });
}
```

Expectations written in **one call** are one claim and are checked whole — the
second runs even when the first fails. Written in **separate calls**, each is a
precondition for the next. Grouping is the only thing that decides it.

## Tags

`e2eTest` wraps `patrolTest` so a tag is declared once and reaches both places
that need it — the runner and the report:

```dart
e2eTest(
  'rejects invalid credentials',
  tags: <String>[Tags.smoke, Tags.negative],
  ($) async { … },
);
```

```sh
patrol test --device chrome --tags "smoke_test && negative"
patrol test --device chrome --exclude-tags "slow"
```

The filter is applied while the test bundle is generated, so an excluded test
is never built into the binary — not built and then skipped. The vocabulary
lives in `Tags` rather than in each test file, because a filter that names a
tag nobody uses does not fail: it selects nothing and reports a green run of
zero tests.

## The run log

`Log` is the trail that explains *how* the test got where it got, as distinct
from the assertions, which are verdicts on the product.

```dart
Log.info('Comprando como ${user.email}');
Log.debug('Carrito', data: <String, Object>{'items': 3});
Log.warn('The coupon was already applied');
```

Everything lands in a `run.log` attachment on the test; `warn` and `error`
*also* become rows in the step tree, because a warning nobody opens the
attachment to read is a warning that did not happen. The threshold is a flag,
not an edit: `--dart-define=E2E_LOG_LEVEL=debug`. Default is `info`.

## Test data

Reading files needs saying why it works the way it does. A Patrol test is
compiled **into** the application binary and runs where the app runs — a
browser tab on web, the device on Android and iOS. There is no `dart:io` on
web and no repository checkout on a phone, so reading from disk would work on
one of the three platforms. Flutter assets resolve the same way on all of
them, which is why the default source goes through `rootBundle`.

Two file shapes are accepted, because both are what data looks like:

```json
// users.json — keyed records, read by name
{ "demo": { "email": "ana@market.demo", "publications": 5 } }

// invalid_logins.json — rows, looped over by a data-driven test
[ { "case": "wrong password", "email": "…", "password": "…" } ]
```

Reads are typed and every failure names the field, the record and the file:

```dart
users.record('demo').string('email');
users.record('demo').integer('publications');
```

They throw `TestDataError`, never `TestFailure` — so a field nobody wrote
reports the step as **broken**, not failed. Data you cannot read is the test
being unable to check, which is not the same as the product being wrong.

**One caveat worth knowing before this reaches an app that ships.** An asset
declared by the app under test travels in *every* build of it, release
included — test fixtures, and any credentials in them, inside the production
binary. `TestDataSource` is an interface for that reason: point the store at
an `InMemoryTestDataSource` fed by a generator and the same API reads data
that was compiled in, with nothing added to the asset manifest.

## The report

The kit prints markers to stdout as the suite runs; SQA Reporter turns them
into a report. Nothing here writes files or touches the network.

| Marker | From | Becomes |
|---|---|---|
| `PATROL_STEP` | `BaseSteps.step` | A business step, with Patrol's interactions nested under it |
| `PATROL_ASSERT` | `reportAssertion` | A leaf carrying `expected` / `actual` |
| `PATROL_SHOT` | `takeScreenshot` | An attachment on the step that produced it |
| `PATROL_META` / `PATROL_PARAM` | `scenario()` / `testParam()` | Labels, description and case data |
| `PATROL_TAGS` | `e2eTest(tags:)` | The test's tags, and a page per tag |
| `PATROL_TRACE` | `Log.*` | The `run.log` attachment, plus rows for `warn`/`error` |

A step that ends badly is reported as **failed** or **broken**, never just red:
a `TestFailure` means the product misbehaved; anything else means the test could
not check at all. It is the distinction WebDriver suites live by — an assertion
failure versus a `NoSuchElementException`.

## Screenshots

Patrol ships no capture on web, so the kit rasterises a `RepaintBoundary` the
launcher wraps around the app and streams it as base64 in 800-character chunks —
a single long line gets mangled on the way out of the browser. Turn it off with
`--dart-define=E2E_SCREENSHOTS=false`.

Every step captures its end state, and that default is the right one: the
picture nobody thought to ask for is the one wanted at three in the morning
when a step failed on CI. Two things override it.

**`capture:` decides whether the automatic frame is taken**, per step:

| | Passed | Broke |
|---|---|---|
| `Capture.auto` (default) | frame | frame |
| `Capture.onFailure` | — | frame |
| `Capture.none` | — | — |

**`shot(name)` takes one whenever you want**, which is how you capture a moment
*inside* a step rather than at its end — the dialog before it is dismissed, the
list before the filter is applied:

```dart
await step('Apply the coupon', capture: Capture.none, () async {
  await cart.openCouponField();
  await shot('coupon field, before typing');
  await cart.applyCoupon(TestData.validCoupon);
  await shot('coupon applied');
});
```

A step can take as many as it likes, with or without its automatic one. They
hang off that step in the report, in the order the calls ran, and the gallery
walks them in the same order. Neither ever fails a test: a missing screenshot
is a worse report, not a wrong result.

## Locale

`Money.parse` reads prices back off the screen, and separators are
locale-dependent. It assumes the `es` convention (`.` groups, `,` decimals) and
is documented as such; pin the locale of your run so local and CI agree.

# Market — local marketplace for light vehicles

A reference Flutter monorepo: a marketplace where the same person buys and sells
(cars, motorcycles, scooters, bicycles and trucks). **No backend**: everything
lives in local SQLite and survives app restarts on Android, iOS and Web.

The repository *is* the deliverable: decoupled micro-features, a strict
dependency direction, immutable state, dependency injection by provider
overrides, complete i18n and aggressive linting. Adding a new feature should be
a matter of copying the structure of an existing one.

---

## Quick start

```bash
dart pub global activate melos 7.3.0
melos bs
melos run lint
```

```bash
cd packages/apps/market_app
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

Demo users (password `Demo1234`):

| Email | Role in the seed |
|---|---|
| `ana@market.demo` | 5 publications, 2 addresses, 1 delivered order |
| `bruno@market.demo` | 10 publications |

---

## Stack

| Tool | Version |
|---|---|
| Flutter | `3.41.9` (stable) |
| Dart SDK | `^3.11.5` |
| Melos | `7.3.0` |

Every third-party dependency is **pinned without a caret** in each
`pubspec.yaml` (full reproducibility). The three the spec left open were
resolved with `flutter pub add` and pinned as follows:

| Package | Version | Note |
|---|---|---|
| `easy_localization` | `3.0.8` | latest stable of the 3.x line |
| `go_router` | `17.3.0` | latest compatible stable |
| `sqflite_common_ffi_web` | `1.1.1` | 1.1.2 requires Flutter 3.44+, incompatible with 3.41.9 |

Only one dependency was added outside the list: **`flutter_web_plugins`** (a
Flutter SDK package, not a third party) to enable real paths on the web — see
[Deep links](#deep-links).

---

## Package map

```
packages/
├── apps/market_app/                 shell: wiring only (router, DI, i18n, bootstrap)
├── development/lint/                shared analysis_options
├── shared/                          pure logic, ZERO widgets
│   ├── typing/                      base ViewModel, Clock, IdGenerator, ViewStatus
│   ├── database/                    connection, schema, migrations, seed, base DAO
│   ├── navigator/                   AppRoute, NavigationManager, BootstrapGate, deep links
│   └── utilities/                   formatters, validators, logger, guards, ImageStorage
├── ui/
│   ├── design_system/               tokens + light/dark themes + primitives
│   └── components/packages/         product_card, quantity_stepper, rating_stars,
│                                    price_tag, filter_chip_bar, status_badge,
│                                    stepper_header, empty_state
└── features/
    ├── generic/                     app_cross, authentication, dashboard, profile
    └── core/                        catalog, cart, orders
```

Every feature is three packages:

| Sub-package | Contents | Depends on |
|---|---|---|
| `constants` | widget keys, routes, limits | nothing |
| `typing` | public contract: models, enums, interfaces, unimplemented providers | `constants` |
| `module` | private implementation: DAO, service, state, UI | `constants`, `typing` |

### Dependency direction

```
apps  →  features  →  shared
 │         │            ↑
 │         └────→  ui ──┘
 └──────────────────────┘
```

- `features/` imports from `shared/`, `ui/` and from the **`typing/` of other
  features** — never from their `module/`.
- `shared/` and `ui/` never import from `features/` or `apps/`.
- `design_system` depends on no internal package.
- Cross-feature navigation uses routes (strings) or the other feature's
  `typing/`, never its module.

---

## Architecture

### State (Riverpod 2.6.1)

Each sub-state is **a single library** with its `part`s in alphabetical order:

```dart
library com.demo.market.catalog.core.state.list;
part 'controller.dart';
part 'provider.dart';
part 'state.dart';
```

State is a flat immutable class (`copyWith`, `==`, `hashCode`, `toString`)
written by hand: no `freezed`, so the example reads without codegen. It is never
mutated in place; always `state = state.copyWith(...)`.

Controllers extend `ViewModel<T>` (in `shared/typing`), which provides:

- `postInit()` — **synchronous**, resolves dependencies (`service`,
  `navigatorNotifier`) before anyone can call the controller.
- `runPostBuild(action)` — kicks off the initial load on the next microtask.
  Riverpod forbids writing `state` while `build()` is running, and calling the
  load inline would leave `late` fields unassigned if a view invokes a method
  immediately (a real bug that surfaced when opening a deep link).
- `mountedKey` — a token captured before an `await` to detect mid-flight
  disposal.

### Dependency injection

The service provider is **declared** in `typing/` throwing
`UnimplementedError` and **overridden** in `module/core/service/provider.dart`.
The shell collects every override in `lib/di/app_overrides.dart`; that is the
only place where infrastructure and features know about each other.

### Data

`DAO → Service → Controller → View`. The DAO speaks raw SQL and returns
`Map<String, Object?>`; the service converts rows ↔ models and applies business
rules; the controller orchestrates and handles errors. **No view runs SQL.**

Every multi-table write happens inside a `transaction`. The two critical cases:

- **Checkout**: creates `orders` + `order_items` (with a name and price
  snapshot), decrements stock, empties the cart and writes the notification —
  all or nothing.
- **Cancel order**: changes the status, restores stock and notifies, in a single
  transaction.

Passwords are stored as `sha256(salt + password)` with a per-user salt. In
production this would be a cost-based KDF (bcrypt/argon2) plus secure storage;
that caveat is documented in `PasswordHasher`.

The text of `notifications` is stored as **i18n keys** with their arguments in
the JSON `payload`, never as already-translated text.

---

## Cross-platform

Native differences are resolved behind an abstraction and documented in a single
file per topic:

| Topic | File | Android / iOS | Web |
|---|---|---|---|
| Database | `shared/database/.../database_factory_resolver.dart` | `sqflite` + `getDatabasesPath()` | `sqflite_common_ffi_web` (wasm + IndexedDB) |
| Images | `shared/utilities/.../image_storage.dart` | file copied into the app directory, the path is stored | base64 data URI in the row itself |
| URLs | `shared/utilities/.../url_strategy.dart` | not applicable (`market://` scheme) | `usePathUrlStrategy()` for real paths |
| Guards | `shared/utilities/.../platform_guard.dart` | — | — |

`dart:io` only appears behind a conditional import; no feature touches it.

Platform configuration: Android `minSdk 23` and an intent-filter for `market://`;
iOS deployment target `13.0`, `CFBundleURLTypes` and gallery/camera permissions
with Spanish copy. The web wasm assets (`sqlite3.wasm`, `sqflite_sw.js`) are
generated with:

```bash
dart run sqflite_common_ffi_web:setup
```

### Layout

The same controller serves mobile and web; only the presentation layer changes.
`AppScaffold` provides SafeArea, padding and a 1200 px max width. The navigation
shell uses a bottom bar below 768 px and a side rail above it, preserving each
tab's state with `StatefulShellRoute.indexedStack`.

---

## Deep links

The scheme is `market://` and routes are named, with path parameters (never
business data in query strings).

```bash
# Web (the host must serve index.html for unknown routes)
open http://localhost:8080/catalog/detail/product_car_001

# Android
adb shell am start -a android.intent.action.VIEW \
  -d "market://catalog/detail/product_car_001" com.demo.market_app

# iOS
xcrun simctl openurl booted "market://catalog/detail/product_car_001"
```

Two pieces make this work:

1. **`usePathUrlStrategy()`** on the web. Flutter defaults to hash URLs
   (`/#/catalog`), so the path never reached the router.
2. **`BootstrapGate`** (`shared/navigator`). On a cold start the router is
   evaluated before the database and the session exist, so the session redirect
   would take the deep link to login and lose it. The gate parks the requested
   location, sends the user through the splash, and the splash (or the login
   that follows it) resumes it once bootstrap finishes.

A route to a nonexistent resource shows the not-found view
(`shell_not_found_view`) or the view's `empty` state — never a blank screen.

---

## Boot flags

```bash
flutter run -d chrome --dart-define=SEED_MODE=empty
flutter run -d chrome --dart-define=FAST_ANIMATIONS=true
```

| Flag | Values | Effect |
|---|---|---|
| `SEED_MODE` | `demo` (default) / `empty` | database with deterministic seed data, or an empty database to walk through every empty state |
| `FAST_ANIMATIONS` | `true` / absent | every `AppDurations` value collapses to `Duration.zero` |

They are read in a single file (`lib/config/app_config.dart`) and propagated
through overrides.

---

## Determinism

1. **Fixed seed**: literal ids (`user_demo_001`, `cat_car`,
   `product_car_001`…), constant prices and dates. 2 users, 5 categories,
   15 products, 3 coupons (`DEMO10` valid, `PAST20` expired, `FROZEN15`
   inactive), 2 addresses and 1 historical delivered order.
2. **Injected clock**: `Clock` + `clockProvider`. `DateTime.now()` is only named
   inside that provider.
3. **Injected ids**: `IdGenerator` behind a provider (`UuidIdGenerator` by
   default), replaceable with a sequential one.
4. **Stable ordering**: every `SELECT` feeding a list carries an explicit
   `ORDER BY` with an `id` tie-breaker.
5. **No hidden work**: no periodic timers or infinite animations; shimmers only
   exist while a view is in its `loading` state.
6. **Reset from the app**: Settings offers "reset demo data" (`resetToSeed`) and
   "delete all my data" (`wipe`), both behind a confirmation.

---

## Widget identifiers

Keys are **contract, not label**: they do not depend on language, theme or
platform, and they do not change when the copy changes. They are declared in
each feature's `constants/` and views reference them by constant.

```
<feature>_<view>_view        root of the view
<element>_<type>             concrete element
<element>_item_<id>          dynamic item (entity id, never the list index)
<view>_state_<state>         root of loading / data / empty / error
```

Elements that carry meaning for the user also get a translated
`Semantics(label:)`.

---

## Internationalization

`easy_localization` with `es` (default) and `en`, both complete. Each feature
declares its map in `module/lib/ui/languages.dart` and the shell merges them in
`MarketTranslationsLoader` — translations live in code, not in JSON assets. Key
convention: `feature.screen.element`, at least three levels.

Switching the language in Settings updates the whole app without a restart and
does not alter any `Key`.

---

## Melos commands

```bash
melos bs                    # bootstrap
melos clean && melos bs     # clean start
melos run lint              # flutter analyze --no-fatal-infos
melos run dartFormat        # dart format . --line-length 80
melos run dartFix           # dart fix --apply
melos run pubGet
melos run rmlock
melos run rmOverrides
melos run e2eWeb            # end-to-end suite
melos run allureReport      # convert the last run and build the report
melos run allureServe       # open it
```

> Melos 7 reads its configuration from the workspace root `pubspec.yaml`; the
> standalone `melos.yaml` of earlier versions is no longer picked up.

---

## Implemented flows

All 16 catalogued flows are implemented: F01 splash · F02 onboarding ·
F03 sign-up · F04 login and session · F05 password recovery · F06 dashboard ·
F07 catalog with search, filters and infinite scroll · F08 product detail ·
F09 publish product · F10 my publications · F11 cart with coupons ·
F12 multi-step checkout · F13 orders with status timeline, cancellation and
re-order · F14 favorites · F15 reviews · F16 profile, addresses, notifications
and settings.

> The app's UI ships in Spanish by default (with a complete English
> translation), so the screenshots and demo copy you will see are in Spanish.

---

## End-to-end tests (Patrol, web)

[Patrol](https://patrol.leancode.co) drives the real app. On the web it does
not use UIAutomator/XCUITest as on mobile: it serves the app with
`flutter run -d web-server` and drives Chromium through **Playwright**, so
Node.js is required (the first run installs Playwright and its browsers
automatically).

```bash
dart pub global activate patrol_cli 4.4.0
```

```bash
melos run e2eWeb
```

That runs the whole suite headless with three reporters, each for a different
reader:

| Reporter | For whom | Output |
|---|---|---|
| `list` | the terminal | live progress |
| `json` | the Allure converter | `playwright-report/results.json` |
| `junit` | CI | `playwright-report/results.xml` — GitLab, Jenkins and Azure turn it into a test tab, which a static Allure site cannot do |

Patrol only accepts that whitelist, so no third-party reporter can be plugged
in — which is why Allure is fed by a converter instead.

`json` is not optional here, and not only for its metadata: Playwright's
per-test stdout capture is the **only channel** that carries the screenshot
markers out of the browser. `patrol_cli` parses `PATROL_LOG` lines and reprints
them formatted, and drops everything else — so its own stdout contains none of
them.

There is deliberately **no video**. The evidence is one screenshot per business
step, which is the only model that behaves identically on web, Android and iOS;
adding video would give the web report something no mobile run could match.

To watch it in a real browser, or to run a single file:

```bash
cd packages/apps/market_app && patrol test --device chrome
```

```bash
cd packages/apps/market_app && patrol test --device chrome --target patrol_test/login_test.dart --web-headless=true
```

### What the suite covers

| Test | What it proves |
|---|---|
| `login_test` · signs in with the seeded demo account | the session reaches the dashboard and it greets the right user |
| `login_test` · rejects wrong credentials | the error is the generic one — the app never reveals whether an email exists |
| `login_test` · keeps submission blocked | live validation disables the CTA until the form is valid |
| `purchase_flow_test` · buys and confirms an order | the critical path end to end: catalog → detail → cart → coupon → three-step checkout → order |
| `purchase_flow_test` · own publication | a product you own offers seller actions instead of the purchase CTA |
| `purchase_flow_test` · expired coupon | the coupon error is the specific one, not a generic failure |

Last verified run: **6 passed, 0 failed, 0 flaky in 55 s** on Chromium.

### Three layers

```
patrol_test/
├── support/     app launcher, fixed data mirroring the seed, takeScreenshot
├── pages/       Page Objects: locators and atomic interactions
├── steps/       business language composing pages, with its assertions
└── *_test.dart  specs that read as sentences
```

The rule that keeps the layers honest: **a page knows where things are, a step
knows what a person does, a test knows what the product promises.** A locator
never leaves `pages/`, and a page never asserts a business rule.

Locators are not string literals: they are the very `Key` constants the app
declares in each feature's `constants/` package, so renaming a key breaks the
tests at compile time instead of at run time.

### Determinism

`launchMarketApp()` mirrors `lib/main.dart` but forces the three things a
repeatable test needs: its own database file (reset to the seed before the
first frame — IndexedDB survives between runs on the web), cleared preferences
(no remembered session), and `AppDurations.fastMode`, so `pumpAndSettle` never
waits on a shimmer.

### Version pinning

`patrol` is pinned to **4.6.1**, not the latest 4.9.0: from 4.7.0 onwards it
requires `equatable ^2.1.0`, which would break the `equatable: 2.0.7` pin this
workspace mandates. `patrol_cli` must match — the CLI refuses to run on a
mismatch — so use **4.4.0**, per the
[compatibility table](https://patrol.leancode.co/documentation/compatibility-table).

### Allure report

```bash
melos run e2eWeb        # runs the suite, emitting Playwright JSON
```

```bash
melos run allureReport  # converts that JSON and builds allure-report/
```

```bash
melos run allureServe   # opens the report in a browser
```

Why a converter (`tool/allure/patrol_to_allure.mjs`) instead of the usual
`allure-playwright` reporter: Patrol owns the Playwright config that runs the
web suite, and its `mapReporters` accepts only a whitelist — `html`, `json`,
`junit`, `list`, `dot`, `line`, `github`, `null` — and throws on anything else.
So the pipeline uses the supported `json` reporter and translates it.

The translation is not a straight copy. Patrol prints a structured
`PATROL_LOG {…}` line for every interaction, so each `tap`, `enterText` and
`waitUntilVisible` becomes a real Allure **step** with its own duration, and a
step still open when a test dies is marked `broken` — which is usually the one
that actually failed. Tests are grouped by the Dart file they came from
(`login_test`, `purchase_flow_test`) under a `Patrol web E2E` parent suite.

Allure 3 is used through its npm package, so **no Java is required**. The
converter has no dependencies beyond Node itself.

Two traps worth knowing: Allure 3's CLI has no `--clean`, and generating into
a directory that already holds a report **nests the new one under `awesome/`**
instead of replacing it — so the scripts delete the output first, otherwise you
end up reading a stale report.

### What carries over to mobile

The suite is written against Flutter, not against a browser, so most of it is
platform-agnostic — but the *reporting pipeline* is not, and it is worth being
precise about where the line falls.

| Piece | Android / iOS | Why |
|---|---|---|
| Tests, steps, pages | reused as-is | plain Dart on top of widget `Key`s |
| `takeScreenshot` | works | `RepaintBoundary.toImage()` is Flutter, not `dart:html` |
| `PATROL_STEP` / `PATROL_SHOT` markers | emitted | they are Dart prints; they surface through logcat and `os_log` |
| Allure report format | same | Allure does not care what produced the results |
| **The converter's input** | **missing** | its source is `playwright-report/results.json`, and there is no Playwright on mobile |
| `--web-reporter`, `--web-*` | not available | every one of those flags is consumed by the Playwright config |

What `patrol test` leaves behind instead is platform-native: Gradle's HTML and
JUnit report under `build/app/reports/androidTests/connected/` on Android, and
an `.xcresult` bundle under `build/` on iOS. Neither carries our business steps
or screenshots.

The reusable part is bigger than it looks, though. `patrol_cli` reads the same
`PATROL_LOG` protocol on all three platforms — `PatrolLogReader` just has a
different line parser for Flutter-on-Android, Flutter-on-iOS, release-mode iOS
and Playwright. And a `TestEntry` carries a test's name, status, start and end
timestamps and error message: every field the converter takes from Playwright
today. So extending this pipeline to mobile means writing a **second input
adapter** over that stream; `stepsFrom()` — the part that builds the step tree,
reassembles the screenshots and decides what is `broken` — is already
platform-neutral and would be reused unchanged.

The trap to know before attempting it: the markers must be read from the
device log (`adb logcat`, `os_log`), **not** from `patrol test`'s stdout. The
CLI consumes `PATROL_LOG` and reprints it formatted, and silently drops every
other line — including ours. On web they survive only because Playwright
captures the browser console per test. Android's logcat is also a ring buffer
that drops lines under load, so a run there wants `adb logcat -G 16M`; the
converter already skips a screenshot whose chunks are incomplete rather than
failing the report.

### A screenshot per business step

The report is organised the way the suite is: **business steps at the top,
Patrol's raw interactions nested underneath, and one screenshot per step.**

```
1  Log in as the demo user                              [image]
   1  Submit credentials for ana@market.demo            [image]
      1  waitUntilVisible widgets with key ['login_view']
      2  enterText widgets with key ['email_input']
      …
2  Open the catalog                                     [image]
   1  tap widgets with key ['go_to_catalog_button']
   …
```

A step is the unit a reader cares about, so it is the unit worth a picture —
a screenshot of every individual tap is noise.

#### `takeScreenshot`, which Patrol does not ship

Patrol's web automation exposes taps, text, cookies, dialogs and window
control, but **no capture**, and its Dart API has no `takeScreenshot`. So the
suite adds one as an extension on `PatrolIntegrationTester`:

```dart
await $.takeScreenshot('cart_with_coupon');
```

The frame is rasterised inside the app from a `RepaintBoundary` the launcher
wraps around the widget tree, encoded as PNG and printed to the browser
console, which the Playwright bridge forwards into the test's stdout, where
the converter reassembles it.

Two details make that work:

- **`debugPrintSynchronously`, not `debugPrint`.** The latter throttles to
  about 1 KB/s and silently drops the rest, which shredded every payload.
- **Chunked base64.** A single very long line gets mangled on the way out, so
  the image travels in 800-character pieces and only becomes an attachment
  once all of them arrive.

#### Declaring a step

`BaseSteps.step` names a step, captures the screen it left behind and reports
its outcome — a failing step still emits its image, so the report shows what
the screen looked like when it broke:

```dart
Future<void> loginAsDemoUser() =>
    step('Log in as the demo user', () async {
      await submitCredentials(...);
      await _dashboard.waitUntilVisible();
      expect(_dashboard.greetingText, contains(TestData.demoFullName));
    });
```

Page objects stay free of reporting: they know how to touch a widget, not what
the touch was for.

Each capture costs roughly 150 ms. To run without them:

```bash
cd packages/apps/market_app && patrol test --device chrome --dart-define=E2E_SCREENSHOTS=false
```

---

## Technical decisions

- **No `freezed`, no `json_serializable`.** Models are written by hand so the
  example is self-explanatory and free of codegen.
- **`ViewStatus` instead of loose flags.** An enum with boolean getters
  (`isLoading`, `isData`, `isEmpty`, `isError`) lets a view resolve its four
  states with an exhaustive `switch`, and lets the analyzer catch missing cases.
- **`runPostBuild` in the base `ViewModel`.** See [State](#state-riverpod-261).
- **Logical deletion of publications.** `status = DELETED` removes them from the
  catalog while keeping the snapshots in historical orders.
- **Display currency with a fixed factor.** Switching to USD only changes
  rendering; prices are always stored in COP and the conversion is a constant
  (an offline app has no exchange-rate source).
- **The recovery code is deterministic**, derived from the email, and shown in a
  demo banner. In production it would be random, expiring and emailed.
- **Card data is never persisted**: it is validated in checkout step 2 and only
  the chosen payment method reaches the database.

## Known limitations

- **Per-platform verification.**
  - **Web**: full walkthrough — login, dashboard, catalog, detail, cart with
    coupons (valid and expired), three-step checkout, order created with stock
    decrement, and cold-start deep links.
  - **Android**: verified on a physical device (Samsung SM-A315G, Android 12):
    splash, onboarding, sign-up, login, dashboard with the bottom bar, product
    detail and the deep link
    `adb shell am start -d "market://catalog/detail/product_car_001"`.
  - **iOS**: verified on the iPhone 17 simulator (Xcode 26.6): onboarding,
    login, dashboard with the bottom bar, product detail, the deep link
    `xcrun simctl openurl booted "market://catalog/detail/product_car_001"` and
    **persistence** — a favorite marked before restarting the app was still
    there afterwards. The simulator runs in light appearance, so this pass also
    validated the light theme (Android and Web were walked in dark).
- **Web deep links** require the host to serve `index.html` for unknown routes
  (SPA fallback). Without it, an `F5` on `/catalog/detail/x` returns a 404 from
  the server, not from the app.
- **No automated tests**: the requested scope explicitly excludes them. The
  determinism and the stable keys are in place for whoever adds them.
- **Web images live in the row** as data URIs; with many large images it is
  worth moving them to IndexedDB separately.

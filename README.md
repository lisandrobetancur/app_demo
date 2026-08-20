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
├── e2e_framework/                   everything the automation framework owns
│   ├── patrol_kit/                  reusable E2E scaffolding — Flutter + Patrol only
│   ├── sqa_reporter/                the report generator, pure Dart
│   └── tool/e2e/                    the run scripts
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
```

Unit suites — no browser, no device, about a second each:

```bash
melos run testKit                 # the framework's own 49 tests
melos run testApp                 # the data files and their wiring
melos run testFast                # both
```

End-to-end suite. Each of these **cleans that platform's previous artifacts,
runs, and builds the report** — three things in one command, so the report is
part of running rather than a step someone has to remember:

```bash
melos run e2eWeb                  # headless, Playwright's bundled Chromium
melos run e2eWebHeaded            # visible browser
melos run e2eAndroid              # connected Android device

melos run e2eWebSmoke             # only --tags "smoke_test"
melos run e2eWebNegative          # only --tags "negative"

melos run e2eWebWip               # only the tests being worked on
melos run e2eAndroidWip           # the same, on a device

melos run e2eWebChrome            # installed Google Chrome
melos run e2eWebEdge              # installed Microsoft Edge
```

Every command above except the two `*Wip` ones passes `--exclude-tags wip`, so a test
tagged `Tags.wip` is left out of the bundle — **absent, not skipped**, because
the filter runs while the bundle is generated. That is what the tag is for: a
test being refactored or repaired should not be failing in anybody's run, and a
red suite people learn to ignore is worse than a smaller green one. The two
`*Wip` commands are the way back in, running those tests and only those.

A tag beats commenting the test out: the commented one stops compiling against
the app and rots in silence, while a `wip` one still builds, still gets renamed
by a refactor, and can be listed at any time.

The last two swap Playwright's bundled Chromium for a browser installed on the
machine, through `run_web.sh --browser=<channel>`; `chrome-beta`, `msedge-dev`
and the other channels work the same way. They are all Chromium builds — Patrol
sets no `browserName` and defines no Playwright projects, so Firefox and WebKit
are not reachable, and this is **not** cross-engine coverage. CI stays on the
bundled Chromium, which is the one it is guaranteed to have.

The report is built **even when the suite fails** — that is when it gets
opened — and the command still exits non-zero, so CI does not read a red run
as green. Opening it stays separate, because generating and opening are
different decisions and CI only ever wants the first:

```bash
melos run sqaOpenWeb              # open build/e2e/web/sqa_reporter/report
melos run sqaOpenAndroid

melos run e2eWebReport            # run, then open
melos run e2eWebHeadedReport
```

Rebuilding a report from results already on disk, without re-running the
suite — for when you changed the generator and want to see the effect:

```bash
melos run sqaWeb
melos run sqaAndroid
```

Cleaning on its own. Per platform, because a web report and a device report
describe different environments and are kept apart; running the web suite must
not take out the last device result:

```bash
melos run e2eCleanWeb             # build/e2e/web
melos run e2eCleanAndroid         # build/e2e/android
melos run e2eClean                # both
```

Everything a run generates goes under **one root per platform**, which is what
makes that cleaning trustworthy — deleting a whole root cannot leave anything
behind, while enumerating four scattered paths can, and did: `test-results/`
went unswept for months because nobody remembered it existed.

```
build/e2e/
├── web/
│   ├── playwright/            results.json, results.xml, Playwright's HTML
│   ├── test-results/          per-test traces and attachments
│   └── sqa_reporter/report    the report, its JSON results and screenshots
└── android/
    ├── android_run.log        the captured logcat
    └── sqa_reporter/report
```

`build/` is already gitignored, so nothing generated needs a rule of its own.
The exceptions are the files whose writers accept no other path:
`test_bundle.dart`, which patrol_cli puts at the package root — nor could it,
being Dart source that has to compile inside the package — and Playwright's
`test-results/` and `playwright-report/`, which appear in the app package when
someone runs `patrol test` by hand instead of through `run_web.sh` (which
redirects both). The clean script deletes all three by name, the Playwright
pair on the web platform only.

Cleaning happens at the **start** of a run, not the end: clearing up afterwards
leaves a tidy machine but also deletes the evidence of what just failed.

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
dart pub global activate patrol_cli 4.7.0
```

```bash
melos run e2eWeb
```

To watch it drive a real browser instead of running headless:

```bash
melos run e2eWebHeaded
```

> The flag behind it is `--no-web-headless`. Passing a value —
> `--web-headless=false` — still parses, but patrol_cli 4.7.0 warns that it is
> deprecated in favour of the boolean pair.

Building and opening the report is a separate step on purpose, so a run does
not force a browser window on you:

```bash
melos run sqaWeb && melos run sqaOpenWeb
```

`sqaOpenWeb` opens the report in the default browser straight off the
filesystem — the site is static and self-contained, so there is no server to
start and none to remember to stop. When you do want the whole thing in one
command, these chain the three steps:

```bash
melos run e2eWebReport        # headless, then open the report
```

```bash
melos run e2eWebHeadedReport  # visible browser, then open the report
```

The run itself uses three reporters, each for a different reader:

| Reporter | For whom | Output |
|---|---|---|
| `list` | the terminal | live progress |
| `json` | the report generator | `build/e2e/web/playwright/results.json` |
| `junit` | CI | `build/e2e/web/playwright/results.xml` — GitLab, Jenkins and Azure turn it into a test tab, which a static report site cannot do |

Patrol only accepts that whitelist, so no third-party reporter can be plugged
in — which is why the report is built from the `json` output afterwards
instead.

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
cd packages/apps/market_app && patrol test --device chrome --target patrol_test/scenarios/login_test.dart --web-headless=true
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
├── data/        the JSON the scenarios read, mirroring the seed
├── support/     app launcher, the data façade, epics and features
├── pages/       Page Objects: locators and atomic interactions
├── steps/       business language composing pages, with its assertions
└── scenarios/   the tests themselves, reading as sentences
```

`scenarios/` is named after the word the code already uses: `scenario()` opens
every test, and "Scenario" is the column the report puts them under. The other
four folders are what a scenario is built from, which is why only this one
holds `*_test.dart`.

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

`patrol` is pinned to **4.9.0** and `patrol_cli` to **4.7.0**.

Reaching 4.9.0 meant moving `equatable` from `2.0.7` to `2.1.0` in the seven
`*_typing` packages, because every patrol from 4.7.0 on requires
`equatable ^2.1.0`. That is a production dependency of the model layer, which is
why it was its own change rather than a line inside another one.

The CLI is versioned separately from the framework and drifted behind for a
while; the pairing above is the one CI runs. Check the
[compatibility table](https://patrol.leancode.co/documentation/compatibility-table)
before moving either.

### The report — SQA Reporter

```bash
melos run e2eWeb        # runs the suite, emitting Playwright JSON
```

```bash
melos run sqaWeb        # rebuilds the report from that JSON
```

```bash
melos run sqaOpenWeb    # opens the report in a browser
```

The generator is a Dart package, `packages/e2e_framework/sqa_reporter`, and it owns the
whole output: the JSON results, the screenshots and the static pages that read
them, all under one directory per platform which it writes from scratch every
time.

```
build/e2e/
├── web/sqa_reporter/report
└── android/sqa_reporter/report
```

The site is **self-contained** — no libraries, no fonts, no network requests at
all — so a browser opens it straight off the filesystem and there is no server
to start. The charts are CSS (a conic-gradient doughnut, flex bars) and the
table's filter, sort and pagination are its own sixty lines of script.

Why a generator of our own rather than an off-the-shelf reporter: Patrol owns
the Playwright config that runs the web suite, and its `mapReporters` accepts
only a whitelist — `html`, `json`, `junit`, `list`, `dot`, `line`, `github`,
`null` — and throws on anything else. So the pipeline uses the supported `json`
reporter and reads it afterwards.

Reading it is not a straight copy. Patrol prints a structured `PATROL_LOG {…}`
line for every interaction, so each `tap`, `enterText` and `waitUntilVisible`
becomes a **step** with its own duration, and a step still open when a test
dies is marked `broken` — which is usually the one that actually failed. Tests
are grouped by the feature their `scenario()` declared, and by the Dart file
they came from (`login_test`, `purchase_flow_test`) when they declared none.

Four markers of the suite's own travel the same stdout channel and are
translated alongside Patrol's:

| Marker | Emitted by | Becomes |
|---|---|---|
| `PATROL_STEP` | `BaseSteps.step` | A business step, with Patrol's interactions nested under it |
| `PATROL_SHOT` | `takeScreenshot` | An attachment on the step that produced it |
| `PATROL_ASSERT` | `BaseSteps.expectThat` | A leaf step carrying `expected` / `actual` |
| `PATROL_META` / `PATROL_PARAM` | `scenario()` / `testParam()` | The test's labels, description and case data |

The last three carry their payload as one-line JSON rather than pipe-separated
fields, so a value containing a `|` — an assertion message, a description —
cannot corrupt the stream.

`PATROL_ASSERT` is what makes a green step readable. `expect` on its own
leaves nothing behind: a passing assertion is invisible and a failing one only
surfaces as the test's error message, so a reader cannot tell whether a step
verified four rules or none. Every check becomes its own entry under its step,
showing what was expected and what was found — and when one fails, the checks
that passed alongside it still read as passed.

### Failed or broken, not just red

Two things end a step badly and they mean opposite things. An expectation the
test *made* went unmet — the test ran correctly and the product did not
behave. Or the test could not do its job at all: a locator matched nothing, a
wait timed out, a value could not be read; the product may be fine, nobody
checked.

WebDriver suites live by this distinction — an assertion failure versus a
`NoSuchElementException` — and the report says **failed** versus **broken**. The suite decides it in `stepOutcomeOf`, on the error object,
where the type is still known: a `TestFailure` is `failed`, anything else is
`broken`. Deciding it downstream would mean pattern-matching a message, and a
message is not a contract.

`should` inherits this for free, and the result reads as intent: an assertion
the test made explicitly is the product's problem, while the same missing
widget tapped without being asserted is the suite's. `seeThatIsPresent` on an
absent widget is *failed* — the test asked, the answer was no. A bare `.tap()`
on that same widget is *broken* — nobody asked, the test assumed.

The generator carries the verdict up: Playwright reports one `failed` for both
cases, so a test whose only casualty was a stale locator is promoted to
*broken* rather than being read as a product defect.

`scenario()` supplies the business taxonomy. `epic` and `feature` drive the
report's **Features** page, which groups by functionality instead of by file,
and `severity` is carried as a tag. There is deliberately no `story`: the
taxonomy this borrows from offers one, but a story is a unit of work while a
test is a unit of
verification, so the level pays for itself only when one story holds several
tests. Declared one-to-one with the tests, as it was here, it was a second name
for each of them and grouped nothing. The test's own name is the leaf. `testParam()` records the data a case
ran with — user, coupon, amounts — so a failure can be reproduced without
opening the test. Neither touches the app: both just print to stdout.

The generator is plain Dart with no dependencies beyond the SDK — **no Java,
no Node, no npm package** — so building a report needs nothing the repository
does not already have to run the suite.

### Counting what the report actually holds

A green suite and a suite that verified something are not the same claim, and
the difference is invisible from the outside. The assertions travel from the
browser console — or from logcat, on a device — through the per-test capture
and into the report, and a break anywhere along that chain is silent: the
tests still pass, the report just holds nothing behind them.

So both CI jobs run `dart run sqa_reporter:assertion_summary` after building the
report and write the count into the job summary, where it is readable from the
pull request without downloading an artifact:

| Scenario | Assertions | Passed | Failed |
|---|--:|--:|--:|
| buys a product from the catalog… | 16 | 16 | 0 |

The step **fails** when the report holds no assertions at all. A notice in a
summary nobody opens would not protect against the very thing this exists to
catch — a suite that stayed green while it stopped verifying anything. What it
does *not* do is add a second red mark to a run that produced no results at
all: a cancelled run, or a suite that never got far enough, is someone else's
red, and the step says so and leaves.

The pipe into `$GITHUB_STEP_SUMMARY` runs under `shell: bash` on purpose. That
is what sets `pipefail`; with the default shell, `tee` would return its own
success and swallow the script's exit code, turning the check quietly back
into a notice.

### Every run starts from nothing

A report describes the run that produced it, and nothing else. Three things
enforce that, because deleting the report alone is not enough:

- `sqaWeb` / `sqaAndroid` write `build/e2e/<platform>/sqa_reporter/report` from
  scratch, results and pages alike.
- Every run deletes `build/e2e/<platform>/` before starting. Patrol overwrites
  its results on success anyway, but a run that dies early would leave the
  previous `results.json` in place — and the next report would be built from it
  without a word, stamped with today's date.
- Rebuilding from results already on disk is a normal thing to do, so instead
  of warning on the command line the page itself says when the run it describes
  finished, beside the time the report was generated.

No history is kept either, by choice: history is state surviving between runs,
and it would be the one thing a rebuild does not clear.

### Running on Android

The same suite runs on a physical device, and produces its own report:

```bash
melos run e2eAndroid
```

```bash
melos run sqaAndroid
```

Everything above the transport is shared — the tests, the steps, the pages and
`takeScreenshot` are plain Flutter and move across untouched. What differs is
how the results get out, and that is where the work was:

| Piece | Web | Android |
|---|---|---|
| Runner | Playwright + Chromium | native instrumentation (`PatrolJUnitRunner`) |
| Marker transport | Playwright's per-test stdout capture | `adb logcat` |
| Generator input | `build/e2e/web/playwright/results.json` | `build/e2e/android/android_run.log` |
| Report | `build/e2e/web/sqa_reporter/report` | `build/e2e/android/sqa_reporter/report` |

The generator has one adapter per transport (`parsePlaywright`,
`parsePatrolLog`) feeding a single model, because the payload is identical:
Patrol emits the same `PATROL_LOG` protocol on every platform, and a case
carries the name, status, both timestamps and the error message — every field
the web path takes from Playwright. `parseMarkers`, which builds the step tree
and reassembles the screenshots, is shared verbatim.

Three things are worth knowing before running this on another machine.

**The markers come from the device log, not from the CLI.** `patrol_cli` parses
`PATROL_LOG` to pretty-print it and silently drops every other line, so its
stdout carries none of the step or screenshot markers. `packages/e2e_framework/tool/e2e/run_android.sh`
therefore reads logcat in parallel with the run. Logcat is also a ring buffer
that drops lines under load, so the script raises it to 16 MB before starting;
the converter skips a screenshot whose chunks are incomplete rather than failing
the report.

**The AndroidX test orchestrator is required**, and not for the usual reason. It
is normally described as the way to get `clearPackageData` between tests, which
this suite does not need — `app_launcher.dart` already resets its own state in
Dart. What it actually provides is a *fresh process per test case*, and Patrol
needs that: it enumerates the Dart tests and asks the native side for one at a
time, but a Dart test bundle runs every test as soon as it starts. Without the
orchestrator the first request executes the whole bundle and the remaining cases
find nothing left to run — 1 passed, 5 failed.

**Installing the orchestrator can time out** on a mid-range device, surfacing as
`ShellCommandUnresponsiveException` and `Failed to install split APK(s)` rather
than as a timeout. `installation { timeOutInMs }` in `android/app/build.gradle.kts`
raises the limit; pre-installing it once with `adb install` also works.

Last verified run: **6 passed, 0 failed in 2 m 50 s** on a Samsung SM-A315G
(Android 12), 33 screenshots in the report — the same six tests and the same
count as the web run.

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

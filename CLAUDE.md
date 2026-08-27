# Market monorepo

A Flutter marketplace demo with no backend — SQLite on Android, iOS and Web —
plus an E2E framework and a report generator built in this repo.

Written in English like the rest of the code. The Spanish in `docs/` is for
briefings a person pastes somewhere; the Spanish inside the E2E suite is
report content, and it stays Spanish (see below).

## Layout

Dart pub workspace, melos 7.3.0. Melos config lives in the root `pubspec.yaml`,
**not** in a `melos.yaml` — melos 7 stopped reading that file.

```
packages/apps/market_app          the app, and its patrol_test/ suite
packages/e2e_framework/patrol_kit         the E2E framework (pure Dart + Flutter)
packages/e2e_framework/e2e_test_reporter  the HTML report generator (pure Dart)
packages/e2e_framework/tool/e2e           the runner scripts
packages/features, ui, shared     the product
```

## Commands

```sh
melos bs                # bootstrap
melos run lint          # flutter analyze
melos run testFast      # testKit + testApp, no browser, no device
melos run e2eWeb        # clean + run + build the report  (~1 min, the fast one)
melos run e2eAndroid    # same, on a device
melos run e2eIos        # same, on a simulator (macOS only)
melos run openReportWeb # open the report that already exists
```

Tag filters exist per platform: `e2eWebSmoke`, `e2eWebRegression`,
`e2eWebNegative`, and the same for Android and iOS. `e2eWebWip` runs the tests
tagged `wip`, compiled without their skip.

CI runs all three suites on every PR and twice a day on `main`, and publishes
the three reports to GitHub Pages.

## Writing an E2E scenario

Load the `e2e-nuevo-escenario` skill. It carries the four layers, the
vocabulary and the traps. The short version:

```
scenarios/  one file per feature area — WHAT is verified, in Spanish
steps/      business steps — perform and assert, take data as parameters
pages/      one screen each — locators and interactions, no assertions
support/    Features, Epics, TestData, launchMarketApp
```

## Rules that fail silently

These do not fail loudly, or fail far from their cause. Each one has cost a
red build or, worse, a green one.

1. **Nothing reads `TestData` before `launchMarketApp($)`.** The data lives in
   the asset bundle, which does not exist until the app launches. Guarded by
   `test/patrol_guards/test_order_test.dart`.
2. **Never put a password in a step name.** Step names travel through the
   marker stream into the HTML report, which CI uploads and GitHub Pages
   serves. The email is fine; the password is a leak.
3. **A step asserts through `should(seeThat(...))` and nothing else.** That is
   what the report counts and what `assertion_summary` guards. A scenario that
   only acts verifies nothing and still passes.
4. **Steps take data as parameters.** A step that reaches into `TestData`
   itself hides half the scenario from the file that claims to define it.
5. **`dart format . --line-length 80` is run from inside the target package**,
   never from the root.
6. **The generated report is self-contained** — no external URL, no CDN, no
   font. Permanent tests assert it. It also carries no vendor logo or borrowed
   product name.
7. **Web runs in profile by default.** Debug means DDC, 1144 JS modules per
   test, and an intermittent 43-minute hang. Typing works in profile because
   the kit registers the keyboard mock itself.
8. Dependencies are **pinned exactly** (`patrol: 4.9.0`, not `^4.9.0`), and
   every package's `analysis_options.yaml` is
   `include: package:lint/analysis_options.yaml`.

## Commit trailers

```
Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: <session url>
```

No model identifiers in commits, PR text, or code.

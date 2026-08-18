# Context handoff: taking this POC's E2E to a real app

This document exists so that a fresh session — on another account, another team
or another day — can pick the work up without analysing anything again. It is
self-contained: reading it gives you everything that was concluded while
studying this POC.

- **Reference repository (public):** https://github.com/lisandrobetancur/app_demo
- **Phased migration prompt:** [`docs/prompt-migracion-patrol.md`](./prompt-migracion-patrol.md)

## How to start on another account

The repo is public, so there is no need to transfer permissions or export the
session. In the new session, **opened on the real app's repository**, this is
enough:

```
Read https://raw.githubusercontent.com/lisandrobetancur/app_demo/main/docs/e2e-handoff.md
and https://raw.githubusercontent.com/lisandrobetancur/app_demo/main/docs/prompt-migracion-patrol.md

Adopt the role and the rules in the prompt, and start from Phase 0 on THIS
project. Phase 0 only.
```

If that session has no internet access, there are two alternatives: clone the
reference repo inside the environment, or paste the prompt's content by hand
(it is self-contained and does not depend on reading this POC).

## What the reference POC is

An offline-first Flutter vehicle marketplace. A Melos monorepo with 36 packages
under `packages/{apps,features,shared,ui,development}`. It runs on Android, iOS
and web from a single shell. The E2E suite is built with **Patrol 4.9.0**, with
an Allure report and CI on GitHub Actions.

**It is not a template to copy as-is.** It is a POC built without constraints,
where any file could be touched. An app in production has different
constraints, which is why what matters in the analysis below is the separation
between what Patrol **requires** and what this POC merely **chose**.

## Files worth looking at

| Path | What it shows |
|---|---|
| `packages/apps/market_app/patrol_test/` | The whole suite: `pages/`, `steps/`, `support/`, tests |
| `patrol_test/pages/base_page.dart` | The page layer's contract, documented |
| `patrol_test/steps/auth_steps.dart` | Steps in business language, no locators |
| `patrol_test/support/app_launcher.dart` | How the app is launched inside a test |
| `patrol_test/support/screenshot.dart` | Per-step capture — **without touching the app** |
| `packages/apps/market_app/pubspec.yaml` | The `patrol:` block and the `dev_dependency` |
| `android/app/build.gradle.kts` | Runner + orchestrator, with the reasoning in comments |
| `pubspec.yaml` (root) | Melos scripts: `e2eWeb`, `e2eAndroid`, `allureWeb` |
| `tool/allure/`, `tool/e2e/` | Allure conversion and logcat capture |
| `.github/workflows/e2e-*.yml` | Web and Android CI |

## Conclusion of the analysis: Patrol's real footprint

This is the part you cannot deduce by reading the code, and the reason this
document exists.

### Mandatory (irreducible)

| What | Where | Impact on the production binary |
|---|---|---|
| `patrol` in `dev_dependencies` + `patrol:` block | the app's `pubspec.yaml` | **None** — a `dev_dependency` does not enter the release |
| A launcher that pumps the tree instead of `runApp` | new file in the test folder | None |
| Android: `testInstrumentationRunner`, orchestrator, bridge class | `android/app/build.gradle`, `src/androidTest/` | `androidTest` only; does not touch the release APK |
| iOS: `RunnerUITests` target | `ios/Runner.xcodeproj` | Additive; does not touch the app target |

**On web the native footprint is exactly zero:** Patrol drives Chromium through
Playwright, without touching `android/` or `ios/`. That is why web is the
recommended way in for a project that does not want to take risks.

### What this POC has but is NOT necessary

Verified in the code, not estimated:

- **`appBoundaryKey` (screenshots)** — lives 100% in
  `patrol_test/support/screenshot.dart`. Footprint in the app: zero. It can be
  replicated without touching anything.
- **`AppDurations.fastMode`** — this one *is* production code
  (`packages/ui/design_system/lib/src/tokens/app_durations.dart` +
  `main.dart:18`). It is the only piece of the POC that adds a behaviour branch
  to the real binary. **In a mature app, do not replicate it.** Alternatives:
  `timeDilation` from the test, or accepting a slower `pumpAndSettle`.
- **`seedMode` / `fileName` on the database** — app-side in the POC.
  Alternative without touching production: use whatever DI already exists to
  substitute the repository or the HTTP client from the test launcher.
- **The ~90 `Key`s centralised in the `*_constants` packages** — the flashiest
  part of the POC, and **Patrol does not require them**. Finders accept text,
  widget type, descendants and semantics. Adding a `Key` changes no layout, no
  render and no behaviour, but it is production code: it must be an explicit
  decision per widget, never a mass sweep.

### Risks when taking this to a production app, in order

1. **Collision with an existing `androidTest`.** There can only be one
   `testInstrumentationRunner`. If the project already has instrumented tests
   (Espresso, or an SDK's own), declaring Patrol's breaks them. This is the
   first thing to check. Mitigation: `testBuildType` or a product flavor
   dedicated to E2E.
2. **An unfactored `main()`.** Here `main.dart` is 14 lines and the launcher
   could mirror it trivially. A mature app usually carries `Firebase`,
   Crashlytics, remote config, analytics and DI inside `main()`. A reusable
   `bootstrap()` / `createApp()` has to be extracted — **this is the project's
   real work**, and it is a mechanical, verifiable refactor.
3. **`project.pbxproj` on iOS.** Adding the target produces merge conflicts
   when several branches are alive. It breaks the repo, not the app.
4. **CI time.** The orchestrator restarts the process for every test (the
   reasoning is in a comment in `android/app/build.gradle.kts`). Correct but
   slow: propose it as a nightly or manual job, not on every PR.

### What is NOT viable

A separate repository holding only the Patrol tests, without touching the app.
Patrol is not black-box: the test **is compiled into the binary** and imports
the app's code (`app_launcher.dart` imports `package:market_app/…`, `database`,
`design_system`), the CLI runs from the app's package and the native side lives
in its Android/iOS projects. An external repo would have to clone the whole
workspace anyway.

What can be done: extract `pages/`, `steps/` and `support/` into a package of
their own, leaving only the `*_test.dart` files and the `patrol:` block in the
app. For genuinely zero contact you would need a black-box tool (Maestro,
Appium) against the already-compiled binary, losing the access to the widget
tree and the state control that makes Patrol worth having.

## Decisions already made for the migration

They are encoded in the prompt; they are listed here so they do not get
re-litigated:

- Start with **web** if the real app supports it (zero native footprint).
- **A person defines the locators, not the agent.** Before writing a page
  object, the agent hands over a request table per screen and waits.
- Do **not** replicate `fastMode` or any other "test mode" flag in production.
- `Key`s, if needed, go in **one commit per screen**.
- One phase at a time, with a declared file budget and a mandatory stop at the
  end of each.

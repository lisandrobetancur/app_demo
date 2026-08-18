#!/usr/bin/env bash
#
# Runs the E2E suite in the browser and leaves the report built.
#
#   packages/sqa_l/tool/e2e/run_web.sh [--headed] [--tags=<expression>] [--browser=<channel>]
#
# Three things in one command, in this order: clean up after the previous run,
# run, and build the report. This is Serenity's `aggregate` model — the report
# is part of running, not a step somebody has to remember to launch afterwards.
# Opening it stays separate (`melos run allureServeWeb`): building and opening
# are different decisions, and in CI only the first one exists.
#
# THE DELICATE PART is the exit code. The report has to be built EVEN WHEN the
# suite fails, which is exactly when somebody is going to open it — but the
# whole command must still exit red, or CI would accept a run with failing
# tests. So the report is not chained to the run with `&&`: the suite's status
# is saved, the report is built either way, and the saved status is what the
# script exits with.
#
# `set -e` stays on for everything else — cleanup and argument parsing SHOULD
# abort on failure — and is switched off only around the run, the one point
# where a non-zero code is a result rather than an error.
set -euo pipefail

# The repo root, asked of git rather than counted in `..` segments.
# This directory has moved once already; a script that locates itself
# by hop count breaks silently on the next move, and the failure lands
# in CI as a missing file rather than as a wrong path.
cd "$(git rev-parse --show-toplevel)"

APP_DIR="packages/apps/market_app"

# A flag, not a value. `--web-headless=false` still parses on patrol_cli
# 4.7.0 but warns that it is deprecated; the boolean pair is what the CLI
# wants now.
HEADLESS_FLAG=--web-headless
TAGS=()
BROWSER=""

# The browsers Playwright will accept as a `channel`. Checked here rather than
# left to Playwright because the failure is expensive and late: the app is built
# and served first, so a typo surfaces a minute in, from inside the runner,
# worded in Playwright's terms rather than this script's.
CHANNELS="chrome chrome-beta chrome-dev chrome-canary msedge msedge-beta msedge-dev msedge-canary"

for arg in "$@"; do
  case "$arg" in
    --headed) HEADLESS_FLAG=--no-web-headless ;;
    --tags=*) TAGS=(--tags "${arg#--tags=}") ;;
    --browser=*)
      BROWSER="${arg#--browser=}"
      if [[ " $CHANNELS " != *" $BROWSER "* ]]; then
        echo "unknown browser: $BROWSER" >&2
        echo "choose one of: $CHANNELS" >&2
        echo "(all of them are Chromium builds — Patrol exposes no other engine)" >&2
        exit 2
      fi
      ;;
    *)
      echo "unrecognized argument: $arg" >&2
      echo "usage: packages/sqa_l/tool/e2e/run_web.sh [--headed] [--tags=<expression>] [--browser=<channel>]" >&2
      exit 2
      ;;
  esac
done

packages/sqa_l/tool/e2e/clean.sh web

# ABSOLUTE paths, and that is not a matter of style. `--web-results-dir` and
# `--web-report-dir` end up in the environment variables read by the
# playwright.config.ts that Patrol ships, and Playwright resolves a relative
# path against the directory of ITS config — inside the patrol package in the
# pub cache, not against where you are. A relative path here would write the
# results into the package cache.
OUT="$PWD/build/e2e/web"

# `--web-locale` is not cosmetic: a freshly created headless browser may report
# no language at all, and the Flutter engine throws "Invalid argument: Incorrect
# locale information provided" before painting a frame — the app never starts
# and the run reports zero tests instead of a failure. Pinning it also makes
# local and CI agree, and the suite asserts on Spanish text. The timezone is
# pinned for the same reason, before a date assertion comes to depend on where
# the machine happens to be.
#
# Three reporters, one per reader: `list` for the terminal, `json` for the
# Allure converter and `junit` for CI. The `json` one is not optional:
# Playwright's per-test capture is the only channel carrying the screenshot
# markers out of the browser.
#
# `--browser` reaches Playwright as an environment variable and not as a flag,
# because `patrol_cli` has none: of its twenty-odd `--web-*` options not one
# selects a browser. Patrol's own playwright.config.ts does read
# `PATROL_WEB_CHANNEL`, and the CLI spreads the parent environment into the
# process it spawns, so exporting it here arrives.
#
# Unset by default, deliberately. With no channel Playwright uses the Chromium
# it ships, which is the one CI has and the one that gets a reproducible run.
# A channel asks for a browser installed on this machine instead.
#
# Note what `--device chrome` above is NOT: that is Flutter's device — how the
# app is built and served — not the browser driving the test. The two words
# being the same is a coincidence worth not tripping over.
status=0
set +e
(
  if [[ -n "$BROWSER" ]]; then
    export PATROL_WEB_CHANNEL="$BROWSER"
  fi
  cd "$APP_DIR" && patrol test \
    --device chrome \
    "${TAGS[@]+"${TAGS[@]}"}" \
    --web-report-dir="$OUT/playwright" \
    --web-results-dir="$OUT/test-results" \
    "$HEADLESS_FLAG" \
    --web-locale=es-ES \
    --web-timezone=America/Bogota \
    --web-reporter='["list","json","junit"]'
) || status=$?
set -e

# A channel names a browser Playwright expects to find already installed; it
# downloads nothing. When one is missing the run dies before the first test
# with `Playwright process exited unexpectedly with code 1` and nothing else —
# patrol_cli captures Playwright's stderr, so the real message ("Chromium
# distribution 'msedge' is not found at ...") never reaches the terminal, and
# `--verbose` does not bring it back.
#
# Zero tests plus a requested channel is that shape almost every time, so the
# guess is worth printing. It is a guess, not a diagnosis, and it says so.
if [[ -n "$BROWSER" && "$status" -ne 0 ]]; then
  echo >&2
  echo "The run asked for --browser=$BROWSER and no test executed." >&2
  echo "A channel uses a browser already installed on this machine; if it is" >&2
  echo "absent Playwright fails to launch and the CLI hides the reason." >&2
  echo >&2
  echo "  npx playwright install $BROWSER      # install it, or" >&2
  echo "  melos run e2eWeb                     # run on the bundled Chromium" >&2
  echo >&2
  echo "To see Playwright's own error, ask it directly:" >&2
  echo "  RUNNER=\$(find ~/.pub-cache/hosted/pub.dev -maxdepth 1 -type d -name 'patrol-*' | tail -1)/web_runner" >&2
  echo "  (cd \"\$RUNNER\" && npx playwright open --channel=$BROWSER about:blank)" >&2
fi

echo
echo "── Building the reports ──────────────────────────────────────────────"
# Deliberately not chained with `&&` to the above: a red suite is exactly when
# the report is needed.
#
# Two reporters read the same run, and neither is allowed to stop the other:
# they are separate `||` branches so a broken Allure toolchain still leaves an
# SQA report, and a bug in the Dart reporter still leaves the Allure one. That
# is the whole point of running both while one replaces the other.
node packages/sqa_l/tool/allure/patrol_to_allure.mjs --platform web \
  && pnpm --dir packages/sqa_l/tool/allure exec allure awesome "$OUT/allure/results" \
       --output "$OUT/allure/report" --report-name "Market E2E · Web" \
  || echo "The Allure report could not be built (the suite exited with $status)." >&2

dart run sqa_reporter --input "$OUT/playwright/results.json" --platform web \
  || echo "The SQA report could not be built (the suite exited with $status)." >&2

echo
echo "Reports:"
echo "  build/e2e/web/allure/report         ·  melos run allureServeWeb"
echo "  build/e2e/web/sqa_reporter/report   ·  melos run sqaOpenWeb"
exit "$status"

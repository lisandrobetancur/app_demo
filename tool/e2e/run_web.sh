#!/usr/bin/env bash
#
# Runs the E2E suite in the browser and leaves the report built.
#
#   tool/e2e/run_web.sh [--headed]
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

cd "$(dirname "$0")/../.."

APP_DIR="packages/apps/market_app"

HEADLESS=true
TAGS=()
for arg in "$@"; do
  case "$arg" in
    --headed) HEADLESS=false ;;
    --tags=*) TAGS=(--tags "${arg#--tags=}") ;;
    *)
      echo "unrecognized argument: $arg" >&2
      echo "usage: tool/e2e/run_web.sh [--headed] [--tags=<expression>]" >&2
      exit 2
      ;;
  esac
done

tool/e2e/clean.sh web

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
status=0
set +e
(
  cd "$APP_DIR" && patrol test \
    --device chrome \
    "${TAGS[@]+"${TAGS[@]}"}" \
    --web-report-dir="$OUT/playwright" \
    --web-results-dir="$OUT/test-results" \
    --web-headless="$HEADLESS" \
    --web-locale=es-ES \
    --web-timezone=America/Bogota \
    --web-reporter='["list","json","junit"]'
) || status=$?
set -e

echo
echo "── Building the report ───────────────────────────────────────────────"
# Deliberately not chained with `&&` to the above: a red suite is exactly when
# the report is needed.
node tool/allure/patrol_to_allure.mjs --platform web \
  && npx --prefix tool/allure allure awesome "$OUT/allure/results" \
       --output "$OUT/allure/report" --report-name "Market E2E · Web" \
  || echo "The report could not be built (the suite exited with $status)." >&2

echo
echo "Report:  build/e2e/web/allure/report  ·  open it with: melos run allureServeWeb"
exit "$status"

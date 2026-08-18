#!/usr/bin/env bash
#
# Deletes everything a run generates, for ONE platform.
#
#   packages/sqa_l/tool/e2e/clean.sh web
#   packages/sqa_l/tool/e2e/clean.sh android
#
# Everything generated lives under a single root, one subfolder per platform:
#
#   build/e2e/
#   ├── web/
#   │   ├── playwright/     results.json, results.xml, Playwright's HTML
#   │   ├── test-results/   per-test traces and attachments
#   │   └── allure/{results,report}
#   └── android/
#       ├── android_run.log the captured logcat
#       └── allure/{results,report}
#
# That is what makes this cleanup trustworthy. The artifacts used to be spread
# across four places in the repository and this script had to enumerate them
# one by one — and it forgot the ones nobody remembered existed: `test-results/`
# was never deleted by anyone. With one root per platform, deleting it whole is
# an operation that cannot leave anything behind.
#
# Per platform rather than all at once, because a web report and an Android one
# describe different environments and are kept apart: running the web suite
# must not take out the last device result.
#
# It runs at the START of every run, not at the end. The difference matters:
# cleaning up afterwards leaves the machine tidy but also deletes the evidence
# of what just failed. Cleaning at the start guarantees the only thing that
# needs guaranteeing — that nothing left on disk came from the previous run.
#
# That is not tidiness for its own sake. Patrol overwrites its results when it
# finishes properly, but a run that dies early leaves yesterday's in place, and
# the next report is built on top of them without a word: it comes out dated
# "now" carrying old data.
set -euo pipefail

# The repo root, asked of git rather than counted in `..` segments.
# This directory has moved once already; a script that locates itself
# by hop count breaks silently on the next move, and the failure lands
# in CI as a missing file rather than as a wrong path.
cd "$(git rev-parse --show-toplevel)"

APP_DIR="packages/apps/market_app"

usage() {
  echo "usage: packages/sqa_l/tool/e2e/clean.sh <web|android>" >&2
  exit 2
}

PLATFORM="${1:-}"
case "$PLATFORM" in
  web | android) ;;
  *) usage ;;
esac

targets=(
  # That platform's root: takes results, report and logs in one go.
  "build/e2e/$PLATFORM"
  # `test_bundle.dart` is the exception, and not by oversight: patrol_cli
  # generates it at the package root and accepts no other path — nor could it,
  # being Dart code that has to compile inside the package. It is deleted all
  # the same because it is a leftover, and one left by an interrupted run may
  # not match the tests that are there now.
  "$APP_DIR/test_bundle.dart"
  "$APP_DIR/patrol_test/test_bundle.dart"
)

removed=0
for target in "${targets[@]}"; do
  if [[ -e "$target" ]]; then
    rm -rf "$target"
    echo "  deleted  $target"
    removed=$((removed + 1))
  fi
done

if [[ "$removed" -eq 0 ]]; then
  echo "Cleanup ($PLATFORM): nothing left from a previous run."
else
  echo "Cleanup ($PLATFORM): $removed item(s)."
fi

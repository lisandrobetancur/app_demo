#!/usr/bin/env bash
#
# Runs the Patrol suite on a connected Android device and captures the device
# log, which is what the Allure converter reads.
#
# The capture is the whole point of this script. `patrol_cli` parses
# `PATROL_LOG` lines to pretty-print them and drops every other line, so its
# stdout carries none of the step or screenshot markers the report is built
# from. On web those markers survive because Playwright captures the browser
# console; on Android the only place they exist is logcat, and it has to be
# read in parallel with the run.
#
# Like the web run, it does three things in one command: clean up after the
# previous run, run, and build the report — Serenity's `aggregate` model, where
# the report is part of running rather than a separate step somebody has to
# remember. Opening it stays a different thing
# (`melos run allureServeAndroid`).
#
# The report is built EVEN WHEN the suite fails, which is when somebody is
# going to open it, but the script still exits red so CI does not accept a run
# with failing tests. Hence saving the status and propagating it at the end
# instead of chaining with `&&`.
#
# `set -e` stays on for device detection and log capture — a failure there is a
# failure — and is switched off only around the run, where a non-zero code is
# the result.
#
#   packages/sqa_l/tool/e2e/run_android.sh [device-serial]
#
set -euo pipefail

# The repo root, asked of git rather than counted in `..` segments.
# This directory has moved once already; a script that locates itself
# by hop count breaks silently on the next move, and the failure lands
# in CI as a missing file rather than as a wrong path.
cd "$(git rev-parse --show-toplevel)"
APP_DIR="packages/apps/market_app"
OUT="build/e2e/android"
LOG="$OUT/android_run.log"

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  # `adb devices` prints a header line, then one line per device.
  DEVICE="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
fi
if [[ -z "$DEVICE" ]]; then
  echo "No authorised Android device found. Connect one, enable USB debugging," >&2
  echo "and accept the pairing prompt; check with 'adb devices'." >&2
  echo "If the list is empty but the device is plugged in, the adb daemon may" >&2
  echo "not be running: 'adb kill-server && adb start-server'." >&2
  exit 1
fi

packages/sqa_l/tool/e2e/clean.sh android

mkdir -p "$OUT"
echo "Running on $DEVICE ($(adb -s "$DEVICE" shell getprop ro.product.model | tr -d '\r'))"

adb -s "$DEVICE" logcat -c
# Logcat is a ring buffer and drops lines under load. Screenshots arrive as
# hundreds of chunked lines, so they are the first thing lost at the default
# size.
adb -s "$DEVICE" logcat -G 16M

adb -s "$DEVICE" logcat > "$LOG" &
LOGCAT_PID=$!
trap 'kill "$LOGCAT_PID" 2>/dev/null || true' EXIT

status=0
set +e
(cd "$APP_DIR" && patrol test --device "$DEVICE")
status=$?
set -e

# Give logcat a moment to flush whatever the last test emitted.
sleep 2
kill "$LOGCAT_PID" 2>/dev/null || true
trap - EXIT

echo "Device log captured at $LOG ($(wc -l < "$LOG" | tr -d ' ') lines)"

echo
echo "── Building the reports ──────────────────────────────────────────────"
# Two reporters over the same device log, each in its own `||` branch: neither
# can stop the other from being built. See run_web.sh for why that matters
# while one is replacing the other.
node packages/sqa_l/tool/allure/patrol_to_allure.mjs --input "$LOG" --platform android \
  && pnpm --dir packages/sqa_l/tool/allure exec allure awesome "$OUT/allure/results" \
       --output "$OUT/allure/report" --report-name "Market E2E · Android" \
  || echo "The Allure report could not be built (the suite exited with $status)." >&2

dart run sqa_reporter --input "$LOG" --format patrol-log --platform android \
  || echo "The SQA report could not be built (the suite exited with $status)." >&2

echo
echo "Reports:"
echo "  build/e2e/android/allure/report        ·  melos run allureServeAndroid"
echo "  build/e2e/android/sqa_reporter/report  ·  melos run sqaOpenAndroid"
exit "$status"

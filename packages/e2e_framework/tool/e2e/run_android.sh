#!/usr/bin/env bash
#
# Runs the Patrol suite on a connected Android device and captures the device
# log, which is what the report generator reads.
#
# The capture is the whole point of this script. `patrol_cli` parses
# `PATROL_LOG` lines to pretty-print them and drops every other line, so its
# stdout carries none of the step or screenshot markers the report is built
# from. On web those markers survive because Playwright captures the browser
# console; on Android the only place they exist is logcat, and it has to be
# read in parallel with the run.
#
# Like the web run, it does three things in one command: clean up after the
# previous run, run, and build the report, so the report is part of running
# rather than a separate step somebody has to remember. Opening it stays a
# different thing (`melos run sqaOpenAndroid`).
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
#   packages/e2e_framework/tool/e2e/run_android.sh [device-serial] [--wip]
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

TAGS=()

# `wip` marks a test somebody is in the middle of, and the runner is what acts
# on it rather than a convention people have to remember. `--exclude-tags` is
# applied while the bundle is GENERATED, so such a test is never compiled in:
# absent, not skipped. A half-finished test that fails is noise, and noise on
# a red suite is what teaches people to stop reading it.
#
# `--wip` is the way back in — it runs those and only those, which is what
# somebody repairing one actually wants.
EXCLUDE=(--exclude-tags wip)

if [[ "${1:-}" == --wip || "${2:-}" == --wip ]]; then
  TAGS=(--tags wip)
  EXCLUDE=()
fi

DEVICE="${1:-}"
[[ "$DEVICE" == --wip ]] && DEVICE=""
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

packages/e2e_framework/tool/e2e/clean.sh android

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
(cd "$APP_DIR" && patrol test --device "$DEVICE" \
   "${TAGS[@]+"${TAGS[@]}"}" "${EXCLUDE[@]+"${EXCLUDE[@]}"}")
status=$?
set -e

# Give logcat a moment to flush whatever the last test emitted.
sleep 2
kill "$LOGCAT_PID" 2>/dev/null || true
trap - EXIT

echo "Device log captured at $LOG ($(wc -l < "$LOG" | tr -d ' ') lines)"

echo
echo "── Building the report ───────────────────────────────────────────────"
dart run sqa_reporter --input "$LOG" --format patrol-log --platform android \
  || echo "The report could not be built (the suite exited with $status)." >&2

echo
echo "Report:"
echo "  build/e2e/android/sqa_reporter/report  ·  melos run sqaOpenAndroid"
exit "$status"

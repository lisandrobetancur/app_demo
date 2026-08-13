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
#   tool/e2e/run_android.sh [device-serial]
#
set -euo pipefail

cd "$(dirname "$0")/../.."
APP_DIR="packages/apps/market_app"
LOG_DIR="build/e2e"
LOG="$LOG_DIR/android_run.log"

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

mkdir -p "$LOG_DIR"
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
(cd "$APP_DIR" && patrol test --device "$DEVICE") || status=$?

# Give logcat a moment to flush whatever the last test emitted.
sleep 2
kill "$LOGCAT_PID" 2>/dev/null || true
trap - EXIT

echo "Device log captured at $LOG ($(wc -l < "$LOG" | tr -d ' ') lines)"
exit "$status"

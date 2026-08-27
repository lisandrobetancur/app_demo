#!/usr/bin/env bash
#
# Runs the Patrol suite on an iOS simulator and captures the device log, which
# is what the report generator reads.
#
# The capture is the whole point of this script, exactly as it is on Android.
# `patrol_cli` parses `PATROL_LOG` lines to pretty-print them and drops every
# other line, so its stdout carries none of the step or screenshot markers the
# report is built from. On web those markers survive because Playwright
# captures the browser console; on a device the only place they exist is the
# device log, and it has to be read in parallel with the run.
#
# WHERE THIS DIFFERS FROM ANDROID, and it is the part worth understanding:
#
#   * `adb logcat` streams a ring buffer that already holds everything the
#     device printed. `log stream` does not — it is a live tap, and anything
#     printed before it attaches is simply not there. So it starts BEFORE the
#     run and gets a moment to attach, rather than being cleared first.
#
#   * os_log throttles. A process that floods it has its lines dropped, and
#     dropped silently: the log just has fewer lines, with no gap marker.
#     Screenshots arrive as hundreds of chunked base64 lines, which is exactly
#     the shape that gets throttled — so this asks for the narrowest predicate
#     that still carries them, rather than streaming everything and hoping.
#
#     There is no `logcat -G 16M` equivalent to buy headroom. If markers do go
#     missing, the visible symptom is a green suite with an empty report, and
#     the guard against it is CI's `assertion_summary` step, which fails when
#     the assertion count comes out zero.
#
#   * A simulator has to be booted first. `adb devices` lists what is already
#     connected; `simctl` will happily be asked for a device that is shut down,
#     and `patrol test` would then fail in Xcode's words rather than this
#     script's.
#
# Like the other two runners it does three things in one command: clean up
# after the previous run, run, and build the report, so the report is part of
# running rather than a separate step somebody has to remember. Opening it
# stays a different thing (`melos run openReportIos`).
#
# The report is built EVEN WHEN the suite fails, which is when somebody is
# going to open it, but the script still exits red so CI does not accept a run
# with failing tests. Hence saving the status and propagating it at the end
# instead of chaining with `&&`.
#
#   packages/e2e_framework/tool/e2e/run_ios.sh [device-udid|device-name]
#                                 [--tags=<expression>] [--wip]
#
set -euo pipefail

# The repo root, asked of git rather than counted in `..` segments.
# This directory has moved once already; a script that locates itself
# by hop count breaks silently on the next move, and the failure lands
# in CI as a missing file rather than as a wrong path.
cd "$(git rev-parse --show-toplevel)"
APP_DIR="packages/apps/market_app"
OUT="build/e2e/ios"
LOG="$OUT/ios_run.log"

# Read from the app's own Patrol config rather than written twice: the log
# predicate has to name the process, and a bundle id that drifts from the one
# Patrol installs would filter the run's own output away — leaving a green
# suite with an empty report, which is the failure this whole file is built to
# avoid.
BUNDLE_ID="$(awk '/^patrol:/{p=1} p&&/^  ios:/{i=1} i&&/bundle_id:/{print $2; exit}' \
  "$APP_DIR/pubspec.yaml")"
if [[ -z "$BUNDLE_ID" ]]; then
  echo "No patrol.ios.bundle_id in $APP_DIR/pubspec.yaml." >&2
  echo "Patrol needs it to install the app; this script needs it to filter" >&2
  echo "the device log down to the app's own output." >&2
  exit 1
fi

TAGS=()

# `wip` is decided in Dart, not here: `e2eTest` registers such a test as
# skipped, so it reaches the report — counted under Skipped, with a pale row —
# without its body ever running. An excluded test is invisible and rots; a
# skipped one is a debt somebody can see.
#
# `--wip` is the way back in. It narrows the run to those tests and compiles
# them WITHOUT the skip, through a dart-define the kit reads at registration
# time.
WIP_DEFINE=()

# Anything that is not a flag names the device, so the two can be given in
# either order and neither has to be given at all. Written as a loop and not
# by position for the reason the Android runner learned the hard way: read
# positionally, `--tags=smoke_test` is taken for a device name and fails much
# later, in Xcode's words rather than this script's.
DEVICE=""
for arg in "$@"; do
  case "$arg" in
    --wip)
      TAGS=(--tags wip)
      WIP_DEFINE=(--dart-define PATROL_RUN_WIP=true)
      ;;
    # Patrol takes boolean expressions, not just names: "smoke_test &&
    # negative" and "!smoke_test" both work. The vocabulary lives in `Tags`,
    # in the kit.
    --tags=*) TAGS=(--tags "${arg#--tags=}") ;;
    -*)
      echo "unrecognized argument: $arg" >&2
      echo "usage: packages/e2e_framework/tool/e2e/run_ios.sh [device-udid|device-name] [--tags=<expression>] [--wip]" >&2
      exit 2
      ;;
    *) DEVICE="$arg" ;;
  esac
done

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found: this runner needs macOS with Xcode installed." >&2
  echo "The web suite runs anywhere ('melos run e2eWeb'); iOS does not." >&2
  exit 1
fi

# Chosen by RULE, never by model name. A hardcoded "iPhone 16" is a script
# that breaks on Apple's release schedule rather than on ours — and it did:
# the first CI run of this file died because the macOS image had moved to the
# 17 line and no iPhone 16 existed on it.
#
# The rule: newest iOS runtime, and among its iPhones the plainest model — no
# Pro, no Max, no Air, no "e". That is the closest thing to a baseline device
# and it survives the line moving from 16 to 17 to whatever comes next.
#
# It prints what it chose, which is the other half of the bargain: a rule that
# picks silently trades one problem for another, because a run whose device
# nobody can name is a run whose failures cannot be compared with yesterday's.
#
# A simulator already booted wins over the rule — somebody debugging has one
# open and means to use it.
_pick_simulator() {
  python3 - "$1" <<'PY'
import json, re, subprocess, sys

state = sys.argv[1]
out = subprocess.run(
    ["xcrun", "simctl", "list", "devices", state, "-j"],
    capture_output=True, text=True,
)
if out.returncode != 0:
    sys.exit(1)
devices = json.loads(out.stdout)["devices"]
runtimes = sorted(
    (k for k in devices if "iOS" in k),
    key=lambda k: [int(n) for n in re.findall(r"\d+", k)],
)
if not runtimes:
    sys.exit(1)
if state == "booted":
    # iOS only: a booted Apple Watch or Apple TV is still a booted device, and
    # handing one to `patrol test` fails in Xcode's words rather than here.
    booted = [x for k in runtimes for x in devices[k]]
    if not booted:
        sys.exit(1)
    print(booted[0]["udid"], booted[0]["name"], "already booted", sep="|")
    sys.exit(0)
phones = [x for x in devices[runtimes[-1]] if x["name"].startswith("iPhone")]
plain = [x for x in phones if re.fullmatch(r"iPhone \d+", x["name"])]
best = plain or phones
if not best:
    sys.exit(1)
print(best[-1]["udid"], best[-1]["name"], runtimes[-1], sep="|")
PY
}

if [[ -z "$DEVICE" ]]; then
  CHOICE="$(_pick_simulator booted || _pick_simulator available || true)"
  if [[ -z "$CHOICE" ]]; then
    echo "No iOS simulator available. Install one from Xcode:" >&2
    echo "  Xcode ▸ Settings ▸ Components ▸ iOS Simulator" >&2
    echo "and check with 'xcrun simctl list devices available'." >&2
    exit 1
  fi
  DEVICE="${CHOICE%%|*}"
  echo "Simulator: ${CHOICE#*|}"
fi

# Booting one already booted is not an error, so this needs no check of its
# own — and waiting for it is not optional: `patrol test` against a device
# still booting fails in Xcode's words rather than waiting.
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null 2>&1 || true

packages/e2e_framework/tool/e2e/clean.sh ios

mkdir -p "$OUT"
DEVICE_NAME="$(xcrun simctl list devices -j \
  | python3 -c "import json,sys
d = json.load(sys.stdin)['devices']
print(next((x['name'] for v in d.values() for x in v if x['udid'] == '$DEVICE'), '$DEVICE'))" \
  2>/dev/null || echo "$DEVICE")"
echo "Running on $DEVICE_NAME ($DEVICE)"

# Started BEFORE the run, and this is the ordering that matters: `log stream`
# is a live tap with no history behind it, so anything printed before it
# attaches is gone. The sleep gives it time to attach — without it the first
# test's markers are a coin toss.
#
# `--predicate` narrows to the app's own process. Everything else the
# simulator says is noise, and noise is what gets the app's own lines
# throttled away.
#
# `--style compact` keeps one line per message: the parser reads markers line
# by line, and the default style wraps.
xcrun simctl spawn "$DEVICE" log stream \
  --style compact \
  --predicate "subsystem == \"$BUNDLE_ID\" OR processImagePath CONTAINS \"$BUNDLE_ID\"" \
  > "$LOG" 2>/dev/null &
LOG_PID=$!
trap 'kill "$LOG_PID" 2>/dev/null || true' EXIT
sleep 2

status=0
set +e
(cd "$APP_DIR" && patrol test --device "$DEVICE" \
   "${TAGS[@]+"${TAGS[@]}"}" "${WIP_DEFINE[@]+"${WIP_DEFINE[@]}"}")
status=$?
set -e

# Give the stream a moment to flush whatever the last test emitted.
sleep 2
kill "$LOG_PID" 2>/dev/null || true
trap - EXIT

LINES="$(wc -l < "$LOG" | tr -d ' ')"
echo "Device log captured at $LOG ($LINES lines)"

# An empty log is worth saying out loud rather than leaving to be discovered
# in an empty report. os_log throttling and a predicate that matches nothing
# look identical from here, and both end the same way.
if [[ "$LINES" -lt 5 ]]; then
  echo >&2
  echo "The device log is essentially empty, so the report will be too." >&2
  echo "Either the predicate matched nothing — check that the bundle id" >&2
  echo "  $BUNDLE_ID" >&2
  echo "is the one the app was installed under — or os_log throttled the" >&2
  echo "app's output away. See the note at the top of this script." >&2
fi

echo
echo "── Building the report ───────────────────────────────────────────────"
dart run e2e_test_reporter --input "$LOG" --format patrol-log --platform ios \
  || echo "The report could not be built (the suite exited with $status)." >&2

echo
echo "Report:"
echo "  build/e2e/ios/e2e_test_reporter/report  ·  melos run openReportIos"
exit "$status"

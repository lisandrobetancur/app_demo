#!/usr/bin/env bash
#
# Runs the web suite and NARRATES it: every line of output arrives stamped
# with the elapsed time, and when the run goes quiet the script says so, and
# for how long. That warning is the point — the hang this suite has suffered
# does not fail, it goes SILENT until the test timeout expires, and the only
# way to see it happening (rather than 43 minutes later) is to watch for the
# silence itself.
#
#   packages/e2e_framework/tool/e2e/watch_web.sh [any run_web.sh flag]
#
# It takes exactly the flags run_web.sh takes and hands them straight over:
#
#   packages/e2e_framework/tool/e2e/watch_web.sh --tags=probe --profile
#
# Reading the output:
#
#   [03:12] ✓ 3 [chromium] › ...     the line, and WHEN it arrived
#   [05:00] ⏳ quiet for 90s ...      nothing has been printed for that long
#
# Quiet is normal WHILE a test runs — the list reporter only speaks when one
# finishes — so the warning starts at 90s, under the 120s per-test timeout
# (PATROL_WEB_TIMEOUT): first a heads-up, and if the timeout then expires the
# run itself will say so. Tune it with STALL_AFTER=<seconds> in front.
#
# The exit code is the suite's, untouched, so this wraps `melos run e2eWeb`
# without changing what CI or a script chained after it would see.
#
# HOW it watches matters, because of where it runs: macOS ships bash 3.2
# (Apple froze it there over the GPLv3), and in 3.2 a `read -t` that times
# out is indistinguishable from end-of-file. The first version of this script
# leaned on that and killed a healthy run with SIGPIPE eighteen seconds in.
# So no `read -t`: the reader below blocks like any pipe reader, and a
# separate watchdog process measures the silence by the age of a timestamp
# the reader refreshes on every line.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

STALL="${STALL_AFTER:-90}"
START=$(date +%s)

elapsed() {
  local s=$(( $(date +%s) - START ))
  printf '%02d:%02d' $((s / 60)) $((s % 60))
}

# The reader touches this on every line; the watchdog reads its age.
LAST_FILE="$(mktemp)"
date +%s > "$LAST_FILE"

(
  warned=0
  while :; do
    sleep 5
    last="$(cat "$LAST_FILE" 2>/dev/null)" || exit 0
    [ -n "$last" ] || continue
    quiet=$(( $(date +%s) - last ))
    if [ "$quiet" -lt "$STALL" ]; then
      warned=0
      continue
    fi
    # One warning as STALL is crossed, then another every further STALL.
    if [ "$quiet" -ge $((warned + STALL)) ]; then
      warned=$quiet
      printf '[%s] ⏳ quiet for %ss — the per-test timeout is %ss; silence past that is the hang\n' \
        "$(elapsed)" "$quiet" "$(( ${PATROL_WEB_TIMEOUT:-120000} / 1000 ))"
    fi
  done
) &
WATCHDOG=$!
trap 'kill "$WATCHDOG" 2>/dev/null; rm -f "$LAST_FILE"' EXIT

bash packages/e2e_framework/tool/e2e/run_web.sh "$@" 2>&1 | {
  while IFS= read -r line; do
    now=$(date +%s)
    quiet=$(( now - $(cat "$LAST_FILE") ))
    if [ "$quiet" -ge "$STALL" ]; then
      printf '[%s] ▶ output resumed after %ss of silence\n' "$(elapsed)" "$quiet"
    fi
    echo "$now" > "$LAST_FILE"
    printf '[%s] %s\n' "$(elapsed)" "$line"
  done
}

status=${PIPESTATUS[0]}
printf '[%s] run finished with exit code %s\n' "$(elapsed)" "$status"
exit "$status"

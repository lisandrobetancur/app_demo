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
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

STALL="${STALL_AFTER:-90}"
START=$(date +%s)

elapsed() {
  local s=$(( $(date +%s) - START ))
  printf '%02d:%02d' $((s / 60)) $((s % 60))
}

echo "[00:00] watching: run_web.sh $*"

bash packages/e2e_framework/tool/e2e/run_web.sh "$@" 2>&1 | {
  quiet=0
  while :; do
    if IFS= read -r -t 5 line; then
      if (( quiet >= STALL )); then
        printf '[%s] ▶ output resumed after %ss of silence\n' \
          "$(elapsed)" "$quiet"
      fi
      quiet=0
      printf '[%s] %s\n' "$(elapsed)" "$line"
    else
      code=$?
      # `read` answers >128 on timeout; anything lower is EOF — the run ended.
      (( code <= 128 )) && break
      quiet=$((quiet + 5))
      if (( quiet % STALL == 0 )); then
        printf '[%s] ⏳ quiet for %ss — the per-test timeout is %ss; silence past that is the hang\n' \
          "$(elapsed)" "$quiet" "$(( ${PATROL_WEB_TIMEOUT:-120000} / 1000 ))"
      fi
    fi
  done
}

status=${PIPESTATUS[0]}
printf '[%s] run finished with exit code %s\n' "$(elapsed)" "$status"
exit "$status"

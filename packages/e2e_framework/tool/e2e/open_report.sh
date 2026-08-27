#!/usr/bin/env bash
#
# Opens a generated report in the default browser.
#
#   packages/e2e_framework/tool/e2e/open_report.sh <path/to/index.html>
#
# The report is a static, self-contained site, so opening it is opening a
# file — no server, nothing left running afterwards. This exists only because
# the command for that differs per platform, and because a missing report
# should say which command builds it rather than opening a blank tab.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

REPORT="${1:-}"

if [[ -z "$REPORT" ]]; then
  echo "usage: packages/e2e_framework/tool/e2e/open_report.sh <path/to/index.html>" >&2
  exit 2
fi

if [[ ! -f "$REPORT" ]]; then
  echo "No report at $REPORT" >&2
  echo >&2
  echo "Run the suite, which builds it:" >&2
  case "$REPORT" in
    *android*) echo "  melos run e2eAndroid    # or, from results already on disk: melos run reportAndroid" >&2 ;;
    *)         echo "  melos run e2eWeb        # or, from results already on disk: melos run reportWeb" >&2 ;;
  esac
  exit 1
fi

case "$OSTYPE" in
  darwin*) open "$REPORT" ;;
  msys* | cygwin*) start "" "$REPORT" ;;
  *)
    if command -v xdg-open > /dev/null; then
      xdg-open "$REPORT"
    else
      # A headless machine is the normal case in CI and on a remote shell:
      # print the path rather than failing on a browser nobody can see.
      echo "No browser opener here. The report is at:"
      echo "  file://$PWD/$REPORT"
    fi
    ;;
esac

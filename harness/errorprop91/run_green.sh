#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# harness/errorprop91/run_green.sh -- drives driver.praat against the real,
# currently-shipped plugin tree (the repo's own plugin/ symlink).
#
#     bash harness/errorprop91/run_green.sh
#
# Output: harness/errorprop91/out/green/report.txt (committed).
# ---------------------------------------------------------------------------
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
source "$REPO/harness/_env.sh"

mkdir -p "$HERE/out/green"
(cd "$REPO" && EML_ERRORPROP91_OUT=out/green \
    "$PRAAT" $PRAAT_TRUST --run harness/errorprop91/driver.praat)
echo "wrote $HERE/out/green/report.txt"

#!/usr/bin/env bash
# ============================================================================
# harness/resultmaxrow/run.sh -- drive the result-store row-cap probe
# ============================================================================
#   harness/resultmaxrow/run.sh          drive the tree this file sits in
#   EML_MAXROW_OUT=<dir> ... run.sh      write the artefact somewhere else
#
# Praat resolves through harness/_env.sh; there is no bare praat on PATH.
# ============================================================================
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_env.sh"

out="${EML_MAXROW_OUT:-$here/out}"
mkdir -p "$out"

"$PRAAT" $PRAAT_TRUST --run "$here/probe.praat" "$out"
echo "wrote $out/MAXROW.tsv"

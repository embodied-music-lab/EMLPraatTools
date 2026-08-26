#!/usr/bin/env bash
# ============================================================================
# harness/resultstore/run.sh -- drive the result-store probe
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   harness/resultstore/run.sh          drive the tree this file sits in
#   EML_STORE_OUT=<dir> ... run.sh      write the artefact somewhere else
#
# THE PROBE INCLUDES ITS OWN TREE by relative path, so a seeded copy is driven
# by running the COPY's run.sh -- see seed_violation.sh, which does exactly
# that. There is deliberately no way to point this tree's probe at another
# tree's plugin: that mix-up rendered figures from the wrong build once
# already (harness/_env.sh records it).
#
# Praat resolves through harness/_env.sh; there is no bare praat on PATH.
# ============================================================================
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_env.sh"

out="${EML_STORE_OUT:-$here/out}"
mkdir -p "$out"

"$PRAAT" $PRAAT_TRUST --run "$here/probe.praat" "$out"
echo "wrote $out/STORE.tsv"

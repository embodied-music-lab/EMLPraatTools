#!/usr/bin/env bash
# ============================================================================
# harness/bridgeconsume/run.sh -- drive the bridge-consumption probe
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   harness/bridgeconsume/run.sh              drive the tree this file sits in
#   EML_CONSUME_OUT=<dir> ... run.sh          write the artefact somewhere else
#
# The probe includes its own tree by relative path, so a seeded copy is driven
# by running the COPY's run.sh. Praat resolves through harness/_env.sh; there
# is no bare praat on PATH.
# ============================================================================
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_env.sh"

out="${EML_CONSUME_OUT:-$here/out}"
mkdir -p "$out"

"$PRAAT" $PRAAT_TRUST --run "$here/probe.praat" "$out"
echo "wrote $out/CONSUME.tsv"

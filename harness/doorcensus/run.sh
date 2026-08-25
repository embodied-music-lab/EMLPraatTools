#!/usr/bin/env bash
# ============================================================================
# harness/doorcensus/run.sh -- drive the door-agreement census probe
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Runs harness/doorcensus/probe.praat and leaves DOORCENSUS.tsv beside it.
# The probe needs no display -- it calls the analysis kernels directly on
# six committed adversarial fixtures (harness/doorcensus/fixtures/*.csv)
# and writes what came out; it draws nothing and opens no dialog.
#
#   $EML_DOORCENSUS_SRC   plugin tree to measure   (default: the shipped one)
#   $EML_DOORCENSUS_OUT   artefact to write        (default: out/DOORCENSUS.tsv)
#
# Both are the variables validate/v127_door_agreement_census.R reads, so a
# seeded copy (for a red demonstration) is pointed at once and both ends
# follow it -- same convention as harness/settings and harness/coldstart.
#
#   bash harness/doorcensus/run.sh
#   Rscript validate/v127_door_agreement_census.R
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../_env.sh"

OUT="${EML_DOORCENSUS_OUT:-$SCRIPT_DIR/out/DOORCENSUS.tsv}"
mkdir -p "$(dirname "$OUT")"

# THE PROBE RESOLVES ITS INCLUDES RELATIVE TO ITS OWN FOLDER, two levels up
# into plugin/. Measuring a tree other than the shipped one therefore means
# running a COPY of the probe that sits two levels under that tree, not
# passing a path in -- the same discipline harness/settings/run.sh uses.
# $EML_DOORCENSUS_SRC names the root the copy is made under.
SRC="${EML_DOORCENSUS_SRC:-}"
if [ -n "$SRC" ]; then
    RUNDIR="$SRC/harness/doorcensus"
    mkdir -p "$RUNDIR"
    cp "$SCRIPT_DIR/probe.praat" "$RUNDIR/probe.praat"
else
    RUNDIR="$SCRIPT_DIR"
fi

EML_DOORCENSUS_OUT="$OUT" "$PRAAT" $PRAAT_TRUST --run "$RUNDIR/probe.praat"
rc=$?
if [ $rc -ne 0 ]; then
    echo "doorcensus/run.sh: praat exited $rc" >&2
    exit $rc
fi
echo "doorcensus/run.sh: wrote $OUT ($(wc -l < "$OUT") lines)"

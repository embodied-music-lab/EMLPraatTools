#!/usr/bin/env bash
# ============================================================================
# harness/settings/run.sh -- drive the settings probe
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Runs harness/settings/probe.praat and leaves SETTINGS.tsv beside it. The
# probe needs no display: it computes and writes, and draws nothing.
#
#   $EML_SETTINGS_SRC   plugin tree to measure   (default: the shipped one)
#   $EML_SETTINGS_OUT   artefact to write        (default: out/SETTINGS.tsv)
#
# Both are the variables validate/v112_settings_census.R reads, so a seeded
# copy is pointed at once and both ends follow it.
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

OUT="${EML_SETTINGS_OUT:-$SCRIPT_DIR/out/SETTINGS.tsv}"
mkdir -p "$(dirname "$OUT")"

# THE PROBE RESOLVES ITS INCLUDES RELATIVE TO ITS OWN FOLDER, two levels up
# into plugin/. Measuring a tree other than the shipped one therefore means
# running a COPY of the probe that sits two levels under that tree, not
# passing a path in -- the same discipline harness/stress_cases/_prelude.praat
# is written to. $EML_SETTINGS_SRC names the root the copy is made under.
SRC="${EML_SETTINGS_SRC:-}"
if [ -n "$SRC" ]; then
    RUNDIR="$SRC/harness/settings"
    mkdir -p "$RUNDIR"
    cp "$SCRIPT_DIR/probe.praat" "$RUNDIR/probe.praat"
else
    RUNDIR="$SCRIPT_DIR"
fi

EML_SETTINGS_OUT="$OUT" "$PRAAT" $PRAAT_TRUST --run "$RUNDIR/probe.praat"
rc=$?
if [ $rc -ne 0 ]; then
    echo "settings/run.sh: praat exited $rc" >&2
    exit $rc
fi
echo "settings/run.sh: wrote $OUT ($(wc -l < "$OUT") lines)"

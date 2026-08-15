#!/usr/bin/env bash
# ============================================================================
# harness/graphaxes/axes.sh — render the four axis and annotation findings
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One Praat process per leg, for the reason harness/stress_graphs.sh gives:
# a Praat script error aborts the script, so five legs in one process report
# one failure and hide four. A second here buys an independent verdict.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. DISPLAY is unset for every leg
# rather than merely ignored, which proves the claim as well as relying on it
# — and stops a stray connection to whatever interactive instance another
# harness has open. The one part of this work that DOES need a display, the
# stereo dialog, is in stereo.sh and says so.
#
# $EML_GRAPHS_SRC points the drive at a different copy of plugin/graphs, which
# is how validate/v62's break tests render a deliberately broken library
# without touching the tree.
#
# Run from anywhere:  bash harness/graphaxes/axes.sh
# Output: harness/graphaxes/out/AXES.tsv   read by validate/v62
#         harness/graphaxes/out/pic_*.png  the figures themselves
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

OUT="${EML_AXES_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
DRIVE="${EML_GRAPHS_DRIVE:-$SCRIPT_DIR/axes_drive.praat}"

mkdir -p "$OUT" "$PREFS"
TSV="$OUT/AXES.tsv"
: > "$TSV"
printf 'praat_version\t%s\n' "$("$PRAAT" --version 2>&1 | head -1)" >> "$TSV"

for leg in steady ramp2 ticks clip collide; do
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    env -u DISPLAY \
        EML_AXES_LEG="$leg" EML_AXES_OUT="$TSV" \
        EML_AXES_PIC="$OUT/pic_$leg.png" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1
done

echo "axes: wrote $TSV"
grep -c . "$TSV" | sed 's/^/axes: rows /'
exit 0

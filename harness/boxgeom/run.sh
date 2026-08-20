#!/usr/bin/env bash
# ============================================================================
# harness/boxgeom/run.sh — one vector figure per graph type, kept as numbers
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE SUBJECT. Praat converts a viewport using the margins in effect when the
# viewport is SELECTED, and converts back using the margins in effect at each
# drawing command. Margin width is a function of font size. So a figure whose
# ambient font size changes between two coordinate-dependent commands puts
# those commands on two different rectangles, and nothing anywhere errors: the
# frame comes out inside its own gridlines, or the tick marks stand clear of
# the axis they belong to. That defect is invisible to every check that reads
# source, and invisible to a pixel count that only asks whether ink arrived.
#
# EPS, NOT PNG, AND THAT IS THE WHOLE METHOD. Praat's EPS states every path as
# device coordinates, so the inner box, each tick mark and each stroke of data
# are three independent witnesses to one rectangle, readable as numbers. A
# PNG of the same figure would need a pixel hunt to find the frame and could
# not tell a tick anchored on the axis from one a thousandth of an inch off it.
#
# Run from anywhere:  bash harness/boxgeom/run.sh [case-substring]
#
# THE FILTER IS FOR DEBUGGING ONE CASE AND LEAVES A PARTIAL ARTEFACT. The TSV
# is rewritten from scratch on every run; validate/v100 censuses the cases it
# finds against the ones it asserts on and goes red on the difference.
#
# Output: harness/boxgeom/out/<case>.eps, <case>.log
#         harness/boxgeom/out/BOXGEOM.tsv    case, key, value
# Exit 0 = every case drew and saved.
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
OUT="${EML_BOXGEOM_DIR:-$SCRIPT_DIR/out}"
FILTER="${1:-}"
mkdir -p "$OUT"
TSV="$OUT/BOXGEOM.tsv"

# THE ARTEFACT IS BUILT BESIDE ITSELF AND MOVED INTO PLACE, the way
# harness/linestyle/run.sh builds its own: a reader must never see a
# half-written file, and must never see the previous run's rows under this
# one's.
TMP="$OUT/.BOXGEOM.$$.tsv"
: > "$TMP"

fail=0
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TMP"; }

# EVERY CASE IS ITS OWN PRAAT PROCESS. A Praat script error aborts the script,
# so a single process running thirteen cases reports one failure and hides the
# twelve after it.
run_case () {
    local c=$1
    [ -z "$FILTER" ] || case "$c" in *"$FILTER"*) ;; *) return 0 ;; esac
    rm -f "$OUT/$c.eps"
    EML_OUT="$OUT/$c.eps" timeout 600 xvfb-run -a "$PRAAT" $PRAAT_TRUST \
        --run "$SCRIPT_DIR/$c.praat" > "$OUT/$c.log" 2>&1
    local rc=$?
    if [ $rc -ne 0 ] || [ ! -s "$OUT/$c.eps" ]; then
        printf '  %-16s FAILED rc=%s\n' "$c" "$rc"
        tail -4 "$OUT/$c.log" | sed 's/^/      /'
        fail=1
        return 0
    fi
    # THE CLAIMS THE CASE MADE, LIFTED OUT OF ITS OWN LOG rather than restated
    # here. @bgSave prints them; a driver that retyped them could disagree with
    # the figure it just rendered and nothing would notice.
    emit "$c" eps "$c.eps"
    emit "$c" type    "$(sed -n 's/^TYPE //p'      "$OUT/$c.log" | tail -1)"
    emit "$c" reach   "$(sed -n 's/^REACH //p'     "$OUT/$c.log" | tail -1)"
    emit "$c" declinner "$(sed -n 's/^DECLINNER //p' "$OUT/$c.log" | tail -1)"
    emit "$c" bodysize  "$(sed -n 's/^BODYSIZE //p'  "$OUT/$c.log" | tail -1)"
    printf '  %-16s ok\n' "$c"
}

# ONE CASE PER GRAPH TYPE, IN THE FORM'S OWN ORDER (graphTypeName$[1..13] in
# eml-graphs-form.praat). Named for the type rather than numbered, because a
# red line that says "waveform" is worth more than one that says "case 2".
echo "harness/boxgeom — one vector figure per graph type"
run_case pitch_contour
run_case waveform
run_case spectrum
run_case ltas
run_case line_chart
run_case bar_chart
run_case violin
run_case scatter
run_case box_plot
run_case histogram
run_case grouped_violin
run_case grouped_box
run_case spaghetti

mv -f "$TMP" "$TSV"
rows=$(wc -l < "$TSV")
echo "  wrote $TSV ($rows rows)"
exit $fail

#!/bin/bash
# ---------------------------------------------------------------------------
# Normality driver -- the GUI half: check-normality's PER-GROUP mode. D137.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   harness/normality/run.sh            # FIRST -- writes out/data/*.csv
#   harness/normality/pergroup.sh       # then this
#
# The third call site of the normality rule is the per-group branch of
# plugin/scripts/eml-check-normality.praat. It is not a procedure: it is
# inline in a wrapper whose first statement is `beginPause:`, and
# `praat --run` cannot open a display connection at all -- confirmed again on
# 8 Aug 2026, Praat 6.4.06, WITH an Xvfb display exported:
#
#     Gtk-ERROR: Can't create a GtkStyleContext without a display connection
#     Trace/breakpoint trap, exit 133
#
# So this half runs a real GUI instance and clicks. Each case is driven
# TWICE over the SAME out/data/<case>.csv file:
#
#     overall   Group column = "(none - overall only)"   -> the else branch,
#               @emlRunNormalityAnalysis
#     grouped   Group column = "grp"                     -> the per-group
#               branch, @emlNormalityRecommendation per group
#
# and on every case but p01_groups the `grp` column holds ONE group, "All",
# covering every row. The two modes therefore analyse the identical vector,
# which is what turns "the two modes agree" into a statement about the rule.
# Until 8 August they did not agree: a group with |skew| between 1 and 2 that
# Shapiro-Wilk declined to reject came out "Nonparametric recommended" here
# and "parametric" from the very same script's overall mode. d01_skew and
# d02_kurt are those numbers.
#
# Rig: harness/walks/rig.sh instance 1 (:91) and harness/walks/d117/lib.sh,
# the same primitives the D117 and gridmode walks use. Nothing new is
# invented here; `launch`, `pwin`, `popt`, `pbtn` and `infodump` are theirs.
#
# Output: harness/normality/out/pergroup/
#   <case>_overall.txt   Info window verbatim, overall mode
#   <case>_grouped.txt   Info window verbatim, per-group mode
#   RESULTS.tsv          case<TAB>mode<TAB>verdict<TAB>bytes
#                        verdict is OK, NO_DIALOG, WRONG_PAGE or NO_CAPTURE,
#                        so a walk that mis-drove is a recorded fact rather
#                        than a short file the validator reads as evidence.
# ---------------------------------------------------------------------------
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
NOUT=${EML_NORMALITY_OUT:-$HERE/out}
PG="$NOUT/pergroup"
I=${I:-1}
FILTER="${1:-}"

export I REPO
# lib.sh reads OUT for its own screenshot helper and would otherwise default
# to evidence/walks/d117. It is set to this harness's own folder and kept in
# a DIFFERENT variable from the harness output root: an earlier revision of
# this file used one name for both and every case reported NO_INPUT, because
# out/data had become out/pergroup/data.
export OUT="$PG"
. "$REPO/harness/walks/d117/lib.sh"

mkdir -p "$PG"
[ -n "$FILTER" ] || : > "$PG/RESULTS.tsv"

# The GUI set. Not every case: the wrapper refuses a table with no numeric
# column through `exitScript`, which paints an error dialog and leaves the
# Info window empty, so r01_blank and r06_text have nothing for this half to
# capture. They are covered headlessly by case.praat, and this limit is
# stated rather than left to be discovered.
#
#   d01_skew d02_kurt   THE D137 REGION -- the load-bearing pair
#   g01_normal          a control that was never in dispute
#   g03_severe          both modes must say nonparametric
#   p01_groups          three real groups, one of them n = 2
GUI_CASES="d01_skew d02_kurt g01_normal g03_severe p01_groups"

# Group column menu indices. The optionmenu is built as
#   1  (none - overall only)
#   2  grp          <- the table's first column
#   3  y
# from `for iCol from 1 to nCols` over the table's own column order, and
# case.praat writes "grp y" in that order. Read off the wrapper, not guessed.
MENU_NONE=1
MENU_GRP=2

# rig up if this instance is not already serving
if ! DISPLAY=":9$I" xdpyinfo >/dev/null 2>&1; then
    echo "bringing up rig instance $I"
    REPO="$REPO" "$REPO/harness/walks/rig.sh" up "$I" >/dev/null || {
        echo "pergroup.sh: rig instance $I would not come up" >&2; exit 1; }
fi

# drive_one <case> <mode> <menu-index>
drive_one () {
    local c=$1 mode=$2 item=$3
    local csv="$NOUT/data/$c.csv" cap="$PG/${c}_${mode}.txt"
    rm -f "$cap"
    if [ ! -s "$csv" ]; then
        printf '%s\t%s\t%s\t%s\n' "$c" "$mode" NO_INPUT 0 >> "$PG/RESULTS.tsv"
        printf '  %-14s %-8s %s\n' "$c" "$mode" NO_INPUT
        return
    fi

    EML_NORM_CSV="$csv" launch "$HERE/pergroup_case.praat"

    # Page 1 -- the entry form. Buttons: Undo, Quit, Run (Praat adds Undo to
    # every pause window, so a two-button endPause is a THREE-button row).
    local t; t=$(ptitle)
    if [ "$t" != "Pause: Check Normality" ]; then
        printf '%s\t%s\t%s\t%s\n' "$c" "$mode" NO_DIALOG 0 >> "$PG/RESULTS.tsv"
        printf '  %-14s %-8s %s [%s]\n' "$c" "$mode" NO_DIALOG "$t"
        return
    fi
    popt 1 "$item" 1
    pbtn 3 3 4

    # Page 2 -- the completion dialog. Buttons: Undo, Done, Draw, New.
    t=$(ptitle)
    if [ "$t" != "Pause: Normality assessment complete" ]; then
        printf '%s\t%s\t%s\t%s\n' "$c" "$mode" WRONG_PAGE 0 >> "$PG/RESULTS.tsv"
        printf '  %-14s %-8s %s [%s]\n' "$c" "$mode" WRONG_PAGE "$t"
        return
    fi
    pbtn 2 4 3

    infodump "$cap"
    local bytes=0
    [ -f "$cap" ] && bytes=$(wc -c < "$cap")
    local verdict=OK
    [ "$bytes" -gt 200 ] || verdict=NO_CAPTURE
    printf '%s\t%s\t%s\t%s\n' "$c" "$mode" "$verdict" "$bytes" >> "$PG/RESULTS.tsv"
    printf '  %-14s %-8s %s (%s bytes)\n' "$c" "$mode" "$verdict" "$bytes"
}

for c in $GUI_CASES; do
    [ -n "$FILTER" ] && case "$c" in *"$FILTER"*) ;; *) continue ;; esac
    drive_one "$c" overall "$MENU_NONE"
    drive_one "$c" grouped "$MENU_GRP"
done

echo "per-group captures written to $PG"

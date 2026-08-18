#!/usr/bin/env bash
# ============================================================================
# harness/linestyle/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect in it,
# driven through its own copy of harness/linestyle and scored by validate/v96
# through $EML_LS_DIR and $EML_LS_SRC. The working tree is never touched and
# never has to be, which is the point: a break test that edits the tree and
# puts it back is one interrupted run away from committing a defect.
#
# THE BREAKS, AND WHAT EACH ONE IS FOR.
#
#   pen_ignored      -- @emlApplyLineStyle reduced to `Solid line` whatever it
#                       was asked for. THE DEFECT CLASS THE CHANGE ORDER NAMES:
#                       a control that is offered, accepted and recorded, and
#                       changes nothing on the page. Every dotted figure comes
#                       back identical to its solid twin.
#
#   styles_swapped   -- Dashed and Dashed-dotted wired to each other's Praat
#                       command. THE BREAK THAT ARGUES FOR THIS FILE'S WHOLE
#                       METHOD: the four figures are still four different
#                       files, the four ink counts are still four different
#                       numbers, and every "is it distinct" check stays green.
#                       Only the ORDER catches it -- how much of the path each
#                       pen inks, and how many marks it breaks into.
#
#   no_draw_reset    -- every @emlResetLineStyle call in the drawing library
#                       commented out. The pen then survives the figure it was
#                       set for: the frame drawn after the series is broken,
#                       and so is the next figure in the same session, whose
#                       own code sets no pen at all.
#
#   no_form_reset    -- the pen line taken out of @emlGraphsResetSeriesPens.
#                       INVISIBLE TO EVERY CASE THAT PRESSES DRAW, because a
#                       press states the whole request and publishes Solid over
#                       the leak. What sees it is the caller that never
#                       presses -- a stats wrapper, a probe, a replayed script
#                       -- which reads emlLineStyle without ever setting it.
#                       That pair of cases exists for this break.
#
#   menu_removed     -- the LTAS dialog's option menu deleted. A type that
#                       strokes a series and offers no pen. Caught statically,
#                       and it has to be: the LTAS would go on drawing solid
#                       lines quite correctly.
#
#   Run:  bash harness/linestyle/break.sh [name-substring]
#   Out:  harness/linestyle/out/BREAKS.tsv   break, red count, first failure
#         harness/linestyle/out/break_<name>.v96.log
#
# A FULL DRIVE PER BREAK IS SEVEN MINUTES. The filter argument runs one break;
# with no argument every break runs in turn and the file is rewritten.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$HERE/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$HERE/out"
WORK="${TMPDIR:-/tmp}/eml-linestyle-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

GRAPH=plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
DRAW=plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
FORM=plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus .git and the
# heavy output folders. A break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=evidence --exclude=harness/stress_out \
        --exclude=harness/linestyle/out --exclude=harness/secondaxis/out \
        --exclude=harness/compose/out --exclude=harness/dialogheight/out \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/linestyle/out"
}

# edit <tree> <path> <sed-script> — one deliberate defect, and a loud complaint
# if it changed nothing. An edit that does not bite makes a break go green for
# the worst possible reason: the tree it was driven on was the correct one.
edit () {
    local n=$1 rel=$2 script=$3
    local f="$WORK/$n/$rel"
    cp "$f" "$f.orig"
    sed -i "$script" "$f"
    if cmp -s "$f" "$f.orig"; then
        printf '  %-20s !! EDIT IS A NO-OP: %s\n' "$n" "$rel"
    fi
    rm -f "$f.orig"
}

# run_break <name> — drive the shadow's harness and score validate/v96 on it.
run_break () {
    local n=$1
    local o="$WORK/$n/harness/linestyle/out"
    EML_LINESTYLE_DIR="$o" timeout 1200 bash \
        "$WORK/$n/harness/linestyle/run.sh" > "$o/drive.log" 2>&1
    EML_VALIDATE_DIR="$ROOT/validate" \
    EML_LS_DIR="$o" EML_LS_SRC="$WORK/$n/plugin_EML_StatsGraphs" \
        Rscript "$ROOT/validate/v96_line_style.R" \
        > "$OUT/break_$n.v96.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v96.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v96.log" \
            | sed 's/^FAIL[[:space:]]*v96[[:space:]]*//; s/[[:space:]]*computed=.*$//')
    [ -n "$first" ] || first="(nothing went red)"
    # ONE ROW PER BREAK, WHOEVER RAN IT AND IN WHATEVER ORDER. Running a
    # single break by name is the normal way to use this file -- a full drive
    # is seven minutes each -- so an appending writer leaves a record in which
    # the same break appears three times with three different verdicts and
    # nothing says which one is now true. The row is replaced instead.
    if [ -s "$TSV" ]; then
        grep -v "^$n	" "$TSV" > "$TSV.keep" 2>/dev/null
        mv -f "$TSV.keep" "$TSV"
    fi
    printf '%s\t%s\t%s\n' "$n" "$red" "$first" >> "$TSV"
    printf '  %-20s red=%-4s %s\n' "$n" "$red" "$first"
    # A BREAK THAT PRODUCED NO RED IS THE FINDING, not a pass. Said here as
    # well as in the file, because the file is read later and this is read now.
    if [ "$red" -eq 0 ]; then
        printf '  %-20s !! THIS BREAK IS INVISIBLE TO v96 -- the check it was\n' "$n"
        printf '  %-20s !! meant to exercise does not exist or does not bite.\n' ""
    fi
}

want () { [ -z "$FILTER" ] && return 0; case "$1" in *"$FILTER"*) return 0 ;; esac; return 1; }

# ---------------------------------------------------------------------------
# 1. THE CONTROL THAT DOES NOTHING
# ---------------------------------------------------------------------------
if want pen_ignored; then
    shadow pen_ignored
    edit pen_ignored "$GRAPH" \
        '/^procedure emlApplyLineStyle:/,/^endproc/{s/^\( *\)Dotted line$/\1Solid line/; s/^\( *\)Dashed line$/\1Solid line/; s/^\( *\)Dashed-dotted line$/\1Solid line/}'
    run_break pen_ignored
fi

# ---------------------------------------------------------------------------
# 2. TWO PENS WIRED TO EACH OTHER'S COMMAND
# ---------------------------------------------------------------------------
# Still four styles, still four different pictures, still four different ink
# counts. The figure a user asked Dashed for comes back dash-dotted.
if want styles_swapped; then
    shadow styles_swapped
    # THE SWAP IN ONE SCRIPT, THROUGH A MARKER, AND THE ORDER IS THE WHOLE
    # TRICK. sed applies the three substitutions to each line in turn, so the
    # dash-dotted line becomes the marker and is then read back as Dashed,
    # while the dashed line becomes Dashed-dotted and is not touched again. A
    # straight two-way swap would send both branches to the same command.
    edit styles_swapped "$GRAPH" \
        '/^procedure emlApplyLineStyle:/,/^endproc/{s/^\( *\)Dashed-dotted line$/\1@@SWAP@@/; s/^\( *\)Dashed line$/\1Dashed-dotted line/; s/^\( *\)@@SWAP@@$/\1Dashed line/}'
    run_break styles_swapped
fi

# ---------------------------------------------------------------------------
# 3. THE PEN IS NEVER PUT BACK, INSIDE THE DRAWING LIBRARY
# ---------------------------------------------------------------------------
if want no_draw_reset; then
    shadow no_draw_reset
    edit no_draw_reset "$DRAW" 's/^\( *\)@emlResetLineStyle$/\1; @emlResetLineStyle -- REMOVED BY break.sh/'
    run_break no_draw_reset
fi

# ---------------------------------------------------------------------------
# 4. THE PEN IS NEVER PUT BACK, IN THE FORM
# ---------------------------------------------------------------------------
if want no_form_reset; then
    shadow no_form_reset
    edit no_form_reset "$FORM" \
        '/^procedure emlGraphsResetSeriesPens$/,/^endproc/s/^\( *\)emlLineStyle = 1$/\1; emlLineStyle = 1 -- REMOVED BY break.sh/'
    run_break no_form_reset
fi

# ---------------------------------------------------------------------------
# 5. A TYPE THAT STROKES A SERIES AND OFFERS NO PEN
# ---------------------------------------------------------------------------
if want menu_removed; then
    shadow menu_removed
    edit menu_removed "$FORM" '/optionmenu: "Line style", ltasLineStyle/,+4d'
    run_break menu_removed
fi

echo "BREAKS.tsv: $(wc -l < "$TSV") rows"

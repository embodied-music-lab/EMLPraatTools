#!/usr/bin/env bash
# ============================================================================
# harness/boxgeom/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE BREAK IS A COPY OF THE REPOSITORY with one deliberate defect in it,
# driven through its own copy of harness/boxgeom and scored by validate/v100
# through $EML_BG_DIR. The working tree is never touched and never has to be,
# which is the point: a break test that edits the tree and puts it back is one
# interrupted run away from committing a defect.
#
# THE BREAK, AND WHAT IT IS FOR.
#
#   box_font_plus_one -- @emlDrawInnerBoxIf asserts the body size PLUS ONE
#                        POINT before it draws. That is the whole defect class
#                        this harness exists for, stated in one character:
#                        ONE mid-figure change of the ambient font size,
#                        between the marks and the frame. Praat then converts
#                        the viewport for the frame using wider margins than
#                        it used for everything else on the page, so the frame
#                        lands on a rectangle about 2.9% narrower and 2.6%
#                        shorter than the one the ticks and the data are on.
#
#                        NOTHING ELSE IN THE TREE SEES IT. The figure saves,
#                        every file is the right size, every pixel count comes
#                        back plausible, and the wrapper it is planted in is
#                        the one whose own comment says it exists to prevent
#                        exactly this. The only witness is where the ink
#                        landed, which is what v100 reads.
#
#                        WHAT IT DOES NOT REACH, and why the second break
#                        exists: the marks are drawn AFTER the frame, so they
#                        inherit the changed size and land on the frame's
#                        rectangle. Every tick still anchors perfectly. It is
#                        the gridlines and the data, drawn before, that are
#                        left behind.
#
#   marks_font_plus_one -- the mirror. @emlDrawAlignedMarksBottom asserts a
#                        size one point up before it lays its marks, so the
#                        FRAME is right and the bottom ticks are on a
#                        rectangle of their own -- floating a fortieth of an
#                        inch off the axis, each one anchored on nothing.
#                        Containment never notices, because the data is still
#                        inside the frame it was drawn with. This is the break
#                        the anchoring assertion exists for.
#
#   Run:  bash harness/boxgeom/break.sh [name-substring]
#   Out:  harness/boxgeom/out/BREAKS.tsv      break, red count, first failure
#         harness/boxgeom/out/break_<name>.v100.log
#
# A BREAK THAT PRODUCES NO RED IS THE FINDING, not a pass, and this file says
# so in the log as well as in the TSV — the TSV is read later and the log is
# read now.
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
WORK="${TMPDIR:-/tmp}/eml-boxgeom-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

GRAPH=plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus .git and the
# heavy output folders. A break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=evidence --exclude=harness/stress_out \
        --exclude=harness/boxgeom/out --exclude=harness/linestyle/out \
        --exclude=harness/secondaxis/out --exclude=harness/vecfig/out \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/boxgeom/out"
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

run_break () {
    local n=$1
    local o="$WORK/$n/harness/boxgeom/out"
    EML_BOXGEOM_DIR="$o" timeout 1800 bash \
        "$WORK/$n/harness/boxgeom/run.sh" > "$o/drive.log" 2>&1
    EML_VALIDATE_DIR="$ROOT/validate" EML_BG_DIR="$o" \
        Rscript "$ROOT/validate/v100_box_geometry.R" \
        > "$OUT/break_$n.v100.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v100.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v100.log" \
            | sed 's/^FAIL[[:space:]]*v100[[:space:]]*//; s/[[:space:]]*computed=.*$//')
    [ -n "$first" ] || first="(nothing went red)"
    if [ -s "$TSV" ]; then
        grep -v "^$n	" "$TSV" > "$TSV.keep" 2>/dev/null
        mv -f "$TSV.keep" "$TSV"
    fi
    printf '%s\t%s\t%s\n' "$n" "$red" "$first" >> "$TSV"
    printf '  %-20s red=%-4s %s\n' "$n" "$red" "$first"
    if [ "$red" -eq 0 ]; then
        printf '  %-20s !! THIS BREAK IS INVISIBLE TO v100 -- the check it was\n' "$n"
        printf '  %-20s !! meant to exercise does not exist or does not bite.\n' ""
    fi
}

want () { [ -z "$FILTER" ] && return 0; case "$1" in *"$FILTER"*) return 0 ;; esac; return 1; }

if want box_font_plus_one; then
    n=box_font_plus_one
    shadow $n
    # ONE POINT, AT THE ONE SITE. @emlDrawInnerBoxIf's first line is the
    # assertion that the frame is drawn at the body size; adding a point to it
    # is the smallest possible statement of "the ambient size changed in the
    # middle of the figure".
    # THE EDIT IS ADDRESSED TO ONE PROCEDURE, not to the string. Twelve lines
    # in this file read `Font size: emlSetAdaptiveTheme.bodySize`, and one of
    # them is in @emlSetPanelViewport, BEFORE the viewport is selected.
    # Changing that one moves the select and every later command together, so
    # the whole figure lands on one consistent (if differently sized)
    # rectangle and the break goes green -- correctly, because nothing became
    # inconsistent. The defect is a change BETWEEN two coordinate-dependent
    # commands, so the edit has to name the procedure it belongs in.
    edit $n "$GRAPH" \
        '/^procedure emlDrawInnerBoxIf$/,/^endproc$/ s/^    Font size: emlSetAdaptiveTheme.bodySize$/    Font size: emlSetAdaptiveTheme.bodySize + 1/'
    run_break $n
fi

if want marks_font_plus_one; then
    n=marks_font_plus_one
    shadow $n
    # THE SAME ONE-POINT CHANGE, ON THE OTHER SIDE OF THE FRAME. Inserted
    # after the tick colour is set, inside the bottom-margin procedure only,
    # so the frame and the left margin are untouched and the difference
    # between the two rectangles has exactly one cause.
    edit $n "$GRAPH" \
        '/^procedure emlDrawAlignedMarksBottom:/,/^endproc$/ s/^    Colour: emlSetAdaptiveTheme.tickColor\$$/    Colour: emlSetAdaptiveTheme.tickColor$\n    Font size: emlSetAdaptiveTheme.bodySize + 1/'
    run_break $n
fi

echo "  wrote $TSV"

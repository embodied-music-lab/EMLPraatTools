#!/usr/bin/env bash
# ============================================================================
# harness/axisrefuse/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect, driven
# through $EML_AR_SRC and read by validate/v84 through $EML_AR_FORM and
# $EML_AR_DIR. The working tree is never touched and never has to be, which is
# the point: a break test that edits the tree and puts it back is one
# interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR.
#
#   swap_back — THE DEFECT ITSELF, on ONE pair. The value pair gets its swap
#   back, ahead of the sweep, and the other five are left repaired. This is
#   the mutation the whole file exists for, and it is deliberately partial: a
#   check that counted call sites, or that asserted "the form refuses
#   somewhere", would be green here because five pairs still refuse.
#
#   head_form — the whole form reverted to HEAD, which restores all six swaps
#   at once. The strongest available mutation of the subject.
#
#   refuse_but_draw — the refusal fires, the dialog appears, and the form
#   draws anyway: only `allFormsDone = 0` is removed. Every text assertion in
#   v84 is satisfied on this tree, and so is every ink assertion — the page IS
#   empty at the moment of the refusal, because the draw comes after it. The
#   sequence of dialog titles is what tells: "Axis range > Graph Complete".
#
#   numberless — the headline keeps every word and loses both numbers. This is
#   the shape a message acquires when somebody "tidies" it, and it is the one
#   a check that asserted "a dialog titled Axis range appeared" cannot see.
#
#   prose_only — the swap restored on the value pair with the whole paragraph
#   above the sweep left in place, including the sentences that explain why a
#   pair is refused rather than repaired. A check that greps the file without
#   stripping comments reads those sentences and calls the repair present.
#   This repository has already paid for that once.
#
#   Run:  bash harness/axisrefuse/break.sh [name-substring]
#   Out:  harness/axisrefuse/out/BREAKS.tsv   break, red-count, first failure
#         harness/axisrefuse/out/break_<name>.v84.log
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$HERE/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$HERE/out"
WORK="${TMPDIR:-/tmp}/axis/eml-axisrefuse-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

FORM=plugin/graphs/eml-graphs-form.praat

shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/axisrefuse/out --exclude=harness/formaxis/out \
        --exclude=harness/record/replay_out --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/axisrefuse/out"
}

revert () {
    ( cd "$ROOT" && git show "HEAD:$2" ) > "$WORK/$1/$2"
}

# A DISPLAY OF ITS OWN PER BREAK is not needed — the breaks run one at a time
# — but a display that is not the working tree's is, so a break run cannot
# collide with a re-drive of the committed transcript on :86.
run_break () {
    local n=$1
    local o="$WORK/$n/harness/axisrefuse/out"
    EML_AR_SRC="$WORK/$n" EML_AR_OUTDIR="$o" EML_AR_DISPLAY=":87" \
        timeout 2400 bash "$WORK/$n/harness/axisrefuse/run.sh" \
        > "$o/drive.log" 2>&1
    EML_AR_FORM="$WORK/$n/$FORM" EML_AR_DIR="$o" \
        Rscript "$ROOT/validate/v84_axis_refusal.R" \
        > "$OUT/break_$n.v84.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v84.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v84.log" \
            | sed 's/^FAIL  *v84  *//; s/  computed.*//' | cut -c1-100)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-18s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF, ON ONE PAIR
# ---------------------------------------------------------------------------
if want swap_back; then
    shadow swap_back
    python3 - "$WORK/swap_back/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = "    if allFormsDone = 1\n        @emlGraphsCheckAxisRanges\n"
assert anchor in s, "swap_back anchor not found"
swap = ("    if allFormsDone = 1\n"
        "        if not (valueMin = 0 and valueMax = 0)\n"
        "            if valueMax < valueMin\n"
        "                tmpSwap = valueMin\n"
        "                valueMin = valueMax\n"
        "                valueMax = tmpSwap\n"
        "            endif\n"
        "        endif\n"
        "    endif\n")
open(p, "w", encoding="utf-8").write(s.replace(anchor, swap + anchor, 1))
PY
    run_break swap_back
fi

if want head_form; then
    shadow head_form
    revert head_form "$FORM"
    run_break head_form
fi

# ---------------------------------------------------------------------------
# 2. THE REFUSAL THAT DRAWS ANYWAY
# ---------------------------------------------------------------------------
if want refuse_but_draw; then
    shadow refuse_but_draw
    python3 - "$WORK/refuse_but_draw/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ("            @emlGraphsShowAxisRefusal\n"
       "            allFormsDone = 0\n")
assert old in s, "refuse_but_draw anchor not found"
open(p, "w", encoding="utf-8").write(
    s.replace(old, "            @emlGraphsShowAxisRefusal\n", 1))
PY
    run_break refuse_but_draw
fi

# ---------------------------------------------------------------------------
# 3. THE MESSAGE WITHOUT THE NUMBERS
# ---------------------------------------------------------------------------
if want numberless; then
    shadow numberless
    python3 - "$WORK/numberless/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ('        .headline$ = .axis$ + " maximum (" + string$ (.max) + ") is below "\n'
       '        ... + .axis$ + " minimum (" + string$ (.min) + ")."\n')
assert old in s, "numberless anchor not found"
new = ('        .headline$ = .axis$ + " maximum is below "\n'
       '        ... + .axis$ + " minimum."\n')
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
    run_break numberless
fi

# ---------------------------------------------------------------------------
# 4. THE PROSE WITHOUT THE CODE
# ---------------------------------------------------------------------------
if want prose_only; then
    shadow prose_only
    python3 - "$WORK/prose_only/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "        @emlGraphsCheckAxisRanges\n"
assert old in s, "prose_only anchor not found"
# The sweep is commented out and the swap put back in its place. Every
# paragraph in the file that explains the refusal stays exactly where it is.
new = ("        # @emlGraphsCheckAxisRanges refuses a pair whose maximum is\n"
       "        # below its minimum rather than guessing which reading the\n"
       "        # user meant.\n"
       "        if valueMax < valueMin\n"
       "            tmpSwap = valueMin\n"
       "            valueMin = valueMax\n"
       "            valueMax = tmpSwap\n"
       "        endif\n"
       "        emlGraphsCheckAxisRanges.refused = 0\n")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
    run_break prose_only
fi

echo "BREAKS.tsv:"
cat "$TSV"

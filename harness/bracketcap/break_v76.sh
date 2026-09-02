#!/usr/bin/env bash
# ============================================================================
# harness/bracketcap/break_v76.sh — nothing is validated until it has been
#                                   broken, and BOTH HALVES OF v76 HAVE TO BE
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# validate/v76 makes one claim — every arm of @emlRunAnnotationComparison that
# can produce a bracket names its test — and proves it two ways: by
# ENUMERATING the arms out of the source, and by READING the name off two
# driven figures. Each half exists because the other cannot see a particular
# failure, so the breaks below are chosen to hit them SEPARATELY as well as
# together. Two of them are the argument:
#
#   new_arm_silent adds a fifth bracket-producing arm with no test name and
#   drives NOTHING new. Every rendered figure is unchanged, every OCR check
#   passes, and the enumeration goes red. That is the case the whole file is
#   a reaction to: this exact defect has now been repaired one arm at a time
#   twice (ruling 1b left the bracket layout silent, ruling 11 left k = 2
#   silent), and a validator scoped to the figures that exist cannot see the
#   arm that does not have a figure yet.
#
#   no_route leaves the bridge perfect and deletes the form's route into the
#   corner block. Every source check passes — the arms all set annotTextN,
#   the label is the omnibus, the anchor is there — and no figure says
#   anything. That is why §3 and §4 read tesseract rather than the source.
#
# Every break is a COPY of the repository carrying one deliberate defect,
# driven through $EML_BC_SRC and read by validate/v76 through $EML_ANNOT_SRC,
# $EML_FORM_SRC and $EML_BRACKETCAP_DIR. The working tree is never touched and
# never has to be, which is the point: a break test that edits the tree and
# puts it back is one interrupted run away from committing a defect.
#
#   Run:  bash harness/bracketcap/break_v76.sh [name-substring]
#   Out:  harness/bracketcap/out/BREAKS_V76.tsv   break, red-count, first fail
#         harness/bracketcap/out/break_<name>.v76.log
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -u

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$ROOT/harness/bracketcap/out"
WORK="${EML_BC76_WORK:-/tmp/wf_co9/breaks76}"
TSV="$OUT/BREAKS_V76.tsv"
FILTER="${1:-}"
ANNOT=plugin/graphs/eml-annotation-procedures.praat
FORM=plugin/graphs/eml-graphs-form.praat

mkdir -p "$OUT" "$WORK"
[ -z "$FILTER" ] && : > "$TSV"

shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/bracketcap/out --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/bracketcap/out"
}

run_break () {
    # TWO STATEMENTS, NOT ONE. `local n=$1 o=...$n...` expands every word
    # before it assigns any of them, so $n is still unset when $o is built —
    # and under `set -u` that is an abort before the first break runs.
    local n=$1
    local o="$WORK/$n/harness/bracketcap/out"
    EML_BC_SRC="$WORK/$n" EML_BC_OUTDIR="$o" \
        timeout 900 bash "$WORK/$n/harness/bracketcap/bracketcap.sh" \
        > "$o/drive.log" 2>&1
    EML_ANNOT_SRC="$WORK/$n/$ANNOT" EML_FORM_SRC="$WORK/$n/$FORM" \
        EML_BRACKETCAP_DIR="$o" \
        Rscript "$ROOT/validate/v76_bracket_names_test.R" \
        > "$OUT/break_$n.v76.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v76.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v76.log" \
            | sed 's/^FAIL  *v76  *//; s/  computed.*//' | cut -c1-88)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-24s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF
# ---------------------------------------------------------------------------
# The annotation bridge reverted to HEAD: the state ruling C describes. Both
# two-group arms compose an omnibus, neither sets annotTextN, and the
# two-group figures carry a bracket, stars and an effect size with nothing
# saying what produced them. The drive is NOT reverted — mw_two still runs —
# so this measures the plugin and not the harness.
if want head_revert; then
    shadow head_revert
    ( cd "$ROOT" && git show "HEAD:$ANNOT" ) > "$WORK/head_revert/$ANNOT"
    run_break head_revert
fi

# The same defect written directly, so it survives the ruling being committed:
# the two annotTextN blocks deleted from the two-group arms and nothing else
# touched. Both captions stay, which is the sharp part — a figure that names
# its test in the caption band and not in the frame passes anything that
# searches the whole image.
if want no_text_n; then
    shadow no_text_n
    python3 - "$WORK/no_text_n/$ANNOT" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding='utf-8').read().split('\n')
BLOCK = ['annotTextN = 1', 'annotTextX[1] = 0', 'annotTextY[1] = 0',
         'annotTextLabel$[1] = .omnibus$', 'annotTextAnchor$[1] = "right"']
# The two-group arms are the FIRST two occurrences of the five-line block in
# file order; the k >= 3 arms follow them. Located as a run rather than by
# line number so an edit above them does not silently move the target.
hits = [i for i in range(len(lines) - 4)
        if [l.strip() for l in lines[i:i+5]] == BLOCK]
assert len(hits) == 6, hits
for i in reversed(hits[:2]):
    del lines[i:i+5]
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break no_text_n
fi

# ---------------------------------------------------------------------------
# 2. THE HALF-REPAIR, WHICH IS HOW THIS DEFECT HAS ARRIVED EVERY TIME
# ---------------------------------------------------------------------------
# Only the parametric arm repaired. welch_two names its test, mw_two does
# not, and a check written against "the two-group figure" — singular, which is
# how the defect was reported — is satisfied.
if want one_arm_only; then
    shadow one_arm_only
    python3 - "$WORK/one_arm_only/$ANNOT" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding='utf-8').read().split('\n')
BLOCK = ['annotTextN = 1', 'annotTextX[1] = 0', 'annotTextY[1] = 0',
         'annotTextLabel$[1] = .omnibus$', 'annotTextAnchor$[1] = "right"']
hits = [i for i in range(len(lines) - 4)
        if [l.strip() for l in lines[i:i+5]] == BLOCK]
assert len(hits) == 6, hits
del lines[hits[0]:hits[0]+5]      # the Mann-Whitney arm, first in file order
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break one_arm_only
fi

# ---------------------------------------------------------------------------
# 3. THE ENUMERATION EARNS ITS PLACE
# ---------------------------------------------------------------------------
# A FIFTH ARM, ADDED SILENTLY. It writes a bracket label and sets no test
# name, and nothing drives it — so every figure in the harness is byte-for-byte
# what it was and every OCR check in §3 and §4 passes. Only a validator that
# enumerates the arms out of the source can see it, and this is the break that
# says so. It is written as a copy of the Welch arm because that is how a new
# arm actually arrives.
if want new_arm_silent; then
    shadow new_arm_silent
    python3 - "$WORK/new_arm_silent/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
anchor = "    # =================================================================\n    # K-GROUP COMPARISON (3-10 groups)"
assert s.count(anchor) == 1
new_arm = """    if .error$ = "" and .nGroups = 2 and .style$ = "future"
        @emlTTest: .v1#, .v2#, 2, 0
        annotBracketN = 1
        annotBracketI[1] = 1
        annotBracketJ[1] = 2
        annotBracketLabel$[1] = "n.s."
        annotBracketTier[1] = 1
    endif

"""
s = s.replace(anchor, new_arm + anchor)
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break new_arm_silent
fi

# THE COUNT SET IN THE WRONG BRANCH. annotTextN = 1 moved INSIDE the
# `if .useMatrix` half of the Welch arm, so the MATRIX layout names its test
# and the BRACKET layout — the layout this ruling is about — does not. A grep
# for "does this arm set annotTextN" finds it and is satisfied; the dominance
# rule in §2 is not, because a statement inside one branch of a conditional
# does not dominate a statement in the other.
if want text_n_in_matrix; then
    shadow text_n_in_matrix
    python3 - "$WORK/text_n_in_matrix/$ANNOT" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding='utf-8').read().split('\n')
BLOCK = ['annotTextN = 1', 'annotTextX[1] = 0', 'annotTextY[1] = 0',
         'annotTextLabel$[1] = .omnibus$', 'annotTextAnchor$[1] = "right"']
hits = [i for i in range(len(lines) - 4)
        if [l.strip() for l in lines[i:i+5]] == BLOCK]
assert len(hits) == 6, hits
i = hits[1]                              # the Welch arm
block = lines[i:i+5]
del lines[i:i+5]
# Re-insert at the top of the arm's `if .useMatrix` branch: the nearest
# `if .useMatrix` above the deleted block.
k = max(j for j in range(i) if lines[j].strip() == 'if .useMatrix')
ind = lines[k][:len(lines[k]) - len(lines[k].lstrip())] + '    '
lines[k+1:k+1] = [ind + l.strip() for l in block]
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break text_n_in_matrix
fi

# A CONSTANT WHERE THE OMNIBUS SHOULD BE. The corner box is created, placed,
# anchored and drawn, and it carries a sentence that names no test and reports
# no number. Every count, coordinate and anchor check passes; §2's "the box
# carries the omnibus the arm composed" and every OCR check do not. This is
# the fix-shaped fix for this ruling.
if want label_constant; then
    shadow label_constant
    python3 - "$WORK/label_constant/$ANNOT" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding='utf-8').read().split('\n')
BLOCK = ['annotTextN = 1', 'annotTextX[1] = 0', 'annotTextY[1] = 0',
         'annotTextLabel$[1] = .omnibus$', 'annotTextAnchor$[1] = "right"']
hits = [i for i in range(len(lines) - 4)
        if [l.strip() for l in lines[i:i+5]] == BLOCK]
assert len(hits) == 6, hits
for i in hits[:2]:
    j = i + 3
    ind = lines[j][:len(lines[j]) - len(lines[j].lstrip())]
    lines[j] = ind + 'annotTextLabel$[1] = "Group comparison"'
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break label_constant
fi

# ---------------------------------------------------------------------------
# 4. THE DRIVEN HALF EARNS ITS PLACE
# ---------------------------------------------------------------------------
# The bridge is untouched and PERFECT. The form's route from annotTextN into
# the corner block is deleted, so every arm names its test into a variable
# nothing reads and no figure in the harness says anything. Every check in §2
# passes.
if want no_route; then
    shadow no_route
    python3 - "$WORK/no_route/$FORM" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = """            if annotTextN > 0
                annotBlockN = annotBlockN + 1
                annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
                annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
                annotTextN = 0
            endif
"""
assert s.count(old) == 1
s = s.replace(old, "            annotTextN = 0\n")
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break no_route
fi

echo
echo "BREAKS_V76.tsv:"
awk -F'\t' '{printf "  %-24s red=%-4s %s\n", $1, $2, $3}' "$TSV"

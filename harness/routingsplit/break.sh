#!/usr/bin/env bash
# ============================================================================
# harness/routingsplit/break.sh — red demonstration for validate/v132
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# MUTATION STANDARD. Copies the plugin tree and makes ONE change to it: in
# @emlEffectMatrixCaption (stats/eml-analysis.praat), the DISCLOSURE sentence
#
#     No pairwise significance tests were run.
#
# is moved from OUTSIDE the `if emlShowExplanations` gate to INSIDE it, beside
# the EXPLANATION sentence that legitimately lives there. Nothing else in the
# tree is touched, no wording changes, and the mutated procedure still
# compiles and still prints both sentences with the toggle on.
#
# THAT IS THE DEFECT CLASS IN ITS PUREST FORM. A fact — what was NOT computed —
# now rides on a line the toggle can remove. A user who leaves the checkbox at
# its shipped default of off gets a grid of pairwise effect sizes under a
# heading that says "pairwise", with nothing on the page saying no pairwise
# test was run. The numbers are all still there and every one of them is
# correct, which is exactly why this is the failure worth building a check
# for: nothing looks wrong.
#
# WHAT SHOULD GO RED, and it is worth reading which:
#   * v132 section 2, "anova_only / kw_only: item 12's DISCLOSURE prints with
#     explanations OFF" — the driven evidence.
#   * v132 section 3, "@emlEffectMatrixCaption's DISCLOSURE sentence stands
#     OUTSIDE the explanations gate" — the source shape.
# Section 1's mechanical pass does NOT go red here, and that is the honest
# result rather than a shortcoming: a disclosure sentence is prose, not a
# labelled statistic row, so the subtraction sees it leave and correctly
# declines to call prose a lost number. Section 2 is what names it. The two
# sections cover different halves of the rule and this run shows the seam.
#
# Usage:
#   bash harness/routingsplit/break.sh
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp -a "$ROOT/plugin_EML_StatsGraphs" "$WORK/plugin_EML_StatsGraphs"

TARGET="$WORK/plugin_EML_StatsGraphs/stats/eml-analysis.praat"

python3 - "$TARGET" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()

before = '''    if .pairwiseFollows = 0
        @emlReportNote: "No pairwise significance tests were run."
        if emlShowExplanations
'''
after = '''    if .pairwiseFollows = 0
        if emlShowExplanations
            @emlReportNote: "No pairwise significance tests were run."
'''
if src.count(before) != 1:
    sys.exit("break.sh: the caption no longer has the shape this mutation "
             "edits (%d matches). Re-read @emlEffectMatrixCaption and update "
             "this file rather than loosening the match." % src.count(before))
open(path, "w", encoding="utf-8").write(src.replace(before, after))
print("break.sh: moved the DISCLOSURE sentence inside the explanations gate")
PY
rc=$?
[ "$rc" -eq 0 ] || exit "$rc"

echo "break.sh: mutated tree at $WORK; driving run.sh against it."

EML_RS_SRC="$WORK/plugin_EML_StatsGraphs" EML_RS_OUT="$SCRIPT_DIR/out/broken" \
    bash "$SCRIPT_DIR/run.sh" > /dev/null 2>&1

# The permutation cells too, so v132's section 4 has shadow evidence to read
# and the red below is the mutation's doing rather than a missing file.
EML_RS_SRC="$WORK/plugin_EML_StatsGraphs" EML_RS_OUT="$SCRIPT_DIR/out/broken" \
    bash "$SCRIPT_DIR/permute.sh" > /dev/null 2>&1

echo
echo "break.sh: the disclosure, on the mutated tree ---"
for leg in anova_only_off anova_only_on kw_only_off kw_only_on; do
    f="$SCRIPT_DIR/out/broken/$leg.txt"
    if grep -q "No pairwise significance tests were run." "$f" 2>/dev/null; then
        echo "  $leg: DISCLOSURE present"
    else
        echo "  $leg: DISCLOSURE ABSENT  <-- the fact is gone with the toggle"
    fi
done

echo
echo "break.sh: v132 against the mutated tree and its evidence ---"
EML_RS_OUT="$SCRIPT_DIR/out/broken" EML_RS_SRC="$WORK/plugin_EML_StatsGraphs" \
    Rscript "$ROOT/validate/v132_routing_split.R" 2>&1 \
    | grep -E "^FAIL|checks," | sed 's/^/  /'

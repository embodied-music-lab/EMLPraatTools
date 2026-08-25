#!/usr/bin/env bash
# ============================================================================
# harness/explaingate/break.sh -- what menu_on and menu_off answer when the
#                                  toggle's routing is removed
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RIG NEXT DOOR (run.sh) MEASURES A REPAIRED TREE, AND A GREEN MEASUREMENT
# ON A REPAIRED TREE IS NOT EVIDENCE THAT THE REPAIR IS LOAD-BEARING. This one
# builds a copy of the plugin with the four-line explanations block removed
# from @emlHandleCommonFields (stats/eml-output.praat) -- the whole of punch
# list 6.1's dialog-side wiring, and nothing else -- and drives the same
# three legs against it.
#
# THE COPY IS A COPY. Nothing here edits the working tree and puts it back: a
# rig that did is one interrupted run away from committing the defect it was
# built to demonstrate.
#
# WHAT IT SHOWS. annotate_results_with_explanations is read by the dialog
# still (the field is untouched), but nothing propagates the answer to
# emlShowExplanations any more, so the global keeps whatever
# stats/eml-output.praat's own include-time default left it at -- 1 -- on
# every leg. menu_off comes back indistinguishable from menu_on: both carry
# the EXPLANATION line, and the toggle the user unchecked has no effect on
# what they read.
#
# Run from anywhere:  bash harness/explaingate/break.sh
# Output: harness/explaingate/out/break/{menu_off,menu_on,wizard_equivalent}.txt
#         harness/explaingate/out/break/EXPLAINGATE.tsv
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || exit 1

WORK="$(mktemp -d "${TMPDIR:-/tmp}/explaingate-break-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
OUT="$SCRIPT_DIR/out/break"
rm -rf "$OUT"
mkdir -p "$OUT"

# The smallest tree the drive can run out of: the plugin, the folder name the
# includes are written against, and this rig's own two files.
cp -r "$ROOT/plugin_EML_StatsGraphs" "$WORK/plugin_EML_StatsGraphs"
ln -s plugin_EML_StatsGraphs "$WORK/plugin"

OUTFILE="$WORK/plugin_EML_StatsGraphs/stats/eml-output.praat"
python3 - "$OUTFILE" <<'PY'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
mark = (
    '    emlLastShowExplanations = annotate_results_with_explanations\n'
    '    emlShowExplanations = annotate_results_with_explanations\n'
    '    emlDialogShowExplanations = annotate_results_with_explanations\n'
    '    emlExplanationsFromDialog = 1\n'
)
if mark not in s:
    sys.exit("break.sh: the block to remove is not in @emlHandleCommonFields "
             "-- this script names the shape it reverts, so a rename is a "
             "failure here rather than a break test that quietly does "
             "nothing.")
io.open(p, "w", encoding="utf-8").write(s.replace(mark, "", 1))
PY
[ $? -eq 0 ] || exit 1

EML_EG_SRC="$WORK/plugin_EML_StatsGraphs" EML_EG_OUT="$OUT" \
    bash "$SCRIPT_DIR/run.sh" || true

echo "break: menu_off and menu_on, with the wiring removed"
for leg in menu_off menu_on; do
    echo "  -- $leg --"
    if grep -q "Effect sizes estimate the size of each pairwise difference." "$OUT/$leg.txt"; then
        echo "     EXPLANATION line present"
    else
        echo "     EXPLANATION line ABSENT"
    fi
done
# A byte diff is not used here: both captures carry a wall-clock timestamp
# line that differs on every run whether or not the bug is present. What
# actually demonstrates the collapse is the EXPLANATION-line presence check
# above (both present) and v130's own assertions below.
if grep -q "Effect sizes estimate the size of each pairwise difference." "$OUT/menu_off.txt" \
   && grep -q "Effect sizes estimate the size of each pairwise difference." "$OUT/menu_on.txt"; then
    echo "break: menu_off and menu_on both carry the explanation line -- the toggle does nothing"
fi

echo "break: v130 against the shadow tree and shadow evidence"
EML_EG_SRC="$WORK/plugin_EML_StatsGraphs" EML_EG_OUT="$OUT" \
    Rscript "$ROOT/validate/v130_explanations_gate.R" 2>&1 \
    | grep -E '^FAIL|checks,' | sed 's/^/break: /'
exit 0

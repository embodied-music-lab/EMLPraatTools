#!/usr/bin/env bash
# ============================================================================
# harness/explainwiring/break.sh — red demonstration, punch list 6.2
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# MUTATION STANDARD. Copies the plugin tree, then replaces
# stats/eml-analysis.praat and stats/eml-output.praat with the committed
# (pre-6.2) versions from HEAD -- i.e. reverts exactly the two files this
# round's wiring touched, mechanically, and nothing else -- then re-drives
# harness/explainwiring/run.sh against that copy.
#
# EXPECTED RESULT ON THE REVERTED TREE: every menu_on capture is
# byte-identical to its menu_off twin for pairwise (Welch, Student, Scheffe,
# Wilcoxon), repeated-measures ANOVA, Friedman and descriptive statistics --
# the toggle does nothing at these seven reporters, which is the defect
# 6.2 closes. On the working tree (run.sh with no EML_EW_SRC) menu_on and
# menu_off differ by exactly the explanation lines this round added; see
# run.sh's own header.
#
# Usage:
#   bash harness/explainwiring/break.sh
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp -a "$ROOT/plugin_EML_StatsGraphs" "$WORK/plugin_EML_StatsGraphs"

for f in stats/eml-analysis.praat stats/eml-output.praat; do
    git -C "$ROOT" show "HEAD:plugin_EML_StatsGraphs/$f" \
        > "$WORK/plugin_EML_StatsGraphs/$f"
done

echo "break.sh: reverted stats/eml-analysis.praat and stats/eml-output.praat"
echo "          to HEAD in a scratch copy at $WORK; driving run.sh against it."

EML_EW_SRC="$WORK/plugin_EML_StatsGraphs" EML_EW_OUT="$SCRIPT_DIR/out/broken" \
    bash "$SCRIPT_DIR/run.sh"

echo
echo "break.sh: menu_off vs menu_on on the REVERTED tree (expect: identical" \
     "except the leg name, for every measure) ---"
rc=0
for measure in pairwise_welch pairwise_student pairwise_scheffe pairwise_wilcoxon rmanova friedman descriptive; do
    off="$SCRIPT_DIR/out/broken/${measure}_menu_off.txt"
    on="$SCRIPT_DIR/out/broken/${measure}_menu_on.txt"
    # Strip the leg-name banner lines (they legitimately differ, "_menu_off"
    # vs "_menu_on") and the report's own timestamp line -- neither is part
    # of what the toggle controls.
    body_diff=$(diff \
        <(grep -v "^== \|^  ..., ... .. ..:..:.. ....$\|^  [A-Za-z]\{3\} [A-Za-z]\{3\} .* 20[0-9][0-9]$" "$off") \
        <(grep -v "^== \|^  ..., ... .. ..:..:.. ....$\|^  [A-Za-z]\{3\} [A-Za-z]\{3\} .* 20[0-9][0-9]$" "$on"))
    if [ -z "$body_diff" ]; then
        echo "  $measure: RED CONFIRMED -- menu_on = menu_off, toggle is a no-op"
    else
        echo "  $measure: NOT RED -- menu_on differs from menu_off on the reverted tree:"
        echo "$body_diff" | sed 's/^/    /'
        rc=1
    fi
done
exit "$rc"

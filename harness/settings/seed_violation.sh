#!/usr/bin/env bash
# ============================================================================
# harness/settings/seed_violation.sh -- the red demonstration for v112
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS PROVES, and why the check is not finished without it.
#
# validate/v112_settings_census.R is a census. Every assertion in it reads
# "for every setting in the population ...", and every one of those is TRUE of
# an empty population -- which is what a renamed door, or a walk that quietly
# stopped resolving, produces. v112 answers half of that itself, with a
# resolver gate that fails on a population of zero and prints the counts. This
# file answers the other half: it shows the check going RED when the plugin
# actually does the things the check forbids.
#
# NOTHING IN THE SHIPPED TREE IS TOUCHED. The plugin is COPIED, the violation
# is seeded into the copy, and v112 is pointed at the copy with
# $EML_SETTINGS_SRC -- the same variable harness/settings/run.sh takes, so one
# setting moves both ends and v112 is used UNMODIFIED. What goes red is the
# check, not a rehearsal of it.
#
# THREE LEGS: THE RATCHET RUNS BOTH WAYS AND EACH DIRECTION HAS TO BE SHOWN ON
# ITS OWN, AND THE VACUOUS PASS IS A THIRD FAILURE THAT LOOKS LIKE NEITHER.
#
#   LEG A -- A NEWLY READ SETTING THAT NOTHING CLASSIFIES. The realistic
#   version of this is not exotic: someone adds a threshold to the graphs
#   form, reads it in the scatter's correlation block, and never touches the
#   census. Seeded as one line inserted immediately before the block that
#   computes r and p, reading a global declared as a default beside the other
#   graph defaults. The read is into a procedure-local, so it is a READ and
#   not a write -- a self-assignment would make the walk treat it as the
#   door's own scratch, which is exactly the distinction being tested.
#   Expected: "every setting the draw layer reads is classified" FAILS,
#   naming emlSeedMinPairs, and the unclassified count in the resolver line
#   goes from 0 to 1.
#
#   LEG B -- A CLASSIFICATION WHOSE SETTING THE LAYER NO LONGER READS. The
#   realistic version is a refactor that drops a control and leaves its line
#   in the list, where the next reader is entitled to believe it. Seeded by
#   making the scatter's two reads of scatterShowFormula unconditional, so
#   the name is still declared in DISPLAY_ONLY and no longer read anywhere in
#   the doors' closure.
#   Expected: "no classification names a setting the draw layer no longer
#   reads" FAILS, naming scatterShowFormula.
#
#   LEG C -- THE VACUOUS PASS. Both doors renamed, so the walk resolves
#   nothing and every per-setting assertion is trivially true. Expected: the
#   door check, the resolver gate and the stale-classification check all FAIL
#   together, which is what stops a census of nothing reading as a clean one.
#
# Usage:  bash harness/settings/seed_violation.sh
#         EML_SETTINGS_SEED_DIR=/somewhere  bash .../seed_violation.sh
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
SEED_DIR="${EML_SETTINGS_SEED_DIR:-/tmp/eml-settings-seed}"

# The seeded trees are read by v112 through $EML_SETTINGS_SRC, which names a
# repository root; each leg gets its own so one leg cannot mask the other.
run_leg () {
    local leg="$1" tree="$SEED_DIR/$1"
    rm -rf "$tree"
    mkdir -p "$tree"
    cp -a "$ROOT/plugin_EML_StatsGraphs" "$tree/plugin_EML_StatsGraphs"
}

# ---------------------------------------------------------------------------
# LEG A -- a setting the draw layer reads and no list classifies
# ---------------------------------------------------------------------------
run_leg A
A="$SEED_DIR/A/plugin_EML_StatsGraphs"

# ANCHORED ON THE CODE, NOT ON A LINE NUMBER. A line number in a seeding
# script rots silently: the day the file moves it seeds a violation into
# somewhere harmless and the demonstration goes green for the wrong reason.
ANCHOR='        # Compute correlations and build annotation block'
grep -qF "$ANCHOR" "$A/graphs/eml-draw-procedures.praat" || {
    echo "seed_violation: REFUSED -- anchor not found in eml-draw-procedures.praat" >&2
    echo "  looked for: $ANCHOR" >&2
    exit 2; }

python3 - "$A/graphs/eml-draw-procedures.praat" "$ANCHOR" <<'PY'
import sys
path, anchor = sys.argv[1], sys.argv[2]
src = open(path, encoding="utf-8").read()
seed = (
    "        ; SEEDED VIOLATION (harness/settings/seed_violation.sh, leg A).\n"
    "        ; A setting the scatter's correlation block reads and that\n"
    "        ; neither of v112's lists classifies. Not in the shipped tree.\n"
    "        .seedMinPairs = emlSeedMinPairs\n"
)
assert src.count(anchor) == 1, "anchor is not unique"
open(path, "w", encoding="utf-8").write(src.replace(anchor, seed + anchor))
PY

cat >> "$A/stats/eml-extract.praat" <<'EOF'

; SEEDED VIOLATION (harness/settings/seed_violation.sh, leg A). Declared here
; beside emlGroupSortAlphabetical, which is the shape a real new setting with
; no control of its own would take. Not in the shipped tree.
emlSeedMinPairs = 3
EOF

# ---------------------------------------------------------------------------
# LEG B -- a classification whose setting the layer no longer reads
# ---------------------------------------------------------------------------
run_leg B
B="$SEED_DIR/B/plugin_EML_StatsGraphs"
n=$(grep -c '^ *if scatterShowFormula = 1$' "$B/graphs/eml-draw-procedures.praat")
[ "$n" -ge 1 ] || {
    echo "seed_violation: REFUSED -- no scatterShowFormula read to remove" >&2
    exit 2; }
sed -i 's/^\( *\)if scatterShowFormula = 1$/\1if 1 = 1/' \
    "$B/graphs/eml-draw-procedures.praat"

# ---------------------------------------------------------------------------
# LEG C -- the vacuous pass itself
# ---------------------------------------------------------------------------
# The characteristic failure of a census is not a wrong answer but a green run
# over an empty population. Seeded by renaming both doors in the copy, which
# is what a refactor that renamed @emlDrawScatterPlot and did not tell this
# file would look like: the walk resolves nothing, every "for every setting"
# assertion below is vacuously true, and without the resolver gate the file
# would report a clean census of nothing at all.
# Expected: the door check FAILS, the resolver line reads 0 settings and
# FAILS, and all seventy classifications turn stale at once.
run_leg C
C="$SEED_DIR/C/plugin_EML_StatsGraphs"
sed -i 's/^procedure emlBridgeGroupComparison:/procedure emlBridgeGroupComparisonRenamed:/' \
    "$C/graphs/eml-annotation-procedures.praat"
sed -i 's/^procedure emlDrawScatterPlot:/procedure emlDrawScatterPlotRenamed:/' \
    "$C/graphs/eml-draw-procedures.praat"

# ---------------------------------------------------------------------------
# AUDIT ALL THREE, WITH v112 UNMODIFIED
# ---------------------------------------------------------------------------
cd "$ROOT" || exit 2
for leg in A B C; do
    echo
    echo "=============================================================="
    echo "  seeded leg $leg -- v112 over $SEED_DIR/$leg"
    echo "=============================================================="
    EML_VALIDATE_DIR="$ROOT/validate" EML_SETTINGS_SRC="$SEED_DIR/$leg" \
        Rscript "$ROOT/validate/v112_settings_census.R" 2>&1 \
        | grep -E "FAIL|RESOLVER: [0-9]+ settings|checks," || true
done

echo
echo "seed_violation: all three legs above must show FAIL lines. A green leg means"
echo "  v112 has stopped catching what it claims to."

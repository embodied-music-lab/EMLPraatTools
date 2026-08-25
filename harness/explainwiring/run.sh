#!/usr/bin/env bash
# ============================================================================
# harness/explainwiring/run.sh — punch list 6.2, seven measures, three legs
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Drives harness/explainwiring/doors.praat once per (measure, leg) pair, for
# every reporter this round's wiring touched: pairwise Welch, pairwise
# Student, pairwise Scheffe, pairwise Wilcoxon, repeated-measures ANOVA,
# Friedman, and descriptive statistics. Three legs per measure --
# wizard, menu_off, menu_on -- twenty-one captures in all.
#
# $EML_EW_SRC points the whole rig at a different plugin tree, the same
# door every other doors.praat in this tree opens, so a red demonstration
# (harness/explainwiring/break.sh) can drive this file unmodified against a
# reverted tree.
#
# Usage:
#   bash harness/explainwiring/run.sh
#   EML_EW_SRC=/path/to/tree bash harness/explainwiring/run.sh
#
# Output:
#   $OUT/<measure>_<leg>.txt   one captured report per (measure, leg)
#   $OUT/EXPLAINWIRING.tsv     leg <TAB> key <TAB> value
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "explainwiring: no Praat; refusing" >&2; exit 2; }

SRC="${EML_EW_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_EW_OUT:-$SCRIPT_DIR/out}"

[ -d "$SRC/stats" ] || {
    echo "explainwiring: REFUSED — no plugin tree at $SRC. Nothing was cleared." >&2
    exit 2; }

mkdir -p "$OUT"
TSV="$OUT/EXPLAINWIRING.tsv"
printf 'leg\tkey\tvalue\n' > "$TSV"
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }
emit rig src "$SRC"
emit rig praat "$("$PRAAT" --version 2>&1 | head -1)"

DOORS="$SCRIPT_DIR/doors.praat"
if [ "$SRC" != "$ROOT/plugin_EML_StatsGraphs" ]; then
    sed "s|\.\./\.\./plugin/|$SRC/|g" "$SCRIPT_DIR/doors.praat" > "$OUT/doors_src.praat"
    DOORS="$OUT/doors_src.praat"
    cp "$SCRIPT_DIR"/fixture_k.csv "$SCRIPT_DIR"/fixture_rm.csv "$OUT/"
fi

rc_all=0
for measure in pairwise_welch pairwise_student pairwise_scheffe pairwise_wilcoxon rmanova friedman descriptive; do
    for state in wizard menu_off menu_on; do
        leg="${measure}_${state}"
        ( cd "$SCRIPT_DIR" && EML_EG_LEG="$leg" \
          timeout 120 "$PRAAT" $PRAAT_TRUST --run "$DOORS" \
          > "$OUT/$leg.txt" 2>&1 )
        rc=$?
        emit "$leg" "returned" "$rc"
        if grep -q "^== END $leg ==" "$OUT/$leg.txt" 2>/dev/null; then
            emit "$leg" "complete" "1"
        else
            emit "$leg" "complete" "0"
            rc_all=1
        fi
    done
done

echo "explainwiring: src = $SRC"
sed 's/^/  /' "$TSV"
echo "explainwiring: wrote $TSV"
exit "$rc_all"

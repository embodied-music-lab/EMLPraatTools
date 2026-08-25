#!/usr/bin/env bash
# ============================================================================
# harness/routingsplit/run.sh — every analysis, both toggle states
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Drives harness/routingsplit/doors.praat once per (analysis, toggle) pair —
# seventeen analyses x two states = thirty-four captures. Each pair is the
# SAME data through the SAME orchestrator with the SAME settings; the only
# thing that differs is the answer a menu dialog's "Annotate results with
# explanations" checkbox left behind.
#
# $EML_RS_SRC points the whole rig at a different plugin tree, so a red
# demonstration (break.sh) can drive this file unmodified against a tree with
# the routing broken. $EML_RS_OUT redirects the captures so a break run never
# overwrites the committed evidence.
#
# Usage:
#   bash harness/routingsplit/run.sh
#   EML_RS_SRC=/path/to/tree EML_RS_OUT=/path/to/out bash harness/routingsplit/run.sh
#
# Output:
#   $OUT/<analysis>_<off|on>.txt   one captured report per leg
#   $OUT/ROUTINGSPLIT.tsv          leg <TAB> key <TAB> value
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "routingsplit: no Praat; refusing" >&2; exit 2; }

SRC="${EML_RS_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_RS_OUT:-$SCRIPT_DIR/out}"

[ -d "$SRC/stats" ] || {
    echo "routingsplit: REFUSED — no plugin tree at $SRC. Nothing was cleared." >&2
    exit 2; }

mkdir -p "$OUT"
TSV="$OUT/ROUTINGSPLIT.tsv"
printf 'leg\tkey\tvalue\n' > "$TSV"
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }
emit rig src "$SRC"
emit rig praat "$("$PRAAT" --version 2>&1 | head -1)"

DOORS="$SCRIPT_DIR/doors.praat"
WORKDIR="$SCRIPT_DIR"
if [ "$SRC" != "$ROOT/plugin_EML_StatsGraphs" ]; then
    sed "s|\.\./\.\./plugin/|$SRC/|g" "$SCRIPT_DIR/doors.praat" > "$OUT/doors_src.praat"
    DOORS="$OUT/doors_src.praat"
    cp "$SCRIPT_DIR"/fixture_k.csv "$SCRIPT_DIR"/fixture_rm.csv \
       "$SCRIPT_DIR"/fixture_flat.csv "$SCRIPT_DIR"/fixture_two.csv "$OUT/"
    WORKDIR="$OUT"
fi

ANALYSES="twogroup_both twogroup_welch twogroup_mwu anova_tukey anova_only kw_dunn kw_only
          pairwise_welch pairwise_wilcoxon correlation_both regression
          descriptive normality paired_both rmanova friedman
          caution_anova caution_kw caution_pairwise"

rc_all=0
for analysis in $ANALYSES; do
    for state in off on; do
        leg="${analysis}_${state}"
        ( cd "$WORKDIR" && EML_RS_LEG="$leg" \
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

echo "routingsplit: src = $SRC"
sed 's/^/  /' "$TSV"
echo "routingsplit: wrote $TSV"
exit "$rc_all"

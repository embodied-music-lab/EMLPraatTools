#!/usr/bin/env bash
# ============================================================================
# harness/explaingate/run.sh — the explanations toggle, three legs, one diff
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Punch list 6.1's acceptance: one fixture through three paths — the wizard,
# a menu dialog with the toggle off, and the same dialog with it on —
# producing IDENTICAL STATISTICS and differing ONLY in the explanations.
#
# THREE LEGS, TWO METHODS:
#   menu_off, menu_on     HEADLESS (doors.praat, `praat --run`), because the
#                         thing under test — @emlHandleCommonFields, the
#                         shared procedure every menu wrapper's Run calls —
#                         has no dialog of its own; the actual checkbox that
#                         feeds it is proved to bind correctly by v98
#                         (character law, name derivation, no collision).
#   wizard_equivalent     HEADLESS too, but see its header comment in
#                         doors.praat: it reproduces the wizard's own single
#                         assignment (emlShowExplanations = 1, no dialog,
#                         no control), not the wizard's pages.
#
# THE REAL WIZARD, GUI-DRIVEN, IS A SEPARATE, ALREADY-EXISTING RIG:
# harness/wizardback's "kgroups" leg drives the actual eml-wizard.praat under
# Xvfb (praat --run refuses a pause window, so nothing here can substitute
# for it) to the SAME table, SAME columns, SAME test (Kruskal-Wallis, no
# Dunn), and its captured Info window
# (harness/wizardback/out/kgroups.info.txt) already carries the exact
# EXPLANATION line this file's validator diffs on. Run BOTH rigs; v130 reads
# both outputs.
#
# $EML_EG_SRC points the whole rig at a different plugin tree, the same door
# every other doors.praat in this tree opens, so the red demonstration drives
# this file unmodified against a seeded tree.
#
# Usage:
#   bash harness/explaingate/run.sh
#   EML_EG_SRC=/path/to/tree bash harness/explaingate/run.sh
#
# Output:
#   $OUT/<leg>.txt          one captured report per leg
#   $OUT/EXPLAINGATE.tsv    leg <TAB> key <TAB> value — what v130 reads
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "explaingate: no Praat; refusing" >&2; exit 2; }

SRC="${EML_EG_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_EG_OUT:-$SCRIPT_DIR/out}"

[ -d "$SRC/stats" ] || {
    echo "explaingate: REFUSED — no plugin tree at $SRC. Nothing was cleared." >&2
    exit 2; }

mkdir -p "$OUT"
TSV="$OUT/EXPLAINGATE.tsv"
printf 'leg\tkey\tvalue\n' > "$TSV"
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }
emit rig src "$SRC"
emit rig praat "$("$PRAAT" --version 2>&1 | head -1)"

DOORS="$SCRIPT_DIR/doors.praat"
if [ "$SRC" != "$ROOT/plugin_EML_StatsGraphs" ]; then
    sed "s|\.\./\.\./plugin/|$SRC/|g" "$SCRIPT_DIR/doors.praat" > "$OUT/doors_src.praat"
    DOORS="$OUT/doors_src.praat"
    cp "$SCRIPT_DIR"/fixture_k.csv "$OUT/"
fi

rc_all=0
for leg in wizard_equivalent menu_off menu_on; do
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

echo "explaingate: src = $SRC"
sed 's/^/  /' "$TSV"
echo "explaingate: wrote $TSV"
exit "$rc_all"

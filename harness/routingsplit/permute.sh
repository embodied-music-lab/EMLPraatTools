#!/usr/bin/env bash
# ============================================================================
# harness/routingsplit/permute.sh — eight settings cells, one fixture
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Drives harness/routingsplit/permute.praat once per cell of
# {explanations off, on} x {table order, alphabetical} x {alpha .05, .01} —
# the settings-permutation drive risk R1 names, as far as the tree permits
# it today. permute.praat's own header states what R1 asks for, what is
# measurable now, and what is not (there is no result store, so there is no
# reprint to count).
#
# $EML_RS_SRC / $EML_RS_OUT redirect the tree and the captures, as in run.sh.
#
# Usage:
#   bash harness/routingsplit/permute.sh
#
# Output:
#   $OUT/perm_<cell>.txt   one captured report per cell
#   $OUT/PERMUTE.tsv       cell <TAB> key <TAB> value
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "routingsplit: no Praat; refusing" >&2; exit 2; }

SRC="${EML_RS_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_RS_OUT:-$SCRIPT_DIR/out}"

[ -d "$SRC/stats" ] || {
    echo "routingsplit/permute: REFUSED — no plugin tree at $SRC." >&2; exit 2; }

mkdir -p "$OUT"
TSV="$OUT/PERMUTE.tsv"
printf 'cell\tkey\tvalue\n' > "$TSV"
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }
emit rig src "$SRC"
emit rig praat "$("$PRAAT" --version 2>&1 | head -1)"

DRIVER="$SCRIPT_DIR/permute.praat"
WORKDIR="$SCRIPT_DIR"
if [ "$SRC" != "$ROOT/plugin_EML_StatsGraphs" ]; then
    sed "s|\.\./\.\./plugin/|$SRC/|g" "$SCRIPT_DIR/permute.praat" > "$OUT/permute_src.praat"
    DRIVER="$OUT/permute_src.praat"
    cp "$SCRIPT_DIR"/fixture_flat.csv "$OUT/"
    WORKDIR="$OUT"
fi

rc_all=0
for expl in 0 1; do
  for sort in 0 1; do
    for alpha in 05 01; do
      cell="expl${expl}_sort${sort}_alpha${alpha}"
      ( cd "$WORKDIR" && EML_RS_PERM="$cell" \
        timeout 120 "$PRAAT" $PRAAT_TRUST --run "$DRIVER" \
        > "$OUT/perm_$cell.txt" 2>&1 )
      rc=$?
      emit "$cell" "returned" "$rc"
      if grep -q "^== END $cell ==" "$OUT/perm_$cell.txt" 2>/dev/null; then
          emit "$cell" "complete" "1"
      else
          emit "$cell" "complete" "0"
          rc_all=1
      fi
    done
  done
done

echo "routingsplit/permute: src = $SRC"
sed 's/^/  /' "$TSV"
echo "routingsplit/permute: wrote $TSV"
exit "$rc_all"

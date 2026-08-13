#!/usr/bin/env bash
# ============================================================================
# legendroom/run.sh — the form's two-pass headroom loop, driven
# ============================================================================
# @emlGraphsDrawWithLegendRoom draws, measures, and if the legend needs y-axis
# room throws the first pass away and draws again. It sits at file scope with
# a comment saying it was extracted so a probe could drive it, and no probe
# ever did — so the loop, its pass counter, its per-type axis read-back and
# @emlGraphsDispatchDraw had never executed outside a live dialog.
#
# harness/legend covers the headroom ARITHMETIC by reimplementing the two-pass
# in its own fixture. That is a statement about the maths, not about this
# procedure.
#
# Run from anywhere:  bash harness/legendroom/run.sh
# Exit 0 = every case drove the loop to completion.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_LEGENDROOM_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
LOG="$OUT/driver.log"
TSV="$OUT/LEGENDROOM.tsv"
rm -f "$LOG" "$TSV"

( cd "$SCRIPT_DIR" && env -u DISPLAY timeout 180 "$PRAAT" $PRAAT_TRUST \
    --pref-dir="$PREFS" --run case.praat > "$LOG" 2>&1 )

: > "$TSV"
sed -n 's/^ROOM \([^ ]*\) type=\([0-9]*\) placement=\([0-9]*\) passes=\([0-9]*\) axisMode=\([0-9]*\) baseMin=\([^ ]*\) baseMax=\([^ ]*\).*/\1\t\2\t\3\t\4\t\5\t\6\t\7/p' \
    "$LOG" >> "$TSV"

nCases=$(wc -l < "$TSV")
printf '%-18s %-6s %-10s %-7s %-9s %s\n' case type placement passes axisMode axis
awk -F"\t" '{printf "%-18s %-6s %-10s %-7s %-9s %s..%s\n", $1,$2,$3,$4,$5,$6,$7}' "$TSV"
echo

fail=0
[[ "$nCases" -eq 5 ]] || { echo "FAIL: expected 5 cases, got $nCases"; fail=1; }
grep -q "^LEGENDROOM DONE$" "$LOG" \
    || { echo "FAIL: the driver did not finish — see $LOG"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "legendroom: PASS — $nCases cases drove the two-pass loop"
    exit 0
fi
exit 1

#!/usr/bin/env bash
# ============================================================================
# blankgroup/run.sh — a blank group cell is missing data, not a category
# ============================================================================
# @emlCountGroups matched on the NORMALISED label and had no test for an empty
# one, so a row whose group cell was blank -- or whitespace only, which
# normalises to empty -- became a group of its own. The count is not cosmetic:
# it is k in every degrees-of-freedom calculation, every post-hoc family size,
# and every legend.
#
# NOTHING IN THE TREE HAD A BLANK GROUP CELL except
# harness/disclosure/probe_exclusion_parity.praat, which has DEMONSTRATED the
# defect since it was written -- "a blank group label is counted as a
# category" -- and which no validator consumes. So the behaviour was
# documented, unasserted, and unfixed, and no existing fixture would have
# caught a regression either way.
#
# This driver supplies the fixture that was missing: one table, three real
# groups, one empty cell and one whitespace-only cell.
#
# Run from anywhere:  bash harness/blankgroup/run.sh
# Exit 0 = blanks excluded from the count and reported.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_BLANKGROUP_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
LOG="$OUT/driver.log"
TSV="$OUT/BLANKGROUP.tsv"
rm -f "$LOG" "$TSV"

( cd "$SCRIPT_DIR" && env -u DISPLAY timeout 120 "$PRAAT" $PRAAT_TRUST \
    --pref-dir="$PREFS" --run case.praat > "$LOG" 2>&1 )

: > "$TSV"
sed -n 's/^CASE \([^ ]*\) nGroups=\([0-9-]*\) nBlank=\([0-9-]*\) labels=\(.*\)$/\1\t\2\t\3\t\4/p' \
    "$LOG" >> "$TSV"

nCases=$(wc -l < "$TSV")
printf '%-18s %-9s %-8s %s\n' case nGroups nBlank labels
awk -F"\t" '{printf "%-18s %-9s %-8s %s\n", $1, $2, $3, $4}' "$TSV"
echo

fail=0
[[ "$nCases" -eq 4 ]] || { echo "FAIL: expected 4 cases, got $nCases"; fail=1; }
grep -q "^BLANKGROUP DONE$" "$LOG" \
    || { echo "FAIL: the driver did not finish — see $LOG"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "blankgroup: PASS — $nCases cases measured"
    exit 0
fi
exit 1

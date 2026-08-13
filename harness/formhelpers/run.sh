#!/usr/bin/env bash
# ============================================================================
# formhelpers/run.sh — the graphs form's own helpers, driven
# ============================================================================
# @emlGenerateUniquePath is the non-destructive-save promise: every save in
# the plugin goes through it, and its job is that an existing file is never
# silently overwritten. @emlGraphsCSVDefaultName builds a CSV export's
# suggested filename. Both live inside eml-graphs-form.praat, are called only
# from inside it, and had no test of any kind — not because they need a
# display, but because the file around them does.
#
# Run from anywhere:  bash harness/formhelpers/run.sh
# Exit 0 = every case produced a name.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_FORMHELPERS_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
LOG="$OUT/driver.log"
TSV="$OUT/FORMHELPERS.tsv"
# The scratch tree is rebuilt every run; a leftover file from a previous run
# would change what "already taken" means and quietly move every answer.
rm -rf "$OUT/scratch"
rm -f "$LOG" "$TSV"

( cd "$SCRIPT_DIR" && env -u DISPLAY timeout 120 "$PRAAT" $PRAAT_TRUST \
    --pref-dir="$PREFS" --run case.praat > "$LOG" 2>&1 )

: > "$TSV"
sed -n 's/^CASE \([^ ]*\) kind=\([^ ]*\) result=\(.*\) exists=\([^ ]*\)$/\1\t\2\t\3\t\4/p' \
    "$LOG" >> "$TSV"

nCases=$(wc -l < "$TSV")
printf '%-16s %-5s %-34s %s\n' case kind result exists
awk -F"\t" '{printf "%-16s %-5s %-34s %s\n", $1, $2, $3, $4}' "$TSV"
echo

fail=0
[[ "$nCases" -eq 17 ]] || { echo "FAIL: expected 17 cases, got $nCases"; fail=1; }
# The promise, enforced at the harness boundary too: a unique path that
# already exists is a hard failure here, not merely a red row in R.
if awk -F"\t" '$2 == "uniq" && $4 != "0"' "$TSV" | grep -q .; then
    echo "FAIL: @emlGenerateUniquePath returned a path that already exists"; fail=1
fi
grep -q "^FORMHELPERS DONE$" "$LOG" \
    || { echo "FAIL: the driver did not finish — see $LOG"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "formhelpers: PASS — $nCases cases measured"
    exit 0
fi
exit 1

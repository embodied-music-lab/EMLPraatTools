#!/bin/bash
# ---------------------------------------------------------------------------
# Normality driver -- the headless half. D137.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   harness/normality/run.sh [case-name-substring]
#
# Sixteen cases through case.praat, ONE PRAAT PROCESS EACH, then the decision
# grid through decision.praat. One process per case for the same reason
# harness/disclosure/run.sh uses one: a Praat script error aborts the whole
# script, so a shared process would let a single degenerate case erase the
# verdict on every case after it -- and half of these cases are degenerate on
# purpose.
#
# This half does NOT cover check-normality's per-group mode. That branch is
# inline in an interactive wrapper whose first statement is `beginPause:`,
# which cannot run under `praat --run` at all. pergroup.sh beside this file
# drives it through the GUI, over the very CSV files this script writes.
# Run this one FIRST; pergroup.sh reads out/data/.
#
# Output: harness/normality/out/
#   data/<case>.csv           the table, as pergroup.sh will read it back
#   info/<case>_analysis.txt  Info window after @emlRunNormalityAnalysis
#   info/<case>_wizard.txt    Info window after @wizardNormDiag
#   manifest.csv              case,n_rows,kind
#   results.csv               case,site,statistic,value
#   refusals.tsv              case<TAB>site<TAB>message
#   decision.csv              the 360-row hierarchy grid
#   RESULTS.tsv               case<TAB>verdict<TAB>exit  -- per-case process
#                             outcome, so a case that CRASHED is a recorded
#                             fact and not an absence
#
# validate/v32_normality_parity.R reads all of it.
# ---------------------------------------------------------------------------
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
OUT=${EML_NORMALITY_OUT:-$HERE/out}
PRAAT=${PRAAT:-praat}
PREFS=${EML_NORMALITY_PREFS:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/prefs"}
FILTER="${1:-}"

# The cases, in the order the harness header documents them.
CASES="g01_normal g02_largen g03_severe g04_reject30 g05_severe12 g06_min3
       d01_skew d02_kurt p01_groups
       r01_blank r02_single r03_identical r04_n2 r05_swceil r06_text
       r07_swceil_sev"

mkdir -p "$OUT/data" "$OUT/info" "$OUT/rows" "$OUT/pergroup" "$PREFS"

# Clear stale per-case artefacts. Without this a RENAMED case leaves its old
# fragment behind and the concatenation below feeds the validator a previous
# run's evidence -- the failure harness/disclosure/run.sh records having hit
# on 7 Aug 2026 when gviolin11 became gviolin25 and the old logs kept the old
# assertions green.
if [ -z "$FILTER" ]; then
    rm -f "$OUT"/rows/* "$OUT"/info/* "$OUT"/data/* "$OUT"/*.log
    : > "$OUT/RESULTS.tsv"
fi

for c in $CASES; do
    [ -n "$FILTER" ] && case "$c" in *"$FILTER"*) ;; *) continue ;; esac
    # DISPLAY deliberately unset: proves this half needs no X server.
    env -u DISPLAY EML_NORM_CASE="$c" EML_NORMALITY_OUT="$OUT" \
        "$PRAAT" --pref-dir="$PREFS" --run "$HERE/case.praat" \
        > "$OUT/$c.log" 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        verdict=PROCESS_FAILED
    elif grep -qiE "^Error|not completed|Unknown variable" "$OUT/$c.log"; then
        # A Praat script error leaves exit 0 in some paths; the log is the
        # authority. Same test as harness/disclosure/run.sh.
        verdict=SCRIPT_ERROR
    elif [ -s "$OUT/rows/${c}_results.csv" ]; then
        verdict=OK
    else
        verdict=NO_RESULTS
    fi
    printf '%s\t%s\t%s\n' "$c" "$verdict" "$rc" >> "$OUT/RESULTS.tsv"
    printf '  %-16s %s\n' "$c" "$verdict"
done

# --- concatenate the per-case fragments ------------------------------------
# The headers are written HERE and the fragments carry none, so a fragment
# cannot contribute a header row that read.csv would silently take as data.
{ echo "case,n_rows,kind"
  cat "$OUT"/rows/*_manifest.csv 2>/dev/null | grep -v '^$'
} > "$OUT/manifest.csv"
{ echo "case,site,statistic,value"
  cat "$OUT"/rows/*_results.csv 2>/dev/null | grep -v '^$'
} > "$OUT/results.csv"
{ printf 'case\tsite\tmessage\n'
  cat "$OUT"/rows/*_refusals.tsv 2>/dev/null | grep -v '^$'
} > "$OUT/refusals.tsv"

# --- the decision grid -----------------------------------------------------
if [ -z "$FILTER" ]; then
    env -u DISPLAY EML_NORMALITY_OUT="$OUT" \
        "$PRAAT" --pref-dir="$PREFS" --run "$HERE/decision.praat" \
        > "$OUT/decision.log" 2>&1
    printf '  %-16s %s\n' "decision grid" \
        "$(wc -l < "$OUT/decision.csv") lines"
fi

echo "normality cases written to $OUT"

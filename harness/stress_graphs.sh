#!/bin/bash
# ---------------------------------------------------------------------------
# Graph stress driver.
#
# Every case runs in its OWN praat process. That is the whole point: a Praat
# script error aborts the script, so a single driver running twenty cases
# reports one failure and hides the nineteen behind it. One process per case
# costs about a second each and gives an independent verdict per case.
#
# Draw procedures do not call beginPause:, so unlike the wrapper scripts they
# run under `praat --run` with no X server. Verified 6 Aug 2026.
#
# Usage:  harness/stress_graphs.sh [case-name-substring]
# Output: stress/out/<case>.png  and  stress/out/<case>.log
#         stress/RESULTS.tsv     case, verdict, first error line
# ---------------------------------------------------------------------------
set -u
ROOT=/home/claude/EMLPraatTools
CASES=$ROOT/harness/stress_cases
OUT=/home/claude/stress/out
PRAAT=/home/claude/praat
PREFS=/home/claude/stress/prefs
FILTER="${1:-}"

mkdir -p "$OUT" "$PREFS"
: > /home/claude/stress/RESULTS.tsv

for f in "$CASES"/*.praat; do
    name=$(basename "$f" .praat)
    case "$name" in _*) continue ;; esac   # _prelude is included, never run
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) continue ;; esac
    rm -f "$OUT/$name.png"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to the interactive :99 instance.
    env -u DISPLAY EML_OUT="$OUT/$name.png" \
        "$PRAAT" --pref-dir="$PREFS" --run "$f" \
        > "$OUT/$name.log" 2>&1
    if [ -s "$OUT/$name.png" ]; then
        if grep -qi "^Error\|not completed" "$OUT/$name.log"; then
            verdict=DREW_THEN_FAILED
        else
            verdict=OK
        fi
    else
        if grep -qiE "EXPECTED-REFUSAL" "$OUT/$name.log"; then
            verdict=REFUSED
        else
            verdict=NO_FIGURE
        fi
    fi
    # Ink fraction. A draw procedure that renders axes, gridlines and a legend
    # but no data still writes a valid PNG, so "the file exists" is not a
    # verdict — emlDrawTimeSeriesCI produced exactly that on 6 Aug 2026 and the
    # driver called it OK. Fraction of non-near-white pixels separates a figure
    # with data (typically >4%) from an empty frame (~1-2%).
    ink=""
    if [ -s "$OUT/$name.png" ]; then
        ink=$(convert "$OUT/$name.png" -colorspace Gray -threshold 92% \
              -format "%[fx:100*(1-mean)]" info: 2>/dev/null \
              | awk '{printf "%.1f%%", $1}')
        case "$verdict" in
            OK) awk -v v="${ink%\%}" 'BEGIN{exit !(v+0 < 2.0)}' && verdict=BLANK_FRAME ;;
        esac
    fi
    first=$(grep -iE "^Error|Unknown|not completed|EXPECTED-REFUSAL" "$OUT/$name.log" \
            | head -1 | cut -c1-110)
    printf '%s\t%s\t%s\t%s\n' "$name" "$verdict" "$ink" "$first" \
        >> /home/claude/stress/RESULTS.tsv
done

awk -F"\t" '{printf "%-24s %-16s %-7s %s\n", $1, $2, $3, $4}' /home/claude/stress/RESULTS.tsv

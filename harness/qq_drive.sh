#!/bin/bash
# ---------------------------------------------------------------------------
# Q-Q path driver — one praat process per case.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Same shape as harness/stress_graphs.sh, and for the same reason: a Praat
# script error aborts the script, so a single process running every case
# reports one failure and hides the rest behind it.
#
# DISPLAY is deliberately unset. @emlDrawQQPlot reaches no beginPause:, so the
# whole Q-Q path must run with no X server; if it ever stops doing so, this
# fails rather than silently attaching to an interactive instance.
#
# Green cases and red cases run through the SAME driver. A red case is not
# expected to produce a figure — it is expected to produce a refusal, and the
# status CSV records which happened. validate/v23_qq_points.R asserts it.
#
# Usage:  harness/qq_drive.sh [case-name-substring]
# Output: harness/qq_out/<case>_points.csv, <case>_status.csv, <case>.png,
#                        <case>.log
#         harness/qq_out/RESULTS.tsv
# ---------------------------------------------------------------------------
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DRIVER=$ROOT/harness/qq_cases/qq_drive.praat
OUT=$ROOT/harness/qq_out
PRAAT=${PRAAT:-praat}
FILTER="${1:-}"

mkdir -p "$OUT"
: > "$OUT/RESULTS.tsv"

# case | input csv | column | expectation (draw | refuse)
CASES="
v15_f0|evidence/csv/v15_normality_input.csv|F0_Hz|draw
v15_shimmer|evidence/csv/v15_normality_input.csv|shimmer_pct|draw
v15_jitter|evidence/csv/v15_normality_input.csv|jitter_pct|draw
r1_na_soft|validate/redpath/r1_incomplete_cases.csv|SPL_soft|draw
r1_na_medium|validate/redpath/r1_incomplete_cases.csv|SPL_medium|draw
r1_na_loud|validate/redpath/r1_incomplete_cases.csv|SPL_loud|draw
r2_n2|validate/redpath/r2_two_subjects.csv|SPL_soft|refuse
r3_constant|validate/redpath/r3_zero_variance.csv|SPL_medium|refuse
qq_na_below_3|harness/qq_cases/qq_na_below_3.csv|value|refuse
qq_n3|harness/qq_cases/qq_n3.csv|value|draw
qq_skewed|harness/qq_cases/qq_skewed.csv|value|draw
qq_n10|harness/qq_cases/qq_n10.csv|value|draw
"

for spec in $CASES; do
    [ -z "$spec" ] && continue
    name=${spec%%|*}
    rest=${spec#*|}
    input=${rest%%|*}
    rest=${rest#*|}
    column=${rest%%|*}
    expect=${rest#*|}
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) continue ;; esac

    # Retried up to three times, and ONLY for one specific environment fault.
    #
    # In this container Praat's first file WRITE after a "Read Table from
    # comma-separated file:" fails at random, roughly one run in ten, with
    # "Cannot create file ... Hint: this is a folder, not a file" — an EISDIR
    # on a path that is plainly not a directory. Reduced to eight includes,
    # one Read Table and one writeFile with no plugin code involved at all
    # (3 failures in 25 runs), so it is not the Q-Q path and not this repo.
    # Every other error class is reported on the first attempt: a retry loop
    # that swallowed real script errors would be worse than no harness.
    attempt=0
    while [ "$attempt" -lt 3 ]; do
        attempt=$((attempt + 1))
        rm -f "$OUT/$name.png" "$OUT/${name}_chrome.png" \
              "$OUT/${name}_points.csv" \
              "$OUT/${name}_status.csv"
        env -u DISPLAY \
            EML_QQ_INPUT="$ROOT/$input" \
            EML_QQ_COL="$column" \
            EML_QQ_CASE="$name" \
            EML_QQ_OUTDIR="$OUT" \
            "$PRAAT" --run "$DRIVER" > "$OUT/$name.log" 2>&1
        grep -q "this is a folder, not a file" "$OUT/$name.log" || break
    done

    if grep -qiE "^Error|not completed|Unknown variable" "$OUT/$name.log"; then
        verdict=SCRIPT_ERROR
    elif [ -s "$OUT/$name.png" ]; then
        verdict=DREW
    elif grep -q "EXPECTED-REFUSAL" "$OUT/$name.log"; then
        verdict=REFUSED
    else
        verdict=NO_FIGURE
    fi

    # Ink fraction against the figure's OWN chrome.
    #
    # A figure with title, axes and gridlines but no data marks is a valid PNG
    # and passes every numeric check — the BLANK_FRAME defect elsewhere in
    # this repo is exactly that — so "the file exists" is not a verdict. A
    # FIXED threshold cannot be the verdict either: measured here, an empty
    # frame of this layout is 1.50% ink and the legitimate n = 3 Q-Q is 1.8%,
    # so the 2.0% constant the graph stress driver uses would condemn a
    # correct figure. The driver therefore renders each case a second time
    # with the dots and the reference line suppressed, and the test is that
    # the real figure carries more ink than its own chrome.
    ink=""
    if [ -s "$OUT/$name.png" ]; then
        ink=$(convert "$OUT/$name.png" -colorspace Gray -threshold 92% \
              -format "%[fx:100*(1-mean)]" info: 2>/dev/null \
              | awk '{printf "%.2f", $1}')
        chromeink=""
        if [ -s "$OUT/${name}_chrome.png" ]; then
            chromeink=$(convert "$OUT/${name}_chrome.png" -colorspace Gray \
                  -threshold 92% -format "%[fx:100*(1-mean)]" info: 2>/dev/null \
                  | awk '{printf "%.2f", $1}')
        fi
        if [ "$verdict" = DREW ]; then
            if [ -z "$chromeink" ]; then
                verdict=NO_CHROME_REF
            else
                awk -v a="$ink" -v b="$chromeink" \
                    'BEGIN{exit !(a+0 <= b+0 + 0.05)}' && verdict=BLANK_FRAME
            fi
        fi
        ink="$ink/$chromeink"
    fi

    case "$expect:$verdict" in
        draw:DREW|refuse:REFUSED) agree=OK ;;
        *) agree=MISMATCH ;;
    esac

    printf '%s\t%s\t%s\t%s%%\t%s\n' "$name" "$expect" "$verdict" "$ink" "$agree" \
        >> "$OUT/RESULTS.tsv"
done

awk -F"\t" '{printf "%-16s %-8s %-14s %-14s %s\n", $1, $2, $3, $4, $5}' \
    "$OUT/RESULTS.tsv"

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
#         harness/stress_out/RESULTS.tsv     case, verdict, first error line
# ---------------------------------------------------------------------------
set -u
# Resolved from this script's own location, never hardcoded. See
# harness/_env.sh for why -- an absolute ROOT is how a copy of this repo came
# to silently test the ORIGINAL tree.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
CASES=$ROOT/harness/stress_cases
# In-repo, like harness/qq_out which v23 reads. v27 reads these, and a fresh
# clone has to be able to run the suite -- an out-of-tree default would make
# v27 hard-stop on a machine that has never run this driver.
OUT=$ROOT/harness/stress_out
# PRAAT and PRAAT_TRUST come from _env.sh, which also REFUSES a binary below
# the plugin's 6.6.30 floor.
PREFS=$ROOT/harness/stress_cases/prefs   # scratch only, never read by a check
FILTER="${1:-}"

# Pixels that are clearly chromatic: saturation high AND lightness not near
# white. Chrome (axes, text, gridlines) is grey/black and scores near zero;
# the series palette scores strongly. Used by the blank-frame verdict below.
chromatic_px () {
    convert "$1" -colorspace HSL -separate +channel \
        \( -clone 1 -threshold 40% \) \( -clone 2 -negate -threshold 15% \) \
        -delete 0-2 -compose multiply -composite \
        -format "%[fx:int(w*h*mean)]" info: 2>/dev/null
}

mkdir -p "$OUT" "$PREFS"
: > "$OUT/RESULTS.tsv"

# Two passes. The empty_<family> cases are the chrome-only baselines the
# verdict below compares against, and the glob is alphabetical, so a
# single pass runs bar_* before empty_bar and finds no baseline to use.
# Render every baseline first, then everything else.
for f in $(ls "$CASES"/empty_*.praat 2>/dev/null; ls "$CASES"/*.praat | grep -v '/empty_'); do
    name=$(basename "$f" .praat)
    case "$name" in _*) continue ;; esac   # _prelude is included, never run
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) continue ;; esac
    rm -f "$OUT/$name.png"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to the interactive :99 instance.
    env -u DISPLAY EML_OUT="$OUT/$name.png" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$f" \
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
    # Blank-frame detection, by CHROMATIC PIXEL COUNT against the family's own
    # chrome-only baseline. Three detectors have now been tried here:
    #
    #   1. "the file exists"            — emlDrawTimeSeriesCI defeated it 6 Aug
    #                                     by writing a valid empty PNG.
    #   2. "ink fraction < 2.0%"        — condemned violin_zerovar and would
    #                                     have condemned violin_n1. BOTH ARE
    #                                     CORRECT FIGURES. Looked at them 7 Aug:
    #                                     a violin of a constant collapses to a
    #                                     line at that constant, and a violin of
    #                                     n=1 to a tick at the value. Two thin
    #                                     lines are ~0.1 pp of a 1800x1200 frame,
    #                                     so a right answer measured 1.0%.
    #   3. chromatic pixels vs baseline — this. The plugin draws data in a
    #                                     coloured series palette and chrome in
    #                                     grey/black, so "did it draw data" is
    #                                     "are there chromatic pixels beyond what
    #                                     the empty frame's antialiasing yields".
    #
    # Measured 7 Aug 2026 at 1800x1200, chromatic pixels:
    #   empty_violin 4609 (baseline)   violin_n1 5318 (+15%)
    #   violin_zerovar 6046 (+31%)     violin_baseline 284121 (+6066%)
    # A 5% margin clears antialiasing jitter and still catches a true blank,
    # which scores +0%. Families with no empty_* counterpart fall back to the
    # absolute ink rule, and the verdict name says which rule was applied.
    ink=""
    chrom=""
    if [ -s "$OUT/$name.png" ]; then
        ink=$(convert "$OUT/$name.png" -colorspace Gray -threshold 92% \
              -format "%[fx:100*(1-mean)]" info: 2>/dev/null \
              | awk '{printf "%.3f%%", $1}')
        chrom=$(chromatic_px "$OUT/$name.png")
        case "$verdict" in
            OK)
                fam=${name%%_*}
                base="$OUT/empty_${fam}.png"
                if [ -s "$base" ] && [ "$name" != "empty_${fam}" ]; then
                    b=$(chromatic_px "$base")
                    awk -v c="$chrom" -v b="$b" \
                        'BEGIN{exit !(b+0 > 0 ? c+0 <= b*1.05 : c+0 == 0)}' \
                        && verdict=BLANK_FRAME
                else
                    awk -v v="${ink%\%}" 'BEGIN{exit !(v+0 < 2.0)}' \
                        && verdict=BLANK_FRAME_ABS
                fi
                ;;
        esac
    fi
    first=$(grep -iE "^Error|Unknown|not completed|EXPECTED-REFUSAL" "$OUT/$name.log" \
            | head -1 | cut -c1-110)
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$verdict" "$ink" "$chrom" "$first" \
        >> "$OUT/RESULTS.tsv"
done

awk -F"\t" '{printf "%-24s %-16s %-7s %s\n", $1, $2, $3, $4}' "$OUT/RESULTS.tsv"

#!/bin/bash
# ---------------------------------------------------------------------------
# Disclosure driver. Ten draw procedures x {Annotate on, off} x {clean data,
# six undefined values} = 40 figures, each in its own praat process for the
# same reason harness/stress_graphs.sh uses one: a Praat script error aborts
# the script, so one process per case gives an independent verdict per case.
#
# Usage:  harness/disclosure/run.sh [chart-name-substring]
# Output: harness/disclosure/out/<chart>_a<0|1>_d<0|1>.png
#         harness/disclosure/out/<chart>_a<0|1>_d<0|1>.log
#         harness/disclosure/out/RESULTS.tsv
#             chart, annotate, dirty, verdict, info-lines, figure-lines
#         harness/disclosure/out/oc_<case>_a<0|1>.png / .log
#         harness/disclosure/out/OVERCAP.tsv
#             case, annotate, verdict, info-lines, figure-lines, signature
#
# The OVERCAP half drives harness/disclosure/overcap.praat: the three shapes
# that push a procedure past a limit it holds (over-cap scatter annotation,
# missing bar group vs measured zero, twenty-fifth sub-group). SIGNATURE is
# ImageMagick's pixel-content hash, not a file checksum: it is what lets the
# validator assert that a bar chart with a missing G3 does not render the SAME
# PICTURE as one whose G3 really measured zero. A count of disclosures cannot
# make that assertion, and that pair is the whole point of the defect.
#
# validate/v29_figure_disclosure.R reads the logs and both TSVs.
# ---------------------------------------------------------------------------
set -u
# Resolved from this script's own location, never hardcoded. harness/_env.sh
# also supplies PRAAT and PRAAT_TRUST, and REFUSES a Praat below the plugin's
# 6.6.30 floor. See its header for why an absolute ROOT was a real defect and
# not a cosmetic one.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_env.sh" || exit 1
ROOT="$EML_ROOT"
CASE=$ROOT/harness/disclosure/case.praat
OVERCAP=$ROOT/harness/disclosure/overcap.praat
OUT=$ROOT/harness/disclosure/out
# PRAAT and PRAAT_TRUST come from _env.sh.
PREFS=$ROOT/harness/disclosure/prefs
FILTER="${1:-}"

mkdir -p "$OUT" "$PREFS"
: > "$OUT/RESULTS.tsv"
: > "$OUT/OVERCAP.tsv"
# Clear stale per-case artefacts. Without this a RENAMED case leaves its old
# .log behind and a validator that still names it reads a previous run's
# evidence and passes -- measured 7 Aug 2026, when gviolin11 was renamed to
# gviolin25 and the old logs kept the old assertions green.
rm -f "$OUT"/*.log "$OUT"/*.png

# Pixel-content hash. `convert ... -format "%#" info:` is ImageMagick's
# signature of the decoded pixels, so two files that decode to the same image
# share it however they were encoded, and two that differ by one drawn line do
# not. Used only by the OVERCAP half.
sig_px () {
    convert "$1" -format "%#" info: 2>/dev/null
}

for chart in ts tsci spaghetti bar violin scatter box hist gviolin gbox; do
    [ -n "$FILTER" ] && case "$chart" in *"$FILTER"*) ;; *) continue ;; esac
    for ann in 0 1; do
        for dirty in 0 1; do
            name="${chart}_a${ann}_d${dirty}"
            rm -f "$OUT/$name.png"
            # DISPLAY deliberately unset: proves the case needs no X server.
            env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CHART="$chart" \
                EML_ANNOTATE="$ann" EML_DIRTY="$dirty" \
                "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$CASE" \
                > "$OUT/$name.log" 2>&1
            if [ -s "$OUT/$name.png" ]; then
                if grep -qiE "^Error|not completed|Unknown variable" \
                        "$OUT/$name.log"; then
                    verdict=DREW_THEN_FAILED
                else
                    verdict=OK
                fi
            else
                verdict=NO_FIGURE
            fi
            info=$(sed -n 's/^LEDGER .* info=\([0-9]*\) .*$/\1/p' \
                   "$OUT/$name.log" | head -1)
            fig=$(sed -n 's/^LEDGER .* fig=\([0-9]*\)$/\1/p' \
                  "$OUT/$name.log" | head -1)
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$chart" "$ann" "$dirty" "$verdict" "${info:-NA}" "${fig:-NA}" \
                >> "$OUT/RESULTS.tsv"
        done
    done
done

# --- OVER-CAP half ---------------------------------------------------------
# Six constructions x {Annotate off, on}. Same one-process-per-case rule.
for oc in scatter8 scatter21 barmix barzero gviolin25 gbox25; do
    [ -n "$FILTER" ] && case "$oc" in *"$FILTER"*) ;; *) continue ;; esac
    for ann in 0 1; do
        name="oc_${oc}_a${ann}"
        rm -f "$OUT/$name.png"
        env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CASE="$oc" \
            EML_ANNOTATE="$ann" \
            "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$OVERCAP" \
            > "$OUT/$name.log" 2>&1
        if [ -s "$OUT/$name.png" ]; then
            if grep -qiE "^Error|not completed|Unknown variable" \
                    "$OUT/$name.log"; then
                verdict=DREW_THEN_FAILED
            else
                verdict=OK
            fi
        else
            verdict=NO_FIGURE
        fi
        info=$(sed -n 's/^LEDGER .* info=\([0-9]*\) .*$/\1/p' \
               "$OUT/$name.log" | head -1)
        fig=$(sed -n 's/^LEDGER .* fig=\([0-9]*\)$/\1/p' \
              "$OUT/$name.log" | head -1)
        sig=$(sig_px "$OUT/$name.png")
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$oc" "$ann" "$verdict" "${info:-NA}" "${fig:-NA}" "${sig:-NA}" \
            >> "$OUT/OVERCAP.tsv"
    done
done

# The graphs form renders a SECOND floating box after the draw procedure
# returns (brackets + omnibus). This probe reproduces that sequence and
# records which corner each box went to, so v29 can assert they never
# coincide -- they did, on 7 Aug 2026, and the omnibus was painted over the
# disclosure.
if [ -z "$FILTER" ]; then
    env -u DISPLAY "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$ROOT/harness/disclosure/probe_formpath.praat" \
        > "$OUT/formpath.log" 2>&1
fi

awk -F"\t" '{printf "%-10s a=%s d=%s  %-16s info=%-3s fig=%s\n", \
             $1, $2, $3, $4, $5, $6}' "$OUT/RESULTS.tsv"
awk -F"\t" '{printf "%-10s a=%s      %-16s info=%-3s fig=%-3s sig=%s\n", \
             $1, $2, $3, $4, $5, substr($6, 1, 12)}' "$OUT/OVERCAP.tsv"
grep -h "^FORMCORNER" "$OUT/formpath.log" 2>/dev/null

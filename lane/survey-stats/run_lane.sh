#!/usr/bin/env bash
# ===========================================================================
# run_lane.sh — one command greens the whole survey-stats lane
# ===========================================================================
# Runs, in order:
#   1. the two dev-test suites (Praat, via the same resolver the rest of
#      the repo uses: $PRAAT, then ../praat, then praat_barren / praat)
#   2. verify-survey-lane.R (every dev-test literal against R)
#   3. the three lane validators v90 / v91 / v92 (live Praat vs R oracle,
#      each with its expect-differ negative-control leg)
#   4. the RED demonstration: each validator re-run with EML_LANE_RED=1,
#      which pits the named agreement check against a scratch copy of the
#      kernel carrying a seeded defect; the run MUST exit 1 (the check
#      goes red). Transcripts land in lane/survey-stats/evidence/.
#
# Exit status 0 means every green leg passed AND every red leg failed as
# required. Any other combination exits 1.
# ===========================================================================

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
EVID="$HERE/evidence"
mkdir -p "$EVID"

# --- Praat resolution: same order and floor as harness/_env.sh ----------
if [[ -z "${PRAAT:-}" ]]; then
    for _cand in "$ROOT/../praat" "$(command -v praat_barren 2>/dev/null)" \
                 "$(command -v praat 2>/dev/null)"; do
        if [[ -n "$_cand" && -x "$_cand" ]]; then
            PRAAT="$_cand"
            break
        fi
    done
fi
if [[ -z "${PRAAT:-}" ]]; then
    echo "run_lane.sh: no Praat binary found (set \$PRAAT)" >&2
    exit 1
fi
export PRAAT
_ver="$("$PRAAT" --version 2>&1 | head -1)"
case "$_ver" in
    *" 6.6.3"*|*" 6.6.4"*|*" 6.7"*|*" 6.8"*|*" 6.9"*|*" 7."*) : ;;
    *)  echo "run_lane.sh: REFUSED — unsupported Praat: $_ver" >&2
        exit 1 ;;
esac
echo "Praat: $_ver"

fail=0

step() {
    echo
    echo "== $1 =="
}

# --- 1. Dev tests --------------------------------------------------------
for t in test-psychometrics.praat test-categorical.praat; do
    step "dev test: $t"
    out="$(cd "$ROOT/plugin/dev/tests/phase2" && \
           env -u DISPLAY "$PRAAT" --run "$t" 2>&1)"
    echo "$out" | tail -3
    if ! echo "$out" | grep -q "status=PASS"; then
        echo "FAIL: $t did not report status=PASS" >&2
        fail=1
    fi
done

# --- 2. Literal verification --------------------------------------------
step "verify-survey-lane.R (dev-test literals vs R)"
if ! (cd "$ROOT/plugin/dev/tests/phase2" && Rscript verify-survey-lane.R \
      > "$EVID/verify_literals.txt" 2>&1); then
    tail -5 "$EVID/verify_literals.txt"
    echo "FAIL: literal verification" >&2
    fail=1
else
    tail -2 "$EVID/verify_literals.txt"
fi

# --- 3. Validators, green mode ------------------------------------------
for v in v90_lane_alpha_oracle v91_lane_chisq_oracle v92_lane_wilson_oracle; do
    step "validator: $v (green)"
    if ! (cd "$ROOT/validate" && Rscript "$v.R" \
          > "$EVID/${v}_green.txt" 2>&1); then
        tail -8 "$EVID/${v}_green.txt"
        echo "FAIL: $v" >&2
        fail=1
    else
        tail -2 "$EVID/${v}_green.txt"
    fi
done

# --- 4. Negative-control RED demonstration ------------------------------
# Each validator re-runs against a seeded-defect scratch copy with the
# STANDARD agreement check; the run must go red (exit 1). A red leg that
# comes back green means the check cannot fail, and the lane fails.
for v in v90_lane_alpha_oracle v91_lane_chisq_oracle v92_lane_wilson_oracle; do
    step "validator: $v (RED demonstration, must fail)"
    if (cd "$ROOT/validate" && EML_LANE_RED=1 Rscript "$v.R" \
        > "$EVID/${v}_red.txt" 2>&1); then
        echo "FAIL: $v stayed green against a seeded defect" >&2
        fail=1
    else
        grep -E "^FAIL" "$EVID/${v}_red.txt" | tail -2
        echo "went red as required (exit 1)"
    fi
done

echo
if [[ $fail -eq 0 ]]; then
    echo "LANE GREEN: dev tests, literals, three oracles, and all three"
    echo "seeded-defect red demonstrations behaved as required."
else
    echo "LANE FAILED — see above." >&2
fi
exit $fail

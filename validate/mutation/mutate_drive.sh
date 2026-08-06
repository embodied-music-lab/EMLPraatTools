#!/usr/bin/env bash
# ============================================================================
# mutate_drive.sh — prove the validation harness bites.
#
# Each mutation corrupts one committed evidence file and re-runs the suite.
# A mutation SUCCEEDS if the suite responds — either by gaining at least one
# new FAIL over the baseline, or by halting on the corrupted capture. A suite
# that stays green under a corrupted capture is validating nothing, which is
# the failure mode this driver exists to expose.
#
# Baseline-relative: no check counts are hardcoded, so the driver survives
# suite growth. Requires a CLEAN git tree (restoration is `git checkout --`).
#
#     bash validate/mutation/mutate_drive.sh
#
# Exit 0 iff the baseline reproduces AND every mutation is detected.
# ============================================================================
set -u
cd "$(git rev-parse --show-toplevel)"

if ! git diff --quiet -- evidence/; then
    echo "evidence/ has uncommitted changes; refusing to mutate" >&2; exit 2
fi

run_suite() {  # -> "<exitcode> <failcount>" ; failcount=HALT if the run aborted
    local log; log=$(mktemp)
    Rscript validate/run_all.R > "$log" 2>&1
    local ec=$?
    if grep -q "Execution halted" "$log"; then echo "$ec HALT"
    else echo "$ec $(grep -c '^FAIL' "$log" || true)"; fi
    rm -f "$log"
}

read -r BASE_EC BASE_FAILS <<< "$(run_suite)"
echo "baseline: exit=$BASE_EC fails=$BASE_FAILS"
if [ "$BASE_FAILS" = "HALT" ]; then
    echo "baseline itself halts; fix the suite before mutating" >&2; exit 2
fi

PASS=0; FAIL=0

mutate() {  # <name> <file> <sed-expr> <expectation: FAILS|HALT|ANY>
    local name=$1 file=$2 expr=$3 want=$4
    if ! sed --in-place "$expr" "$file" 2>/dev/null || git diff --quiet -- "$file"; then
        echo "SKIP  $name (pattern not present in $file)"; git checkout -q -- "$file"; return
    fi
    read -r ec fails <<< "$(run_suite)"
    git checkout -q -- "$file"
    local ok=no
    case $want in
        HALT) [ "$fails" = "HALT" ] && ok=yes ;;
        FAILS) [ "$fails" != "HALT" ] && [ "$fails" -gt "$BASE_FAILS" ] && ok=yes ;;
        ANY) { [ "$fails" = "HALT" ] || [ "$fails" -gt "$BASE_FAILS" ]; } && ok=yes ;;
    esac
    if [ $ok = yes ]; then
        echo "OK    $name detected (exit=$ec result=$fails)"; PASS=$((PASS+1))
    else
        echo "MISS  $name NOT detected (exit=$ec result=$fails, baseline=$BASE_FAILS)"; FAIL=$((FAIL+1))
    fi
}

# The mutation set. sed patterns target values the suite reads; if a capture
# is reformatted, a stale pattern reports SKIP rather than a false OK.
mutate "tukey cell corrupt (v09)" \
    evidence/info/v09_anova_tukey_info.txt '0,/0\.0018/s//0.0088/' ANY
mutate "tukey symmetric pair corrupt (v09)" \
    evidence/info/v09_anova_tukey_info.txt 's/0\.0018/0.0088/g' ANY
mutate "descriptive mean shifted one display ULP x10 (v14)" \
    evidence/info/v14_descriptive_info.txt '0,/88\.3272/s//88.3282/' ANY
mutate "label deleted -> harness must halt (v05)" \
    evidence/info/v05_paired_info.txt "/Cohen's dz/d" HALT
mutate "dunn z sign flipped (v10)" \
    evidence/info/v10_kw_dunn_info.txt '0,/-3\.04/s//3.04/' ANY
mutate "csv export df corrupted (v16)" \
    evidence/csv_export/anova.csv 's/,df1,2$/,df1,3/' ANY
mutate "csv export slope corrupted (v16)" \
    evidence/csv_export/regression.csv 's/estimate,1\.889/estimate,1.989/' ANY

# Confirm clean restoration
read -r ec fails <<< "$(run_suite)"
echo "restored: exit=$ec fails=$fails (baseline was $BASE_FAILS)"
[ "$fails" = "$BASE_FAILS" ] || { echo "RESTORATION FAILED" >&2; exit 2; }

echo "$PASS detected, $FAIL missed"
exit $(( FAIL > 0 ? 1 : 0 ))

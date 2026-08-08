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
# suite growth.
#
#     bash validate/mutation/mutate_drive.sh          # preflight + full run
#     bash validate/mutation/mutate_drive.sh --audit  # preflight table only
#
# PREFLIGHT. Before any suite runs, every case is applied to a COPY of its
# target and the copy compared with the original. A case whose sed no longer
# changes anything cannot corrupt anything, so it can never be detected, so
# it is not a pass — it is DEAD, and the driver exits 3 naming it. This is
# not a warning. On 7 Aug 2026 the v09 and v10 captures were re-driven and
# @emlFormatP's output moved from "0.0018" to ".002"; the two cases aimed at
# the old literal stopped biting and reported a quiet SKIP that nobody read.
# A mutation driver that silently stops biting is the same defect as a
# validator that silently stops checking. Hence: absent pattern = failure.
#
# A case may opt out only by declaring a reason as its fifth field, e.g.
# SKIPPABLE:nist .dat files are not redistributed. The reason is printed on
# every run. There is no unnamed skip and no default skip.
#
# RESTORATION is by copy, never by git. Every target is copied to a temp dir
# during preflight, before a byte is written, and copied back after each case
# and again under an EXIT/INT/TERM trap, so an interrupted run still leaves the
# tree as it found it. The final check byte-compares each touched file with its
# pre-run copy — the suite merely reproducing its baseline count would not
# notice a corrupted byte no validator reads.
#
# The driver runs NO git command that writes. It previously restored with
# `git checkout -- <file>`; that is unsafe in a checkout more than one agent is
# working in, where it would discard their uncommitted work. `rev-parse` and
# `diff --quiet` are read-only, and the restoration check no longer consults
# git at all, so a concurrent agent adding files under evidence/ cannot make a
# clean restoration look like a failure.
#
# Exit 0 iff every case fires, the baseline reproduces, every mutation is
# detected, and the tree is byte-identical afterwards.
#   1 = a mutation went undetected     3 = a case is dead (cannot fire)
#   2 = precondition or restoration failure
# ============================================================================
set -u
cd "$(git rev-parse --show-toplevel)"        # read-only

if ! git diff --quiet -- evidence/; then     # read-only
    echo "evidence/ has uncommitted changes; refusing to mutate" >&2; exit 2
fi

# PRISTINE holds one untouched copy of every file any case names, taken during
# preflight before a single byte is written. It is the restore source, and it
# is also the only thing the final verification trusts: comparing the tree with
# `git status` alone is not safe here, because an unrelated agent working in
# the same checkout can add or change files under evidence/ while this runs and
# make a clean restoration look like a failure (seen 7 Aug 2026). Byte-compare
# what this driver actually touched instead — purely local, and correct no
# matter what else moves.
PRISTINE=$(mktemp -d)
TOUCHED=()                                   # repo-relative paths, deduplicated

pristine_of() { echo "$PRISTINE/$(tr '/' '@' <<< "$1")"; }

remember() {                                 # <file> -> snapshot it once
    local f=$1 p; p=$(pristine_of "$f")
    [ -e "$p" ] && return 0
    cp -p "$f" "$p" || return 1
    TOUCHED+=("$f")
}

restore_all() {                              # copy back anything that differs
    local f p
    for f in ${TOUCHED+"${TOUCHED[@]}"}; do
        p=$(pristine_of "$f")
        [ -e "$p" ] || continue
        cmp -s "$p" "$f" || cp -p "$p" "$f"
    done
}
cleanup() { restore_all; rm -rf "$PRISTINE"; }
# A signal handler that only cleans up is worse than none: bash RESUMES the
# script after the handler returns, so the run would carry on with its backup
# dir deleted and leave every later mutation in the tree. Caught 7 Aug 2026 by
# sending TERM mid-run. The signal handler must therefore terminate.
on_signal() {
    local name=$1 num=$2
    trap - EXIT; cleanup
    echo "interrupted by SIG$name; tree restored by copy" >&2
    exit $((128 + num))
}
trap cleanup EXIT
trap 'on_signal INT   2' INT
trap 'on_signal TERM 15' TERM


run_suite() {  # -> "<exitcode> <failcount>" ; failcount=HALT if the run aborted
    local log; log=$(mktemp)
    Rscript validate/run_all.R > "$log" 2>&1
    local ec=$?
    if grep -q "Execution halted" "$log"; then echo "$ec HALT"
    else echo "$ec $(grep -c '^FAIL' "$log" || true)"; fi
    rm -f "$log"
}

# ---------------------------------------------------------------------------
# The case list, declared once and walked twice: once by preflight_case to
# prove every case still bites, once by mutate_case to run it.
#
#   M <name> <file> <sed-expr> <FAILS|HALT|ANY> [SKIPPABLE:<reason>]
# ---------------------------------------------------------------------------
CASES() {
  # The Tukey matrix p cell for Soprano-Mezzo. Was the literal "0.0018" until
  # D110's re-drive of 7 Aug 2026 put the matrix through @emlFormatP's bare
  # APA form, three decimals and no leading zero. ".002" is that same cell.
  # First-occurrence-only breaks the printed matrix's symmetry as well as the
  # value; the /g form corrupts both cells, so symmetry survives and only the
  # value check can catch it. Both are wanted: they separate "the suite reads
  # this number" from "the suite only cross-checks the two halves".
  M "tukey cell corrupt (v09)" \
      evidence/info/v09_anova_tukey_info.txt '0,/\.002/s//.009/' ANY
  M "tukey symmetric pair corrupt (v09)" \
      evidence/info/v09_anova_tukey_info.txt 's/\.002/.009/g' ANY
  M "descriptive mean shifted one display ULP x10 (v14)" \
      evidence/info/v14_descriptive_info.txt '0,/88\.3272/s//88.3282/' ANY
  M "label deleted -> harness must halt (v05)" \
      evidence/info/v05_paired_info.txt "/Cohen's dz/d" HALT
  M "dunn z sign flipped (v10)" \
      evidence/info/v10_kw_dunn_info.txt '0,/-3\.04/s//3.04/' ANY
  M "csv export df corrupted (v16)" \
      evidence/csv_export/anova.csv 's/,df1,2$/,df1,3/' ANY
  M "csv export slope corrupted (v16)" \
      evidence/csv_export/regression.csv 's/estimate,1\.889/estimate,1.989/' ANY
}

# --- phase 1: preflight ----------------------------------------------------
# Applies each case to a copy. Reports PRESENT / ABSENT / NO FILE. Nothing in
# the working tree is written.
LIVE=0; DEAD=0; SKIPPED=0
preflight_case() {
    local name=$1 file=$2 expr=$3 skip=${5:-}
    local why=${skip#SKIPPABLE:}
    if [ ! -f "$file" ]; then
        if [ -n "$skip" ]; then
            printf '  %-46s %-9s %s\n' "$name" "NO FILE" "declared skippable: $why"
            SKIPPED=$((SKIPPED+1))
        else
            printf '  %-46s %-9s %s\n' "$name" "NO FILE" "$file"
            DEAD=$((DEAD+1))
        fi
        return
    fi
    remember "$file"
    local probe; probe=$(mktemp)
    cp -p "$file" "$probe"
    if sed --in-place "$expr" "$probe" 2>/dev/null && ! cmp -s "$file" "$probe"; then
        printf '  %-46s %-9s %s\n' "$name" "PRESENT" "$file"
        LIVE=$((LIVE+1))
    elif [ -n "$skip" ]; then
        printf '  %-46s %-9s %s\n' "$name" "ABSENT" "declared skippable: $why"
        SKIPPED=$((SKIPPED+1))
    else
        printf '  %-46s %-9s %s\n' "$name" "ABSENT" "$file  <-- DEAD CASE"
        DEAD=$((DEAD+1))
    fi
    rm -f "$probe"
}

echo "preflight: does every case still bite?"
M() { preflight_case "$@"; }
CASES
echo "preflight: $LIVE live, $SKIPPED declared-skippable, $DEAD dead"

if [ "$DEAD" -gt 0 ]; then
    echo >&2
    echo "$DEAD mutation case(s) cannot fire: the pattern is no longer in the" >&2
    echo "capture. A case that cannot corrupt anything cannot be detected, so" >&2
    echo "it is not a pass. Repoint it at the value the file carries now, or" >&2
    echo "give it an explicit SKIPPABLE:<reason> fifth field." >&2
    exit 3
fi
[ "${1:-}" = "--audit" ] && { echo "audit only; no mutation run"; exit 0; }

# --- phase 2: baseline -----------------------------------------------------
read -r BASE_EC BASE_FAILS <<< "$(run_suite)"
echo
echo "baseline: exit=$BASE_EC fails=$BASE_FAILS"
if [ "$BASE_FAILS" = "HALT" ]; then
    echo "baseline itself halts; fix the suite before mutating" >&2; exit 2
fi

# --- phase 3: mutate -------------------------------------------------------
PASS=0; MISSED=0
mutate_case() {
    local name=$1 file=$2 expr=$3 want=$4 skip=${5:-}
    if [ ! -f "$file" ] && [ -n "$skip" ]; then
        echo "SKIP  $name (declared: ${skip#SKIPPABLE:})"; return
    fi
    local bak; bak=$(pristine_of "$file")     # taken in preflight, kept to exit
    if ! sed --in-place "$expr" "$file" 2>/dev/null || cmp -s "$bak" "$file"; then
        cp -p "$bak" "$file"
        if [ -n "$skip" ]; then
            echo "SKIP  $name (declared: ${skip#SKIPPABLE:})"; return
        fi
        # Preflight cleared this case, so reaching here means the tree moved
        # under the run. Treat it as a miss rather than swallowing it.
        echo "DEAD  $name did not change $file"; MISSED=$((MISSED+1)); return
    fi
    read -r ec fails <<< "$(run_suite)"
    cp -p "$bak" "$file"
    local ok=no
    case $want in
        HALT) [ "$fails" = "HALT" ] && ok=yes ;;
        FAILS) [ "$fails" != "HALT" ] && [ "$fails" -gt "$BASE_FAILS" ] && ok=yes ;;
        ANY) { [ "$fails" = "HALT" ] || [ "$fails" -gt "$BASE_FAILS" ]; } && ok=yes ;;
    esac
    if [ $ok = yes ]; then
        echo "OK    $name detected (exit=$ec result=$fails)"; PASS=$((PASS+1))
    else
        echo "MISS  $name NOT detected (exit=$ec result=$fails, baseline=$BASE_FAILS)"
        MISSED=$((MISSED+1))
    fi
}
echo
M() { mutate_case "$@"; }
CASES

# --- phase 4: restoration --------------------------------------------------
# Byte-level first: the suite reproducing its baseline count is necessary but
# not sufficient, since a corrupted byte the suite does not read would slip
# through unnoticed. Every file this driver touched is compared with the copy
# taken before anything was written.
echo
DIRTY=""
for f in ${TOUCHED+"${TOUCHED[@]}"}; do
    cmp -s "$(pristine_of "$f")" "$f" || DIRTY="$DIRTY  $f"$'\n'
done
if [ -n "$DIRTY" ]; then
    echo "RESTORATION FAILED — these differ from their pre-run bytes:" >&2
    printf '%s' "$DIRTY" >&2; exit 2
fi
echo "restoration: ${#TOUCHED[@]} touched files byte-identical to pre-run"
read -r ec fails <<< "$(run_suite)"
echo "restored: suite reproduces, exit=$ec fails=$fails (baseline was $BASE_FAILS)"
[ "$fails" = "$BASE_FAILS" ] || { echo "RESTORATION FAILED" >&2; exit 2; }

echo "$LIVE cases fired, $PASS detected, $MISSED missed, $SKIPPED declared-skippable"
exit $(( MISSED > 0 ? 1 : 0 ))

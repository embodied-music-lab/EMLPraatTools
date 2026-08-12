#!/usr/bin/env bash
# ============================================================================
# record_e2e/run.sh — the recorder driven the way a user drives it
# ============================================================================
# Runs driver.praat, which starts a recording and then puts ten operations
# through `runScript:` — each in its OWN variable scope inside ONE Praat
# process, which is what a menu command gets. Emits out/RECORD.tsv, one row
# per operation, saying whether a step actually reached the buffer.
#
# WHY IT EXISTS. Every earlier test of the recorder started the recording and
# added steps in the SAME scope. A menu command ends and takes its variables
# with it; re-attaching across that boundary is the whole design, and nothing
# had ever crossed it. This is the §2h lesson applied before the defect rather
# than after: the parts were tested and the assembly was not.
#
# AND IT MEASURES COVERAGE. The recorder's infrastructure is complete; the
# number of operations that CALL it is not. A user who switches recording on
# and runs an operation that captures nothing gets an empty script with no
# warning, so the count goes in the artefact rather than in someone's memory.
#
# Run from anywhere:  bash harness/record_e2e/run.sh
# Exit 0 = the recording survived every invocation and a file was written.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_RECORD_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"

LOG="$OUT/driver.log"
REC="$OUT/recorded.praat"
rm -f "$LOG" "$REC" "$OUT/RECORD.tsv"

# ---------------------------------------------------------------------------
# THE DRIVER RUNS FROM plugin/scripts/, AND IT HAS TO.
#
# `include` resolves against the folder of the script that was RUN, not the
# folder of the file the directive sits in. eml-lib.praat's own line reads
# `include eml-lib-stats.praat`, so a driver anywhere else sends Praat looking
# for eml-lib-stats.praat beside the DRIVER and the barrel cannot be loaded at
# all. harness/wrappers/run.sh cds into plugin/scripts for the same reason.
#
# So the two fixtures are staged there for the run and removed after. The trap
# fires on any exit, including a crash, because a stray .praat left in
# plugin/scripts is a file harness/wrappers globs and validate/v35's census
# would report as an unexpected entry point -- correctly, and confusingly.
#
# Staging is also the more faithful test: a menu command IS a script in
# plugin/scripts, loading the barrel from there.
# ---------------------------------------------------------------------------
STAGE="$EML_ROOT/plugin/scripts"
cleanup () {
    rm -f "$STAGE/_record_e2e_driver.praat" "$STAGE/_record_e2e_op.praat" \
          "$STAGE/fixture.praat"
}
trap cleanup EXIT
sed 's|\.\./\.\./plugin/scripts/eml-lib\.praat|eml-lib.praat|; s|"op\.praat"|"_record_e2e_op.praat"|; s|"\.\./\.\./plugin/scripts/eml-record-start\.praat"|"eml-record-start.praat"|' \
    "$SCRIPT_DIR/driver.praat" > "$STAGE/_record_e2e_driver.praat"
sed 's|\.\./\.\./plugin/scripts/eml-lib\.praat|eml-lib.praat|' \
    "$SCRIPT_DIR/op.praat" > "$STAGE/_record_e2e_op.praat"
# THE FIXTURE IS A THIRD FILE, and forgetting it is exactly the failure this
# harness exists to catch, one level up: the driver's `include fixture.praat`
# resolves against plugin/scripts, so an unstaged fixture is an unopenable
# include and the whole run dies before the first operation.
# harness/norecord copies the same file for the same reason.
cp "$SCRIPT_DIR/fixture.praat" "$STAGE/fixture.praat"

# THE TIMESTAMP IS PINNED, or the artefact this commits differs on every run.
# @emlRecordBegin stamps the session with date$() so that a user's recording
# says when it was made; EML_RECORD_STAMP is the seam that makes the same code
# path diffable. Same role as EML_RECORD_OUT on the next line.
( cd "$STAGE" && env -u DISPLAY EML_RECORD_OUT="$REC" \
    EML_RECORD_STAMP="12 August 2026, 00:00:00" \
    timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run _record_e2e_driver.praat \
    > "$LOG" 2>&1 )

# PRAAT WRITES UTF-16 THE MOMENT THE TEXT IS NOT PURE ASCII, and a recorded
# workflow is a file a user opens, edits and commits. The plugin's own strings
# are ASCII on purpose, but a column name or a table name is the user's, so
# this cannot be assumed away -- normalise the same way harness/gui.sh and
# harness/record/roundtrip.sh already do, so the artefact in git is readable
# and validate/v39 can read it with plain readLines().
if [[ -f "$REC" ]] && file "$REC" | grep -q UTF-16; then
    iconv -f UTF-16 -t UTF-8 "$REC" -o "$REC.u8" && mv "$REC.u8" "$REC"
fi

TSV="$OUT/RECORD.tsv"
: > "$TSV"

started=$(sed -n 's/^RECSTART buffer=\([0-9-]*\).*/\1/p' "$LOG" | head -1)
survived=$(sed -n 's/^RECEND buffer=\([0-9-]*\) .*/\1/p' "$LOG" | head -1)
steps=$(sed -n 's/^RECEND buffer=[0-9-]* steps=\([0-9-]*\).*/\1/p' "$LOG" | head -1)
written=$(sed -n 's/^FLUSH written=\([0-9-]*\).*/\1/p' "$LOG" | head -1)

# One row per operation: name, steps before, steps after, verdict.
#
# THREE VERDICTS, NOT TWO, and the third is the one that matters. An operation
# that CRASHED and one that ran and recorded nothing both leave the step count
# unchanged, and the first version of this harness called both "silent" -- so
# ten scripts that never ran were reported as ten operations with no capture
# hook, and the coverage number was fiction. op.praat prints OPDONE as its
# last line; an operation without one did not finish.
while read -r name before after; do
    if ! grep -q "^OPDONE $name\$" "$LOG"; then
        verdict=DIDNOTRUN
    elif [[ "$after" -gt "$before" ]]; then
        verdict=recorded
    else
        verdict=silent
    fi
    printf '%s\t%s\t%s\t%s\n' "$name" "$before" "$after" "$verdict" >> "$TSV"
done < <(sed -n 's/^OP name=\([^ ]*\) k=[0-9]* nOps=[0-9]* before=\([0-9-]*\) after=\([0-9-]*\).*/\1 \2 \3/p' "$LOG")

nOps=$(wc -l < "$TSV")
nRec=$(awk -F"\t" '$4=="recorded"' "$TSV" | wc -l)
nDead=$(awk -F"\t" '$4=="DIDNOTRUN"' "$TSV" | wc -l)

printf '%-14s %s\n' "operation" "verdict"
awk -F"\t" '{printf "%-14s %s\n", $1, $4}' "$TSV"
echo
echo "recording started      : ${started:-?}"
echo "recording survived all : ${survived:-?}   steps=${steps:-?}"
echo "script written         : ${written:-?}"
echo "operations that record : $nRec of $nOps"
echo "operations that ran    : $((nOps - nDead)) of $nOps"

# THE PASS CONDITION IS THE MECHANISM, NOT THE COVERAGE. Coverage is a number
# this harness reports and validate/v39 pins; it is expected to be low today
# and to rise deliberately. What must not break is the recording surviving
# every invocation and producing a file.
fail=0
[[ "${started:-0}" == "1"  ]] || { echo "FAIL: the recording did not start"; fail=1; }
[[ "${survived:-0}" == "1" ]] || { echo "FAIL: the buffer did not survive the invocations"; fail=1; }
[[ "${written:-0}" == "1"  ]] || { echo "FAIL: no script was written"; fail=1; }
[[ "$nOps" -eq 38 ]] || { echo "FAIL: expected 38 operations, drove $nOps"; fail=1; }
# AN OPERATION THAT DID NOT RUN IS A HARNESS FAILURE, not a coverage figure.
[[ "$nDead" -eq 0 ]] || { echo "FAIL: $nDead operation(s) never completed — see $LOG"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "record_e2e: PASS — the recording crossed $nOps script boundaries"
    exit 0
fi
exit 1

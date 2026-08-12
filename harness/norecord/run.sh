#!/usr/bin/env bash
# ============================================================================
# norecord/run.sh — the plugin driven with the recorder NOT LOADED
# ============================================================================
# The recorder is optional. Every capture hook is guarded on
# variableExists ("emlRecordLoaded") so that a script including the stats and
# graphs files directly — a user script, a PraatGen companion — gets the
# analyses and the figures without it.
#
# Every shipped barrel includes the recorder, so no harness that loads a
# barrel can tell whether that guard is still there. This one includes the
# individual files and nothing else, and drives the same 27 operations
# harness/record_e2e drives from the same fixture and the same op.praat.
#
# It exists because the contract was broken twice on 12 Aug 2026 and both
# breaks reached a green suite: unguarded analysis hooks took
# plugin/dev/tests/phase2 down, and @emlRunAnovaAnalysis called into the
# recorder unconditionally.
#
# Run from anywhere:  bash harness/norecord/run.sh
# Exit 0 = all 27 operations completed with the recorder absent.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_NORECORD_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"

LOG="$OUT/driver.log"
TSV="$OUT/NORECORD.tsv"
rm -f "$LOG" "$TSV"

# Staged into plugin/scripts for the same reason record_e2e stages: `include`
# resolves against the folder of the script that was RUN, and the trap removes
# the fixtures on any exit so validate/v35's entry-point census does not meet
# a stray file it correctly cannot explain.
STAGE="$EML_ROOT/plugin/scripts"
REC_DIR="$EML_ROOT/harness/record_e2e"
cleanup () {
    rm -f "$STAGE/_norecord_driver.praat" "$STAGE/op.praat" \
          "$STAGE/fixture.praat"
}
trap cleanup EXIT
sed 's|\.\./\.\./plugin/|../|' "$SCRIPT_DIR/driver.praat" \
    > "$STAGE/_norecord_driver.praat"
# THE SAME TWO FILES record_e2e USES, copied rather than re-authored, so the
# operation list and the fixture data cannot drift between the two harnesses.
# op.praat runs through runScript:, which gives it its OWN scope — the
# driver's procedures are not visible to it, so it needs the same
# recorder-free include set rather than none at all. Substituted here rather
# than kept as a second copy of op.praat, which would be a second place for
# the operation calls to drift.
read -r -d '' NORECORD_INCLUDES <<'INC'
include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat
include ../stats/eml-result-writer.praat
include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
include ../graphs/eml-draw-procedures.praat
include ../stats/eml-analysis.praat
if variableExists ("emlRecordLoaded")
    exitScript: "NORECORD: the recorder was loaded. This run proves nothing."
endif
INC
awk -v inc="$NORECORD_INCLUDES" \
    '{ if ($0 == "include ../../plugin/scripts/eml-lib.praat") print inc; else print }' \
    "$REC_DIR/op.praat" > "$STAGE/op.praat"
cp "$REC_DIR/fixture.praat" "$STAGE/fixture.praat"

( cd "$STAGE" && env -u DISPLAY \
    timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run _norecord_driver.praat > "$LOG" 2>&1 )

: > "$TSV"
while read -r name; do
    if grep -q "^OPDONE $name\$" "$LOG"; then
        printf '%s\tran\n' "$name" >> "$TSV"
    else
        printf '%s\tDIDNOTRUN\n' "$name" >> "$TSV"
    fi
done < <(sed -n 's/^OP name=\([^ ]*\) k=[0-9]* nOps=[0-9]*.*/\1/p' "$LOG")

nOps=$(wc -l < "$TSV")
nDead=$(awk -F"\t" '$2=="DIDNOTRUN"' "$TSV" | wc -l)

printf '%-14s %s\n' "operation" "verdict"
awk -F"\t" '{printf "%-14s %s\n", $1, $2}' "$TSV"
echo
echo "operations that ran : $((nOps - nDead)) of $nOps"

fail=0
grep -q "^NORECORD DONE nOps=35\$" "$LOG" \
    || { echo "FAIL: the driver did not finish — see $LOG"; fail=1; }
[[ "$nOps" -eq 35 ]] || { echo "FAIL: expected 35 operations, drove $nOps"; fail=1; }
[[ "$nDead" -eq 0 ]] || { echo "FAIL: $nDead operation(s) failed with the recorder absent — see $LOG"; fail=1; }
# THE PROOF THAT THE RUN MEANT ANYTHING. A driver that somehow loaded the
# recorder would pass every check above while testing nothing.
grep -q "^NORECORD: the recorder was loaded" "$LOG" \
    && { echo "FAIL: the recorder was loaded — this run proves nothing"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "norecord: PASS — all $nOps operations ran with the recorder absent"
    exit 0
fi
exit 1

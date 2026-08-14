#!/usr/bin/env bash
# ============================================================================
# batchcmd/run.sh — run the batch module's commands, and its abort paths
# ============================================================================
# Two jobs, and the second is why this is a shell driver and not one Praat
# script.
#
# drive.praat exercises every non-acoustic command eml-batch-process.praat
# uses and writes what each returned. It can only record calls that SUCCEED,
# because a Praat script does not survive its own abort: the line that fails
# is the last line that runs, and nothing after it — including the write that
# would record the failure — happens at all.
#
# THE ABORTS ARE THE FINDING, THOUGH. Three of the module's calls take a
# number that comes straight from a user's `natural:` field, unclamped, and
# each of the three ends the whole batch rather than the file:
#
#     Get string:            past the end -> returns ""  -> Read from file:
#                            then fails on "<folder>/" and the script dies
#     Get number of intervals: tier past the tier count -> dies
#     Is interval tier:      tier past the tier count -> dies (which is why
#                            the module must ask Get number of tiers first)
#
# Each runs as its OWN process here, and what is recorded is the process's
# exit status and Praat's own error text. That is evidence a script cannot
# produce about itself. `nocheck` would let one script survive all three, but
# COMMANDS_Universal.txt's errata is explicit that nocheck must never be used
# as a diagnostic branch — after a failing nocheck the interpreter's variable
# state is unreliable, so a probe built on it would be measuring the probe.
#
# Run from anywhere:  bash harness/batchcmd/run.sh
# Exit 0 = drive completed and all three abort probes aborted as expected.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_BATCHCMD_DIR:-$SCRIPT_DIR/out}"
mkdir -p "$OUT"
TSV="$OUT/COMMANDS.tsv"
LOG="$OUT/driver.log"
PROBE="$OUT/probe"
rm -rf "$OUT/fixture" "$OUT/scaffold" "$PROBE"
rm -f "$TSV" "$LOG" "$OUT/probe.csv"
mkdir -p "$PROBE"

( cd "$SCRIPT_DIR" && env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST \
    --run drive.praat > "$LOG" 2>&1 )
driveStatus=$?

# ---------------------------------------------------------------------------
# THE ABORT PROBES
# ---------------------------------------------------------------------------
# Each writes MARKER only if the risky line RETURNED. A missing marker plus a
# non-zero exit is the abort; a present marker would mean Praat had changed
# and the module's guards were no longer needed.
probe () {
    local name="$1" body="$2"
    local f="$PROBE/$name.praat" log="$PROBE/$name.log"
    printf '%s\n' "$body" > "$f"
    ( cd "$PROBE" && env -u DISPLAY timeout 60 "$PRAAT" $PRAAT_TRUST \
        --run "$name.praat" > "$log" 2>&1 )
    local status=$?
    local reached=0
    grep -q "^MARKER$" "$log" && reached=1
    printf '%s_aborted\t%s\n' "$name" "$([[ $reached -eq 0 ]] && echo 1 || echo 0)" >> "$TSV"
    printf '%s_exit\t%s\n' "$name" "$status" >> "$TSV"
}

probe "read_after_string_overrun" \
'st = Create Strings as file list: "files", "'"$PROBE"'/*.praat"
n = Get number of strings
name$ = Get string: n + 99
s = Read from file: "'"$PROBE"'/" + name$
writeInfoLine: "MARKER"'

probe "intervals_tier_overrange" \
'tg = Create TextGrid: 0, 1, "words points", "points"
selectObject: tg
n = Get number of intervals: 5
writeInfoLine: "MARKER"'

probe "intervals_on_point_tier" \
'tg = Create TextGrid: 0, 1, "words points", "points"
selectObject: tg
n = Get number of intervals: 2
writeInfoLine: "MARKER"'

probe "isintervaltier_overrange" \
'tg = Create TextGrid: 0, 1, "words points", "points"
selectObject: tg
b = Is interval tier: 7
writeInfoLine: "MARKER"'

# ---------------------------------------------------------------------------
# FORM VARIABLE DERIVATION (APPENDIX_C §C.3)
# ---------------------------------------------------------------------------
# The module's sixteen field labels, verbatim, in a form: block. Praat is asked
# whether each DERIVED name exists — the names the module actually reads. This
# is a form: rather than the module's beginPause: because a beginPause cannot
# be answered by a headless process; §C.3 states the derivation algorithm is
# the same for both, and §C.1's 6.6.30 correction records the one thing that
# differs (bare vs quoted numeric defaults) and says quoting is not a defect.
cat > "$PROBE/derive.praat" <<'PRAAT'
form: "Batch Voice Analysis"
    folder: "Sound folder", ""
    word: "File extension", "wav"
    optionmenu: "Channel handling", 1
        option: "Mix to mono"
        option: "Left channel only"
        option: "Right channel only"
    folder: "Output folder", ""
    boolean: "Mean F0", 1
    boolean: "Mean intensity", 1
    boolean: "Jitter (local)", 0
    boolean: "Shimmer (local)", 0
    boolean: "HNR", 0
    boolean: "CPPS", 0
    positive: "Highest expected F0 (Hz)", "500"
    boolean: "Use TextGrids", 0
    folder: "TextGrid folder", ""
    natural: "Tier number", "1"
    word: "Target label", "V"
    boolean: "Clear Info window", 0
endform
names$# = {"sound_folder$", "file_extension$", "channel_handling",
    ... "channel_handling$", "output_folder$", "mean_F0", "mean_intensity",
    ... "jitter", "shimmer", "hNR", "cPPS", "highest_expected_F0",
    ... "use_TextGrids", "textGrid_folder$", "tier_number", "target_label$",
    ... "clear_Info_window"}
missing = 0
for i from 1 to size (names$#)
    if not variableExists (names$# [i])
        missing = missing + 1
    endif
endfor
writeInfoLine: "DERIVED_DECLARED ", size (names$#)
appendInfoLine: "DERIVED_MISSING ", missing
appendInfoLine: "OPTIONMENU_READBACK ", channel_handling$
appendInfoLine: "POSITIVE_READBACK ", highest_expected_F0
PRAAT
( cd "$PROBE" && env -u DISPLAY timeout 60 "$PRAAT" $PRAAT_TRUST \
    --run derive.praat "/tmp" "wav" "Left channel only" "/tmp/o" "yes" "yes" \
    "no" "no" "no" "no" "500" "no" "" "1" "V" "no" \
    > "$PROBE/derive.log" 2>&1 )

sed -n 's/^DERIVED_DECLARED \(.*\)$/form_derived_declared\t\1/p'  "$PROBE/derive.log" >> "$TSV"
sed -n 's/^DERIVED_MISSING \(.*\)$/form_derived_missing\t\1/p'    "$PROBE/derive.log" >> "$TSV"
sed -n 's/^OPTIONMENU_READBACK \(.*\)$/form_optionmenu_readback\t\1/p' "$PROBE/derive.log" >> "$TSV"
sed -n 's/^POSITIVE_READBACK \(.*\)$/form_positive_readback\t\1/p' "$PROBE/derive.log" >> "$TSV"

# ---------------------------------------------------------------------------
echo
printf '%-38s %s\n' KEY VALUE
awk -F"\t" '{printf "%-38s %s\n", $1, $2}' "$TSV"
echo

fail=0
grep -q "^completed	1$" "$TSV" \
    || { echo "FAIL: drive.praat did not finish (exit $driveStatus) — see $LOG"; fail=1; }
for p in read_after_string_overrun intervals_tier_overrange \
         intervals_on_point_tier isintervaltier_overrange; do
    grep -q "^${p}_aborted	1$" "$TSV" \
        || { echo "FAIL: $p did NOT abort — the module's guard may be moot now"; fail=1; }
done
grep -q "^form_derived_missing	0$" "$TSV" \
    || { echo "FAIL: a form label did not derive to the name the module reads"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "batchcmd: PASS — commands ran, aborts aborted, every label derived"
    exit 0
fi
exit 1

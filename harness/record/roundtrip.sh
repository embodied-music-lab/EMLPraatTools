#!/usr/bin/env bash
# ============================================================================
# roundtrip.sh — the check §9 of TREATMENT_record_workflow.md asks for
# ============================================================================
# Record a session. Emit the script. Run the emitted script in a FRESH Praat
# process. Diff the two Info outputs.
#
# If they differ, either the log is lying or the recorded path and the
# emitted path are not the same analysis. There is no third explanation.
#
# WHY THIS RUNS AT ALL, which it did not two hours ago. The proposal settled
# emission on wrapper-level `runScript:` calls, and no EML wrapper can be
# called headless: with arguments it fails "Found 3 arguments but expected
# only 0", and without them it reaches beginPause: and needs a display. Nor
# can beginPause: become form:, because a form is parsed once and cannot hold
# the loop that builds the column menus from the table. Moving emission to
# the API level — an include block and whatever object is selected — made
# this check reachable without touching a single wrapper.
#
# Run from anywhere:  bash harness/record/roundtrip.sh
# Exit 0 = the log and the analysis agree.
# ============================================================================
set -uo pipefail

# Resolved from this script's own location, never from the working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="$SCRIPT_DIR/out"

# THE PINNED BINARY AND AN ISOLATED PREFERENCES DIRECTORY, both of which this
# script lacked in its first cut and both of which harness/stress_graphs.sh
# and harness/disclosure/run.sh have had all along.
#
# 1. VERSION. A bare `praat` resolves to whatever is first on PATH, which in
#    this container is /usr/bin/praat -- 6.4.06, dated April 2024. That is
#    BELOW the plugin's own declared floor (emlMinPraatVersion = 6630 in
#    setup.praat) and is not the build evidence/info/ was captured on. The
#    first runs of this harness were therefore made on a Praat the plugin
#    refuses to load under. /home/claude/praat is the 6.6.30 symlink the
#    other harnesses use.
#
# 2. PREFERENCES. Without --pref-dir, Praat reads the user's prefs5, and
#    prefs5 decides the output encoding. That is exactly how this harness
#    came to pass five times and then fail: installing the plugin caused a
#    prefs5 to be written, "try ASCII, then UTF-16" took effect, and the
#    byte-oriented diff stopped matching. Isolating the preferences makes the
#    run reproducible; folding to UTF-8 below makes it correct either way.
#    Both are wanted -- the isolation is not a substitute for the fold,
#    because a real user's Praat WILL write UTF-16.
PRAAT="${PRAAT:-/home/claude/praat}"
PREFS="$SCRIPT_DIR/prefs"

# PRAAT 7 REFUSES FILE WRITES FROM A SCRIPT UNLESS TRUSTED, and both legs of
# this check write files. Measured 10 Aug 2026 on 7.0:
#
#   Error: The following potentially dangerous action was requested by the
#   script "..." but is not allowed without --FULL-TRUST:
#   save a line of text to the file "..."
#
# 6.6.30 does not know the flag, so it cannot simply be passed always. It is
# added only for a 7.x binary, detected from --version.
TRUST=""
if "$PRAAT" --version 2>&1 | grep -qE "Praat 7"; then
    TRUST="--FULL-TRUST"
fi
if [[ ! -x "$PRAAT" ]]; then
    echo "FAIL: pinned Praat not found at $PRAAT"
    echo "      Set PRAAT=... to override."
    exit 1
fi

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.txt "$OUT"/*.praat 2>/dev/null

CSV="$ROOT/evidence/csv/demo_3groups_input.csv"
if [[ ! -f "$CSV" ]]; then
    echo "FAIL: fixture not found: $CSV"
    exit 1
fi

# --- leg 1: record a session, capture its Info, emit the script -------------
cat > "$OUT/record_leg.praat" <<PRAAT
include $ROOT/plugin/stats/eml-core-utilities.praat
include $ROOT/plugin/stats/eml-core-descriptive.praat
include $ROOT/plugin/stats/eml-extract.praat
include $ROOT/plugin/stats/eml-output.praat
include $ROOT/plugin/stats/eml-inferential.praat
include $ROOT/plugin/stats/eml-result-writer.praat
include $ROOT/plugin/stats/eml-record.praat
include $ROOT/plugin/graphs/eml-graph-procedures.praat
include $ROOT/plugin/graphs/eml-annotation-procedures.praat
include $ROOT/plugin/stats/eml-analysis.praat

; The emitted file will include the plugin from wherever it was recorded.
; Point that at THIS tree rather than at an installed copy, so the round trip
; compares this build against itself and not against whatever is installed.
@emlRecordInit
emlRecordPluginRoot\$ = "$ROOT/plugin"

@emlRecordBegin: "$OUT"
emlRecordPluginRoot\$ = "$ROOT/plugin"
@emlRecordLoadPhrases: "$ROOT/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "demo_3groups_input.csv", 45, 4, "roundtrip"

Read Table from comma-separated file: "$CSV"
t = selected ("Table")

clearinfo
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
writeFileLine: "$OUT/leg1_info.txt", info\$ ()

@emlRecordFlush: "$OUT/emitted.praat"
@emlRecordDiscard
PRAAT

( cd "$ROOT" && timeout 300 "$PRAAT" $TRUST --pref-dir="$PREFS" --run "$OUT/record_leg.praat" >"$OUT/leg1_stderr.txt" 2>&1 )
if [[ ! -f "$OUT/emitted.praat" ]]; then
    echo "FAIL: leg 1 produced no emitted script"
    tail -20 "$OUT/leg1_stderr.txt"
    exit 1
fi

# --- leg 2: run the emitted script in a fresh process ------------------------
# The emitted file takes whatever Table is selected, so the driver reads the
# same CSV and hands it over — which is exactly the contract the file states
# in its own header.
cat > "$OUT/replay_leg.praat" <<PRAAT
Read Table from comma-separated file: "$CSV"
clearinfo
runScript: "$OUT/emitted.praat"
writeFileLine: "$OUT/leg2_info.txt", info\$ ()
PRAAT

( cd "$ROOT" && timeout 300 "$PRAAT" $TRUST --pref-dir="$PREFS" --run "$OUT/replay_leg.praat" >"$OUT/leg2_stderr.txt" 2>&1 )
if [[ ! -f "$OUT/leg2_info.txt" ]]; then
    echo "FAIL: the emitted script did not run"
    tail -20 "$OUT/leg2_stderr.txt"
    exit 1
fi

# --- normalise the one line that CANNOT match ---------------------------------
# The report header carries a wall-clock timestamp, so the two legs agree only
# when they happen to land in the same second. Caught by running this three
# times: exit 0, exit 1, exit 0. A check that passes by luck is worse than no
# check, because it reports agreement it did not establish.
#
# Only the timestamp is normalised, by an anchored pattern, so every other
# byte still has to match. If the pattern ever stops matching, the line stays
# as it is and the diff fails loudly rather than quietly comparing less.
# PRAAT CHOOSES THE ENCODING, AND THE CHOICE IS NOT STABLE ACROSS MACHINES.
# prefs5 carries "TextEncoding.outputEncoding: try ASCII, then UTF-16", so a
# report containing box rules is written UTF-16BE on any installation that has
# ever written a preferences file — and UTF-8 on one that has not. This
# harness saw both: five green runs on a sandbox with no prefs5, then a hard
# FAIL the moment one existed, because sed and grep are byte-oriented and the
# ASCII timestamp pattern cannot match UTF-16.
#
# That is Praat behaving correctly (it reads back what it writes) and the
# harness being wrong to assume bytes. Both captures are folded to UTF-8
# first, so the diff compares CONTENT and the encoding is Praat's business.
for leg in leg1 leg2; do
    if file "$OUT/${leg}_info.txt" | grep -q "UTF-16"; then
        iconv -f UTF-16 -t UTF-8 "$OUT/${leg}_info.txt" > "$OUT/${leg}_utf8.txt"
    else
        cp "$OUT/${leg}_info.txt" "$OUT/${leg}_utf8.txt"
    fi
done

DATE_RE='[A-Z][a-z][a-z] [A-Z][a-z][a-z] [ 0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]'
for leg in leg1 leg2; do
    sed -E "s/$DATE_RE/<TIMESTAMP>/" "$OUT/${leg}_utf8.txt" > "$OUT/${leg}_norm.txt"
done
if ! grep -q "<TIMESTAMP>" "$OUT/leg1_norm.txt"; then
    echo "roundtrip: FAIL — the timestamp pattern no longer matches."
    echo "           Fix the pattern rather than dropping the check."
    exit 1
fi

# --- diff --------------------------------------------------------------------
if diff -q "$OUT/leg1_norm.txt" "$OUT/leg2_norm.txt" >/dev/null; then
    echo "roundtrip: PASS — the recorded session and the emitted script"
    echo "           (Praat $("$PRAAT" --version 2>&1 | head -1))"
    echo "           produce byte-identical Info output"
    echo "           ($(wc -l < "$OUT/leg1_norm.txt") lines compared, timestamp normalised)"
    exit 0
fi

echo "roundtrip: FAIL — the log and the analysis disagree"
echo
diff "$OUT/leg1_norm.txt" "$OUT/leg2_norm.txt" | head -40
exit 1

#!/usr/bin/env bash
# ============================================================================
# roundtrip_graph.sh — §9's check, for a FIGURE rather than for a report
# ============================================================================
# Record a session that draws a figure. Emit the script. Run the emitted
# script in a fresh Praat process. Compare the two PNGs.
#
# WHY THE COMPARISON IS THE IMAGE AND NOT THE INFO TEXT. roundtrip.sh diffs
# Info output, which is the right evidence for an analysis: the numbers ARE
# the result. A drawing procedure's Info output is thin — a note or two — so
# diffing it would pass while the figure differed in every pixel. The
# artifact under test is the picture, so the picture is what is compared.
#
# It is compared BYTE FOR BYTE. A tolerance would have to be justified, and
# there is nothing to justify it with: the same procedure, on the same data,
# at the same viewport, on the same build, has no licence to differ at all.
# If that ever becomes too strict it will be because something genuinely
# non-deterministic entered the draw path, and that is worth failing over.
#
# Run from anywhere:  bash harness/record/roundtrip_graph.sh
# Exit 0 = the emitted script reproduces the figure.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$SCRIPT_DIR/graph_out"
PREFS="$SCRIPT_DIR/prefs"

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.png "$OUT"/*.praat "$OUT"/*.txt 2>/dev/null

# The fixture is built in-script rather than read from evidence/, and it is
# DETERMINISTIC. 22 of the 39 stress cases call randomGauss with no seed, so
# two runs of the same case produce different figures — see §14 of
# audit/GRAPHING_PUSH_REMAINING.md. A byte-for-byte image comparison cannot
# be built on that, and seeding here is cheaper than seeding those.
read -r -d '' FIXTURE <<'PRAATFIX'
Create Table with column names: "vt", 0, "grp val"
rngState = 20260810
row = 0
for g from 1 to 4
    for k from 1 to 25
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 200 + g * 8 + (rngState / 2147483648 - 0.5) * 34
    endfor
endfor
PRAATFIX

# --- leg 1: draw with a recording running, save the figure, emit -------------
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
include $ROOT/plugin/graphs/eml-draw-procedures.praat

@emlInitializeDrawingDefaults
@emlRecordInit
emlRecordPluginRoot\$ = "$ROOT/plugin"
@emlRecordBegin: "$OUT"
emlRecordPluginRoot\$ = "$ROOT/plugin"
@emlRecordLoadPhrases: "$ROOT/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "vt", 100, 2, "graph roundtrip"

$FIXTURE
table = selected ("Table")

Erase all
@emlDrawViolinPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg1.png"

@emlRecordFlush: "$OUT/emitted.praat"
@emlRecordDiscard
PRAAT

# A HEADER LINE FIRST, so the transcript is never a zero-byte file. A leg
# that produces no output is the normal case here -- the draw path is quiet
# when nothing goes wrong -- and an empty file is indistinguishable from a
# missing one to a reader, cannot be uploaded through GitHub's web form at
# all, and reads in a diff as though the capture had been removed.
echo "# roundtrip_graph leg 1 -- record: transcript follows" \
    > "$OUT/leg1_stderr.txt"
# HOME IS PINNED ABOVE THE REPOSITORY, for the reason replay.sh records at
# length. Since the 15 August 2026 ruling the renderer rewrites the include
# root home-relative and its header states that as a fact -- there is no
# second arm any more. Under the ambient HOME (/root in the sandbox) the
# working tree is not under home, the rewrite cannot fire, and this rig would
# be the one place in the project emitting a file whose header and paths
# disagree. Pointing HOME at the repository's parent makes the tree genuinely
# home-relative, so the committed artefact is one a user could actually run.
# The pref dir is pinned separately, so nothing else moves.
( cd "$ROOT" && HOME="$(dirname "$ROOT")" timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run "$OUT/record_leg.praat" >>"$OUT/leg1_stderr.txt" 2>&1 )
if [[ ! -f "$OUT/leg1.png" || ! -f "$OUT/emitted.praat" ]]; then
    echo "FAIL: leg 1 produced no figure or no emitted script"
    tail -20 "$OUT/leg1_stderr.txt"
    exit 1
fi

# --- leg 2: replay the emitted script, save its figure -----------------------
# The emitted file takes whatever Table is selected and carries its own
# include block, so the driver builds the same fixture and hands it over.
# THE EMITTED FILE IS INCLUDED, NOT runScript:-ED, and finding that out is
# worth more than the check it enables.
#
# `runScript:` opens a fresh scope. Two consequences, both measured here:
#   1. Procedures defined inside the emitted file do not come back out, so
#      @emlAssertFullViewport was not callable in the driver.
#   2. Worse, the DRAWN-EXTENT TRACKER is scoped too. The emitted file drew
#      the figure and updated its own emlDrawnMinX/MaxX; the driver's copies
#      stayed at their initial values, and saving from the driver died with
#      "The left and right edges of the viewport cannot be equal."
#
# So a picture drawn by a runScript:-ed file cannot be saved by its caller at
# the extent it was actually drawn. `include` is a textual paste into ONE
# scope, which is how a user running the emitted file in Praat experiences it
# anyway -- there, the emitted file IS the top-level script. Including it
# here reproduces that faithfully; runScript: would have been testing a mode
# no user is in.
cat > "$OUT/replay_leg.praat" <<PRAAT
$FIXTURE
table = selected ("Table")
Erase all
include $OUT/emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg2.png"
PRAAT

echo "# roundtrip_graph leg 2 -- replay: transcript follows" \
    > "$OUT/leg2_stderr.txt"
( cd "$ROOT" && HOME="$(dirname "$ROOT")" timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run "$OUT/replay_leg.praat" >>"$OUT/leg2_stderr.txt" 2>&1 )
if [[ ! -f "$OUT/leg2.png" ]]; then
    echo "FAIL: the emitted script drew no figure"
    tail -20 "$OUT/leg2_stderr.txt"
    exit 1
fi

# --- compare -----------------------------------------------------------------
s1=$(stat -c%s "$OUT/leg1.png")
s2=$(stat -c%s "$OUT/leg2.png")
if cmp -s "$OUT/leg1.png" "$OUT/leg2.png"; then
    echo "roundtrip_graph: PASS — the emitted script reproduces the figure"
    echo "                 (Praat $("$PRAAT" --version 2>&1 | head -1))"
    echo "                 byte-identical PNG, $s1 bytes"
    exit 0
fi

echo "roundtrip_graph: FAIL — the emitted script drew a DIFFERENT figure"
echo "                 leg1 $s1 bytes, leg2 $s2 bytes"
if command -v compare >/dev/null 2>&1; then
    d=$(compare -metric AE "$OUT/leg1.png" "$OUT/leg2.png" null: 2>&1 || true)
    echo "                 differing pixels: $d"
fi
exit 1

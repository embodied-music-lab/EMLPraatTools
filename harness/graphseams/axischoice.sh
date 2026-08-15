#!/usr/bin/env bash
# ============================================================================
# graphseams/axischoice.sh — does a recorded figure carry the user's axis
#                            CHOICE, or the axis that one dataset happened to
#                            resolve to?
# ============================================================================
# WHAT THIS RIG IS FOR. RULING 10, 15 August 2026. A recorded draw step is
# emitted with the RESOLVED y-axis baked into the call as numeric literals:
#
#     @emlDrawViolinPlot: data, ..., groupCol$, valueCol$, 1.554964, 4.416270
#     # Axis resolved to 1.5550 .. 4.4163 over 2 groups.
#
# and it is emitted that way EVEN WHEN THE USER LEFT THE AXIS ON AUTO. The
# recorded script is the plugin's retargeting surface — its whole editable
# header block exists so that one edit re-points the workflow at other data —
# so the statistics recompute honestly on the new table while the FRAME stays
# frozen at the original table's extent. Data below the frozen floor or above
# the frozen ceiling is clipped off the page; data far inside it swims in an
# empty box. Neither says anything went wrong.
#
# THE RULING NAMES THE PROOF, and it is two legs, not one:
#
#   SAME DATA      a byte-identical figure must still hold. A "fix" that
#                  makes the frame follow the data is worthless if it also
#                  makes the frame WANDER on data that did not change. This
#                  leg is the one that fails if auto is emitted as auto but
#                  auto and the recorded literals were never the same number
#                  in the first place.
#
#   RETARGETED     the figure must rescale. This is the leg the defect fails.
#                  It is measured as a NUMBER, not as a picture: the axis the
#                  replay resolves, read back out of the draw procedure that
#                  drew it, against the axis a NATIVE auto draw of the same
#                  retargeted table resolves. Equal to the ORIGINAL axis =
#                  frozen. Equal to the native one = rescaled.
#
# WHY THE FOURTH LEG (native retarget) IS NOT OPTIONAL. Without it the
# retarget leg can only say "the axis did not change", and a check written on
# that alone passes for the wrong reason the moment someone emits a DIFFERENT
# constant. The native draw is the answer key: it is what the user would have
# got by drawing the retargeted table through the form with the axis on auto,
# which is exactly what they asked the recorded script to be.
#
# AND WHY THE PIXEL COMPARISON IS KEPT ANYWAY. The axis numbers are the
# separator; the PNGs are the evidence a human can look at. A frozen frame is
# not a subtle picture — leg 3 and leg 4 differ in essentially every pixel of
# the data area — and the ruling asked for a figure.
#
# NO DISPLAY. Every leg is `praat --run` with no X server at all: the
# recorder hooks fire from inside the draw procedures, not from the form, so
# nothing here needs a dialog. harness/graphseams/run.sh owns :94; this rig
# takes no display and therefore cannot collide with one.
#
# THE FIXTURES ARE SEEDED. 22 of the 39 stress cases call randomGauss with no
# seed, so two runs of the same case draw different figures; a byte-for-byte
# image comparison cannot be built on that. Both tables here come from the
# same linear congruential generator with a written-down seed, and the
# retargeted one is the original SHIFTED AND SCALED CLEAR OF IT — 200..270
# becomes 1100..1300 — so a frozen frame clips every point rather than
# merely shifting them, and the two states cannot be confused.
#
# Run from anywhere:  bash harness/graphseams/axischoice.sh
# Exit 0 = every leg ran and AXIS.tsv was written. It is NOT a pass/fail rig:
# the numbers go to validate/v61_graphs_seams.R, which decides.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$SCRIPT_DIR/axis_out"
PREFS="$SCRIPT_DIR/prefs_axis"

# A SOURCE OVERRIDE, for the break tests. Every check in v61 that reads this
# rig's output has to be shown RED against a deliberately broken copy of the
# tree, and a rig that hardcodes $EML_ROOT for its includes cannot be pointed
# at one. $EML_AXIS_SRC replaces the plugin root the legs include from;
# $EML_AXIS_OUT moves the artefacts so a break run does not overwrite the
# real ones.
SRC="${EML_AXIS_SRC:-$ROOT/plugin}"
OUT="${EML_AXIS_OUT:-$OUT}"

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.png "$OUT"/*.praat "$OUT"/*.txt "$OUT"/*.tsv 2>/dev/null

TSV="$OUT/AXIS.tsv"
: > "$TSV"
kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

kv praat_version "$("$PRAAT" --version 2>&1 | head -1)"
kv plugin_root "$SRC"

# ---------------------------------------------------------------------------
# The two tables. Same shape, same column names, same row count, same
# generator — only the values are moved, because the point of the rig is that
# NOTHING about the workflow changed except the numbers it is pointed at.
# ---------------------------------------------------------------------------
read -r -d '' FIXTURE_A <<'PRAATFIX'
Create Table with column names: "vt", 0, "grp val"
rngState = 20260815
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

read -r -d '' FIXTURE_B <<'PRAATFIX'
Create Table with column names: "vt", 0, "grp val"
rngState = 20260815
row = 0
for g from 1 to 4
    for k from 1 to 25
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 1100 + g * 24 + (rngState / 2147483648 - 0.5) * 102
    endfor
endfor
PRAATFIX

INCLUDES="include $SRC/stats/eml-core-utilities.praat
include $SRC/stats/eml-core-descriptive.praat
include $SRC/stats/eml-extract.praat
include $SRC/stats/eml-output.praat
include $SRC/stats/eml-inferential.praat
include $SRC/stats/eml-result-writer.praat
include $SRC/stats/eml-record.praat
include $SRC/graphs/eml-graph-procedures.praat
include $SRC/graphs/eml-annotation-procedures.praat
include $SRC/graphs/eml-draw-procedures.praat"

runleg () {   # runleg <name> <script>
    local name="$1" script="$2"
    echo "# axischoice $name: transcript follows" > "$OUT/${name}.txt"
    ( cd "$ROOT" && HOME="$(dirname "$ROOT")" timeout 300 "$PRAAT" $PRAAT_TRUST \
        --pref-dir="$PREFS" --run "$script" >>"$OUT/${name}.txt" 2>&1 )
    return $?
}

# A VALUE READ OUT OF A TRANSCRIPT, not out of a filename or a guess.
# `grep -o` on an anchored key, last match wins, empty string if absent —
# because an absent key must reach the TSV as an empty field and fail the
# validator's numeric guard, not silently become the previous leg's number.
pick () {   # pick <file> <key>
    sed -n "s/^$2=\\(.*\\)$/\\1/p" "$1" | tail -1
}

# ---------------------------------------------------------------------------
# LEG 1 — RECORD. The axis is left on AUTO, which in this plugin is the pair
# (0, 0): the dialog says so in as many words ("📐 Y-axis range (both 0 =
# auto)") and eml-graphs-form.praat passes the pair straight through to every
# draw procedure. This leg is the user leaving the field alone.
# ---------------------------------------------------------------------------
cat > "$OUT/leg1_record.praat" <<PRAAT
$INCLUDES

@emlInitDrawingDefaults
@emlRecordInit
emlRecordPluginRoot\$ = "$SRC"
@emlRecordBegin: "$OUT"
emlRecordPluginRoot\$ = "$SRC"
@emlRecordLoadPhrases: "$SRC/data/eml-record-phrases.csv"
@emlRecordHeader: "vt", 100, 2, "axis choice"

$FIXTURE_A
table = selected ("Table")

Erase all
@emlDrawViolinPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg1.png"

appendInfoLine: "AXISLO=", fixed\$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawViolinPlot.axisYMax, 6)
selectObject: table
dLo = Get minimum: "val"
dHi = Get maximum: "val"
appendInfoLine: "DATALO=", fixed\$ (dLo, 6)
appendInfoLine: "DATAHI=", fixed\$ (dHi, 6)

@emlRecordFlush: "$OUT/auto_emitted.praat"
@emlRecordDiscard
PRAAT
runleg leg1 "$OUT/leg1_record.praat"

if [[ ! -f "$OUT/auto_emitted.praat" || ! -f "$OUT/leg1.png" ]]; then
    echo "axischoice: FAIL — leg 1 emitted no script or drew no figure"
    tail -20 "$OUT/leg1.txt"; exit 1
fi
kv leg1_axis_lo "$(pick "$OUT/leg1.txt" AXISLO)"
kv leg1_axis_hi "$(pick "$OUT/leg1.txt" AXISHI)"
kv leg1_data_lo "$(pick "$OUT/leg1.txt" DATALO)"
kv leg1_data_hi "$(pick "$OUT/leg1.txt" DATAHI)"
kv leg1_png_bytes "$(stat -c%s "$OUT/leg1.png")"

# WHAT THE EMITTED CALL SAYS ABOUT ITS AXIS. Three separate statements, kept
# apart on purpose, because "the file mentions auto somewhere" is not the
# claim:
#   auto_call_line     the draw call, verbatim, for a human reading the TSV
#   auto_call_literals how many bare decimal literals the call's last two
#                      arguments are — 2 = the frozen frame, 0 = auto or a
#                      header variable
#   auto_hdr_axis      whether the editable header block declares the axis
DRAWLINE=$(grep -m1 '^@emlDrawViolinPlot:' "$OUT/auto_emitted.praat")
kv auto_call_line "$DRAWLINE"
# The tail after the last quoted argument: everything the call passes as bare
# numbers. `0, 0` is the auto sentinel and is NOT a resolved literal, so the
# count is of numbers with a decimal point in them.
TAIL=${DRAWLINE##*\"}
kv auto_call_literals "$(printf '%s' "$TAIL" | grep -o '[0-9]\+\.[0-9]\+' | wc -l)"
kv auto_call_tail "$TAIL"
kv auto_hdr_axis "$(grep -c '^axisY\(Min\|Max\)\b *=' "$OUT/auto_emitted.praat")"
kv auto_resolved_comment "$(grep -c '^# Axis resolved to' "$OUT/auto_emitted.praat")"

# ---------------------------------------------------------------------------
# LEG 2 — SAME DATA. The emitted script, replayed on the table it was
# recorded from. The figure must be byte-identical: this is the leg that
# catches a fix which makes the frame follow the data by making it follow
# something else as well.
#
# The emitted file is INCLUDED, not runScript:-ed. runScript: opens a fresh
# scope, so the drawn-extent tracker the save reads stays at its initial
# value in the caller and `Save as PNG` dies on an empty viewport.
# harness/record/roundtrip_graph.sh found that and its header records it; the
# include is also what a user actually does with the file.
# ---------------------------------------------------------------------------
cat > "$OUT/leg2_same.praat" <<PRAAT
$FIXTURE_A
table = selected ("Table")
Erase all
include $OUT/auto_emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg2.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawViolinPlot.axisYMax, 6)
PRAAT
runleg leg2 "$OUT/leg2_same.praat"

if [[ -f "$OUT/leg2.png" ]]; then
    kv leg2_png_bytes "$(stat -c%s "$OUT/leg2.png")"
    if cmp -s "$OUT/leg1.png" "$OUT/leg2.png"; then
        kv same_data_identical 1
    else
        kv same_data_identical 0
    fi
else
    kv leg2_png_bytes 0
    kv same_data_identical 0
fi
kv leg2_axis_lo "$(pick "$OUT/leg2.txt" AXISLO)"
kv leg2_axis_hi "$(pick "$OUT/leg2.txt" AXISHI)"

# ---------------------------------------------------------------------------
# LEG 3 — RETARGETED. The same emitted script, run with the retargeted table
# selected. Nothing about the script changes; this is the one edit the header
# block exists to make.
# ---------------------------------------------------------------------------
cat > "$OUT/leg3_retarget.praat" <<PRAAT
$FIXTURE_B
table = selected ("Table")
Erase all
include $OUT/auto_emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg3.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawViolinPlot.axisYMax, 6)
selectObject: table
dLo = Get minimum: "val"
dHi = Get maximum: "val"
appendInfoLine: "DATALO=", fixed\$ (dLo, 6)
appendInfoLine: "DATAHI=", fixed\$ (dHi, 6)
PRAAT
runleg leg3 "$OUT/leg3_retarget.praat"
kv leg3_axis_lo "$(pick "$OUT/leg3.txt" AXISLO)"
kv leg3_axis_hi "$(pick "$OUT/leg3.txt" AXISHI)"
kv leg3_data_lo "$(pick "$OUT/leg3.txt" DATALO)"
kv leg3_data_hi "$(pick "$OUT/leg3.txt" DATAHI)"
[[ -f "$OUT/leg3.png" ]] && kv leg3_png_bytes "$(stat -c%s "$OUT/leg3.png")" \
                         || kv leg3_png_bytes 0

# ---------------------------------------------------------------------------
# LEG 4 — THE ANSWER KEY. The retargeted table drawn NATIVELY with the axis
# on auto: the figure the user would have got from the form. Leg 3 must equal
# this, not merely differ from leg 1.
# ---------------------------------------------------------------------------
cat > "$OUT/leg4_native.praat" <<PRAAT
$INCLUDES

@emlInitDrawingDefaults

$FIXTURE_B
table = selected ("Table")

Erase all
@emlDrawViolinPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg4.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawViolinPlot.axisYMax, 6)
PRAAT
runleg leg4 "$OUT/leg4_native.praat"
kv leg4_axis_lo "$(pick "$OUT/leg4.txt" AXISLO)"
kv leg4_axis_hi "$(pick "$OUT/leg4.txt" AXISHI)"
[[ -f "$OUT/leg4.png" ]] && kv leg4_png_bytes "$(stat -c%s "$OUT/leg4.png")" \
                         || kv leg4_png_bytes 0

if [[ -f "$OUT/leg3.png" && -f "$OUT/leg4.png" ]] && \
   cmp -s "$OUT/leg3.png" "$OUT/leg4.png"; then
    kv retarget_matches_native 1
else
    kv retarget_matches_native 0
fi

# ---------------------------------------------------------------------------
# LEG 5 — THE EXPLICIT RANGE. The other half of ruling 10: a user who TYPED a
# range gets it back as a variable in the editable header block, referenced by
# the call, so the one place they edit for new data is still the top block.
# The range chosen is deliberately WIDER than the data on both sides, so that
# "the figure used it" is visible in the axis readback and cannot be confused
# with an auto resolution that happened to land nearby.
# ---------------------------------------------------------------------------
cat > "$OUT/leg5_explicit.praat" <<PRAAT
$INCLUDES

@emlInitDrawingDefaults
@emlRecordInit
emlRecordPluginRoot\$ = "$SRC"
@emlRecordBegin: "$OUT"
emlRecordPluginRoot\$ = "$SRC"
@emlRecordLoadPhrases: "$SRC/data/eml-record-phrases.csv"
@emlRecordHeader: "vt", 100, 2, "axis choice explicit"

$FIXTURE_A
table = selected ("Table")

Erase all
@emlDrawViolinPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 150, 300
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg5.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawViolinPlot.axisYMax, 6)

@emlRecordFlush: "$OUT/expl_emitted.praat"
@emlRecordDiscard
PRAAT
runleg leg5 "$OUT/leg5_explicit.praat"
kv leg5_axis_lo "$(pick "$OUT/leg5.txt" AXISLO)"
kv leg5_axis_hi "$(pick "$OUT/leg5.txt" AXISHI)"

if [[ -f "$OUT/expl_emitted.praat" ]]; then
    EDRAW=$(grep -m1 '^@emlDrawViolinPlot:' "$OUT/expl_emitted.praat")
    kv expl_call_line "$EDRAW"
    ETAIL=${EDRAW##*\"}
    kv expl_call_tail "$ETAIL"
    # THE HEADER DECLARATION, and the call REFERENCING it. Either alone is
    # the defect wearing the fix's clothes: a header variable nothing reads
    # is a dead channel (the same D4 shape v61 already pins), and a call
    # naming a variable nobody declares does not parse.
    kv expl_hdr_min "$(grep -c '^axisYMin *= *150\b' "$OUT/expl_emitted.praat")"
    kv expl_hdr_max "$(grep -c '^axisYMax *= *300\b' "$OUT/expl_emitted.praat")"
    kv expl_call_refs_vars "$(printf '%s' "$ETAIL" \
        | grep -c 'axisYMin.*axisYMax')"
    # And the header variables must be inside the EDITABLE BLOCK, not merely
    # somewhere in the file: the block is the contract ruling 9 put the column
    # names into, and a declaration below the first step is not in it.
    HDRLINE=$(grep -n '^axisYMin *=' "$OUT/expl_emitted.praat" | head -1 | cut -d: -f1)
    STEPLINE=$(grep -n '^# --- Step 1' "$OUT/expl_emitted.praat" | head -1 | cut -d: -f1)
    if [[ -n "$HDRLINE" && -n "$STEPLINE" && "$HDRLINE" -lt "$STEPLINE" ]]; then
        kv expl_hdr_in_block 1
    else
        kv expl_hdr_in_block 0
    fi
else
    kv expl_call_line ""
    kv expl_hdr_min 0
    kv expl_hdr_max 0
    kv expl_call_refs_vars 0
    kv expl_hdr_in_block 0
fi

# ---------------------------------------------------------------------------
# LEGS 6-8 — THE POSITIVE CONTROL, and it is the most useful thing this rig
# found.
#
# A retarget leg on its own can only ever say "the axis did not move", and a
# check written on that alone is a check that cannot go green for the right
# reason: it would report the same number whether the emitter is incapable of
# emitting auto or merely was not asked to. So the same three legs are run
# again on a BOX PLOT, whose recorder is a plain @emlRecordDrawStep and builds
# its call from `string$ (.vMin)` — the REQUEST — rather than from the
# resolved extent.
#
# Measured 15 Aug 2026: the box plot, the bar chart, the scatter and the
# histogram all emit `0, 0` for a user's auto and all rescale on retargeted
# data. The violin is the only draw recorder in the plugin that bakes the
# resolved axis into its call, and it does so by an explicit decision written
# into eml-draw-procedures.praat above the line that does it. So ruling 10(a)
# is not a policy the plugin holds and has to be talked out of — it is ONE
# procedure that went its own way, and these legs are what says so.
# ---------------------------------------------------------------------------
cat > "$OUT/leg6_boxrecord.praat" <<PRAAT
$INCLUDES

@emlInitDrawingDefaults
@emlRecordInit
emlRecordPluginRoot\$ = "$SRC"
@emlRecordBegin: "$OUT"
emlRecordPluginRoot\$ = "$SRC"
@emlRecordLoadPhrases: "$SRC/data/eml-record-phrases.csv"
@emlRecordHeader: "vt", 100, 2, "axis choice box"

$FIXTURE_A
table = selected ("Table")

Erase all
@emlDrawBoxPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg6.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawBoxPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawBoxPlot.axisYMax, 6)

@emlRecordFlush: "$OUT/box_emitted.praat"
@emlRecordDiscard
PRAAT
runleg leg6 "$OUT/leg6_boxrecord.praat"
kv leg6_axis_lo "$(pick "$OUT/leg6.txt" AXISLO)"
kv leg6_axis_hi "$(pick "$OUT/leg6.txt" AXISHI)"
if [[ -f "$OUT/box_emitted.praat" ]]; then
    BDRAW=$(grep -m1 '^@emlDrawBoxPlot:' "$OUT/box_emitted.praat")
    kv box_call_line "$BDRAW"
    BTAIL=${BDRAW##*\"}
    kv box_call_literals "$(printf '%s' "$BTAIL" | grep -o '[0-9]\+\.[0-9]\+' | wc -l)"
else
    kv box_call_line ""
    kv box_call_literals -1
fi

cat > "$OUT/leg7_boxretarget.praat" <<PRAAT
$FIXTURE_B
table = selected ("Table")
Erase all
include $OUT/box_emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg7.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawBoxPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawBoxPlot.axisYMax, 6)
PRAAT
runleg leg7 "$OUT/leg7_boxretarget.praat"
kv leg7_axis_lo "$(pick "$OUT/leg7.txt" AXISLO)"
kv leg7_axis_hi "$(pick "$OUT/leg7.txt" AXISHI)"

cat > "$OUT/leg8_boxnative.praat" <<PRAAT
$INCLUDES

@emlInitDrawingDefaults

$FIXTURE_B
table = selected ("Table")

Erase all
@emlDrawBoxPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/leg8.png"
appendInfoLine: "AXISLO=", fixed\$ (emlDrawBoxPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed\$ (emlDrawBoxPlot.axisYMax, 6)
PRAAT
runleg leg8 "$OUT/leg8_boxnative.praat"
kv leg8_axis_lo "$(pick "$OUT/leg8.txt" AXISLO)"
kv leg8_axis_hi "$(pick "$OUT/leg8.txt" AXISHI)"

if [[ -f "$OUT/leg7.png" && -f "$OUT/leg8.png" ]] && \
   cmp -s "$OUT/leg7.png" "$OUT/leg8.png"; then
    kv box_retarget_matches_native 1
else
    kv box_retarget_matches_native 0
fi

echo "axischoice: wrote $TSV"
sed 's/^/  /' "$TSV"
exit 0

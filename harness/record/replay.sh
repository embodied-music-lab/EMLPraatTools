#!/usr/bin/env bash
# ============================================================================
# replay.sh — the recorder's REPLAY contract, which is not the same as its
#             emission contract
# ============================================================================
# WHY THIS LIVES IN harness/record/ RATHER THAN IN A NEW DIRECTORY. This is
# the same journey roundtrip.sh and roundtrip_graph.sh already make — record,
# emit, replay, compare — with the same _env.sh, the same prefs isolation and
# the same "the artefact is the picture" rule. What it adds is the part those
# two cannot reach, because both drive a BEGINNER figure and a bare analysis:
#
#   * roundtrip_graph.sh draws a violin with no annotation and no jitter, so
#     the advanced settings are outside its journey by construction. It went
#     green throughout the period the audit's advanced figure was losing its
#     bracket and its points.
#   * neither of them records a SAVE step, because a save step can only be
#     recorded from inside @emlSavePanel — which is a dialog.
#
# Six legs, one artefact directory, one TSV.
#
#   ADV      record an advanced-mode annotated, jittered violin; replay it;
#            compare the replay against BOTH the original AND a deliberately
#            un-advanced reference. Which of the two it matches is the whole
#            result — see the note on the seed below.
#   SAVE     replay a recorded save step and count the timestamps in the names
#            it writes. One is correct; two is the accretion defect.
#   META     drive several script scopes in ONE Praat process, remove the
#            record tables the way a user can, and read the provenance the
#            next session emits.
#   FOLDER   replay a save onto a folder two levels deep that does not exist.
#   RETARGET edit the emitted script's header block -- and NOTHING else -- to
#            point at a same-shape table whose columns are named differently,
#            then run it. This is the only leg that can tell a block which
#            GATHERS the column names from one the steps actually READ, and
#            the difference between those two is author ruling 9 in full.
#   LEGEND   record a figure whose legend needs y-axis room -- one press of
#            Draw through the shipped @emlGraphsDrawWithLegendRoom, which
#            draws it, measures the legend, and draws it again on a widened
#            axis with the first pass discarded. One emitted step, and the
#            block's resolved-range note has to name the axis the figure was
#            FINALLY drawn on: the leg edits the block to the two numbers the
#            note itself quotes and the resulting figure is byte-identical to
#            the one the recording drew. Author ruling B, change order 8;
#            read by validate/v75. It is also the only leg that INCLUDES
#            eml-graphs-form.praat rather than writing the form's state out
#            by hand -- see the note above the leg for why that is now
#            possible and why the ADV leg's remark to the contrary is stale.
#
# THE SEED IS WHAT MAKES THE FIGURE COMPARABLE AT ALL, and finding that out
# changed the design of this file. @emlDrawJitteredPoints calls randomUniform
# for every point's x-offset, so two draws of the same jittered figure land
# their points in different places no matter how correct both are — the
# figures are not the same picture and no comparison of them means anything.
# Praat can be told to seed its generator —
# random_initializeWithSeedUnsafelyButPredictably, measured working on 6.6.30
# — so each leg seeds identically before it draws and the two pictures become
# the same picture.
#
# WHAT REMAINS AFTER THE SEED IS NOT ZERO, AND IT IS NOT NOISE EITHER. A
# correct replay still differs from the original in forty pixels, by at most 4
# of 255: the recorder emits a resolved axis to six decimal places, so the
# replayed draw maps world coordinates through an axis that differs in the
# last bits and anti-aliases each jitter mark's edge fractionally
# differently — one pixel per point, and there are forty points. So `cmp`,
# which roundtrip_graph.sh rightly uses for a beginner figure, would fail here
# on a PERFECT replay. The comparison is pngdiff.py's count of pixels
# differing by more than 32, which is 0 for a faithful replay and 2740 for one
# that dropped the bracket and the points. The threshold sits in that gap, not
# on a line chosen to make a case pass.
#
# THE PLUGIN UNDER TEST IS OVERRIDABLE. $EML_RECORD_PLUGIN replaces the plugin
# tree, so a break test runs against a mutated copy without touching the
# working tree. $EML_REPLAY_DIR moves the artefacts for the same reason.
#
# Run from anywhere:  bash harness/record/replay.sh
# Exit 0 = every leg produced its artefacts. The VERDICT is v58's, not this
# script's: it writes what it measured and does not decide.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
PLUG="${EML_RECORD_PLUGIN:-$ROOT/plugin}"
OUT="${EML_REPLAY_DIR:-$SCRIPT_DIR/replay_out}"
PREFS="$SCRIPT_DIR/replay_prefs"

mkdir -p "$OUT" "$PREFS"
rm -rf "$OUT"/*.png "$OUT"/*.praat "$OUT"/*.log "$OUT"/*.tsv "$OUT"/*.txt \
       "$OUT"/saved "$OUT"/deep 2>/dev/null
mkdir -p "$OUT/saved"

TSV="$OUT/REPLAY.tsv"
: > "$TSV"
kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

kv praat_version "$("$PRAAT" --version 2>&1 | head -1)"
kv plugin_root "$PLUG"

# ---------------------------------------------------------------------------
# THE INCLUDE BLOCK, and the fixture, shared by every leg.
# ---------------------------------------------------------------------------
# DETERMINISTIC DATA, by the same argument roundtrip_graph.sh makes: a
# byte-for-byte image comparison cannot be built on randomGauss. The LCG below
# is the one that harness already uses.
read -r -d '' INCLUDES <<PRAATINC
include $PLUG/stats/eml-core-utilities.praat
include $PLUG/stats/eml-core-descriptive.praat
include $PLUG/stats/eml-extract.praat
include $PLUG/stats/eml-output.praat
include $PLUG/stats/eml-inferential.praat
include $PLUG/stats/eml-result-writer.praat
include $PLUG/stats/eml-record.praat
include $PLUG/graphs/eml-graph-procedures.praat
include $PLUG/graphs/eml-annotation-procedures.praat
include $PLUG/graphs/eml-draw-procedures.praat
include $PLUG/stats/eml-analysis.praat
PRAATINC

read -r -d '' FIXTURE <<'PRAATFIX'
Create Table with column names: "vt", 0, "grp val"
rngState = 20260814
row = 0
for g from 1 to 2
    for k from 1 to 20
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 1 + g * 1.2 + (rngState / 2147483648 - 0.5) * 1.4
    endfor
endfor
PRAATFIX

# THE ADVANCED STATE, WRITTEN OUT AS THE FORM WRITES IT. This leg drives
# @emlDrawViolinPlot directly rather than any form procedure, so the globals a
# form sets around a draw are set here by hand.
#
# (This note used to say eml-graphs-form.praat "is not includable — including
# it runs the form". That is false and was corrected on 16 August 2026: the
# file's top-level code is array initialisation only, there is no `form:` or
# `beginPause:` at top level, and @emlGraphsWorkflow is never called from
# inside it, so an include gets every procedure and no dialog. harness/formaxis
# has stood on that since 16 August and the LEGEND leg below does too. What is
# true of an EMITTED file is different and unchanged: a recorded script must
# not include the form, because the form's procedures are not what it replays.) Every one of them is copied from the
# form's own dispatch block, and the point of the leg is precisely that these
# are NOT arguments to the draw procedure: they are the thing the recorder was
# failing to carry.
read -r -d '' ADVSTATE <<'PRAATADV'
annotate = 1
annotAlpha = 0.05
annotStyle$ = "p-value"
annotShowNS = 0
annotShowEffect = 1
annotTestType$ = "parametric"
annotLayoutMode = 1
annotCorrectionMethod$ = "holm"
graph_type = 7
prev_violinShowJitter = 1
@emlClearAnnotations
@emlSetAdaptiveTheme: 6, 4
@emlBridgeGroupComparison: table, "val", "grp", annotAlpha, annotStyle$,
... annotShowNS, annotShowEffect, annotTestType$, annotLayoutMode
selectObject: table
dMax = Get maximum: "val"
dMin = Get minimum: "val"
dataYMax_forAnnotation = dMax
@emlComputeAnnotationHeadroom: dMax - dMin, emlSetAdaptiveTheme.annotSize, 0, ""
valueMin = dMin
valueMax = dMax + emlComputeAnnotationHeadroom.headroom
PRAATADV

# The graphs form's post-dispatch annotation render, inlined. This is the code
# the emitted script has to reproduce, and it is here so the ORIGINAL figure is
# the one a user actually gets rather than one this harness invented.
read -r -d '' POSTDISPATCH <<'PRAATPOST'
annotXMin = emlDrawViolinPlot.axisXMin
annotXMax = emlDrawViolinPlot.axisXMax
annotYMin = emlDrawViolinPlot.axisYMin
annotYMax = emlDrawViolinPlot.axisYMax
if annotBracketN > 0 or (annotTextN > 0 and annotMatrixN = 0)
    annotYRange = annotYMax - annotYMin
    if annotTextN > 0
        annotBlockN = annotBlockN + 1
        annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
        annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
        annotTextN = 0
    endif
    if annotBracketN > 0
        @emlDrawAnnotations: annotXMin, annotXMax, dataYMax_forAnnotation,
        ... annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize,
        ... annotYMin, annotYMax
    endif
    if annotBlockN > 0
        if annotBracketN > 0
            omnibusCorner$ = "bottom-right"
        else
            omnibusCorner$ = "top-right"
        endif
        @emlDrawAnnotationBlock: omnibusCorner$, annotXMin, annotXMax,
        ... annotYMin, annotYMax, emlSetAdaptiveTheme.annotSize
    endif
endif
PRAATPOST

# HOME IS PINNED ABOVE THE REPOSITORY, and that is not cosmetic.
#
# These legs override emlRecordPluginRoot$ to the working tree, so the emitted
# script includes the code under test rather than an installed copy. Since the
# 15 Aug 2026 ruling the renderer rewrites whatever root it is handed into a
# home-relative one, and refuses to emit anything else -- the emitted file is a
# user artefact and must be portable, full stop.
#
# With the ambient HOME (/root under the sandbox) the working tree is not under
# home, the rewrite cannot fire, and this rig would be the one place in the
# project producing an emission whose header and paths disagree. Pointing HOME
# at the repository's parent makes $PLUG genuinely home-relative -- ~/<repo>/
# plugin -- so the emitted script both RUNS here and carries the tilde the
# ruling requires. The pref dir is pinned separately, so nothing else moves.
run_praat () {   # run_praat <script> <log>
    ( cd "$ROOT" && HOME="$(dirname "$ROOT")" timeout 300 "$PRAAT" $PRAAT_TRUST \
        --pref-dir="$PREFS" --run "$1" >>"$2" 2>&1 )
}

# ===========================================================================
# LEG ADV — the advanced figure, recorded, replayed, and compared to two
#           references
# ===========================================================================
cat > "$OUT/adv_record.praat" <<PRAAT
$INCLUDES
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot\$ = "$PLUG"
@emlRecordLoadPhrases: "$PLUG/data/eml-record-phrases.csv"
@emlRecordHeader: "Table vt", 40, 2, "14 August 2026, 00:00:00"

$FIXTURE
table = selected ("Table")

$ADVSTATE

Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
@emlDrawViolinPlot: table, "advanced violin", "Cohort", "val", 6, 4,
... "color", 1, "grp", "val", valueMin, valueMax
$POSTDISPATCH
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/ADV_ORIG.png"

@emlRecordFlush: "$OUT/adv_emitted.praat"
@emlRecordDiscard

# THE UN-ADVANCED REFERENCE, drawn in the same process at the same axis so
# nothing but the advanced settings can differ. This is what a replay that
# drops them looks like, and having it makes the ADV result an identification
# rather than an inequality: "the replay matches the bare figure" says which
# way it failed, where "the replay differs from the original" does not.
annotate = 0
prev_violinShowJitter = 0
@emlClearAnnotations
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
@emlDrawViolinPlot: table, "advanced violin", "Cohort", "val", 6, 4,
... "color", 1, "grp", "val", valueMin, valueMax
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/ADV_BARE.png"
PRAAT

echo "# leg ADV record" > "$OUT/adv_record.log"
run_praat "$OUT/adv_record.praat" "$OUT/adv_record.log"

# THE EMITTED FILE IS INCLUDED, NOT runScript:-ED. roundtrip_graph.sh records
# why at length: a runScript:-ed file keeps its own drawn-extent tracker, so
# the caller cannot save the picture it drew. `include` is also what a user
# experiences, since for them the emitted file IS the top-level script.
cat > "$OUT/adv_replay.praat" <<PRAAT
$FIXTURE
table = selected ("Table")
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
include $OUT/adv_emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/ADV_REPLAY.png"
PRAAT
echo "# leg ADV replay" > "$OUT/adv_replay.log"
run_praat "$OUT/adv_replay.praat" "$OUT/adv_replay.log"

for f in ADV_ORIG ADV_BARE ADV_REPLAY; do
    if [[ -f "$OUT/$f.png" ]]; then
        kv "${f,,}_md5"   "$(md5sum "$OUT/$f.png" | cut -d' ' -f1)"
        kv "${f,,}_bytes" "$(stat -c%s "$OUT/$f.png")"
    else
        kv "${f,,}_md5" MISSING
        kv "${f,,}_bytes" 0
    fi
done

# THE COMPARISON IS NOT `cmp`, AND THE REASON IS MEASURED. See the header of
# pngdiff.py: the recorder emits a figure's resolved axis to six decimal
# places, so a replayed draw anti-aliases forty jitter marks fractionally
# differently -- forty pixels, at most 4 of 255, on an otherwise identical
# figure. Byte equality would fail on a perfect replay. What separates a
# faithful replay from one that lost its bracket and its points is 2740
# pixels at up to 254, so the count of pixels differing by more than 32 sits
# in a two-order-of-magnitude gap rather than on a tuned line.
pdiff () {   # pdiff <a> <b> <field>   field: over|max
    if [[ ! -f "$1" || ! -f "$2" ]]; then echo -1; return; fi
    local line; line=$(python3 "$SCRIPT_DIR/pngdiff.py" "$1" "$2" 32)
    if [[ "$3" == over ]]; then awk '{print $2}' <<<"$line"
    else awk '{print $4}' <<<"$line"; fi
}
kv adv_orig_vs_bare_over32    "$(pdiff "$OUT/ADV_ORIG.png"   "$OUT/ADV_BARE.png" over)"
kv adv_replay_vs_orig_over32  "$(pdiff "$OUT/ADV_REPLAY.png" "$OUT/ADV_ORIG.png" over)"
kv adv_replay_vs_bare_over32  "$(pdiff "$OUT/ADV_REPLAY.png" "$OUT/ADV_BARE.png" over)"
kv adv_replay_vs_orig_max     "$(pdiff "$OUT/ADV_REPLAY.png" "$OUT/ADV_ORIG.png" max)"

# STATIC WITNESSES ON THE EMITTED FILE. Independent of the picture on purpose:
# if a future change made both figures wrong in the same way the comparison
# above would go green, and these would not.
em="$OUT/adv_emitted.praat"
# THE COUNT COMES BACK ON ONE LINE OR NOT AT ALL. `grep -c` on a file with no
# match prints 0 AND exits 1, so the obvious `|| echo 0` appends a second
# line and the TSV gains a phantom row -- which it did, on the first run.
grepc () { local n; n=$(grep -c -- "$1" "$em" 2>/dev/null); echo "${n:-0}"; }
kv emit_jitter_lines      "$(grepc '^prev_violinShowJitter = ')"
kv emit_annotate_lines    "$(grepc '^annotate = ')"
kv emit_bracket_render    "$(grepc '@emlDrawAnnotations:')"
kv emit_clear_annotations "$(grepc '@emlClearAnnotations')"
kv emit_savepanel         "$(grepc '@emlSavePanel:')"
kv emit_beginpause        "$(grepc 'beginPause')"
kv emit_include_root      "$(sed -n 's|^include \(.*\)/stats/eml-core-utilities.praat$|\1|p' "$em" 2>/dev/null | head -1)"
kv emit_claims_home_relative "$(grepc 'Paths are home-relative')"
kv emit_states_absolute      "$(grepc 'These paths are ABSOLUTE')"

# ===========================================================================
# LEG SAVE — a recorded save step, replayed
# ===========================================================================
# THE SAVE STEP IS SYNTHESISED, AND IT HAS TO BE. @emlSavePanel records its own
# step from INSIDE the dialog, so no headless driver can make the plugin
# produce one. The string below is copied from the emitter in
# stats/eml-output.praat, and v58 re-reads that file and asserts the shape
# still matches — a fixture that quietly drifts from the code it stands in for
# is a test of nothing.
#
# THE STEM CARRIES A STAMP ALREADY, because a real one does: @emlSavePanel
# proposes <stem>_<stamp> and then writes back whatever the field held. That
# is what made replay generations accrete a stamp each.
SAVE_STEM='vt_two-group_20260814_120000'
cat > "$OUT/save_record.praat" <<PRAAT
$INCLUDES
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot\$ = "$PLUG"
@emlRecordLoadPhrases: "$PLUG/data/eml-record-phrases.csv"
@emlRecordHeader: "Table vt", 40, 2, "14 August 2026, 00:00:00"

$FIXTURE
table = selected ("Table")

@emlRunTwoGroupAnalysis: table, "val", "grp", "parametric", 0
@emlRecordSource: table
@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder\$ = " + """" + "$OUT/saved" + """" + newline\$
... + "@emlSavePanel: 0, " + """" + "$SAVE_STEM" + """" + ", outputFolder\$, "
... + """""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

@emlRecordFlush: "$OUT/save_emitted.praat"
@emlRecordDiscard
PRAAT
echo "# leg SAVE record" > "$OUT/save_record.log"
run_praat "$OUT/save_record.praat" "$OUT/save_record.log"

cat > "$OUT/save_replay.praat" <<PRAAT
$FIXTURE
table = selected ("Table")
include $OUT/save_emitted.praat
PRAAT
echo "# leg SAVE replay" > "$OUT/save_replay.log"
run_praat "$OUT/save_replay.praat" "$OUT/save_replay.log"

names=$(cd "$OUT/saved" 2>/dev/null && ls -1 2>/dev/null | tr '\n' ' ')
kv save_files "$(cd "$OUT/saved" 2>/dev/null && ls -1 2>/dev/null | wc -l)"
kv save_names "$names"
# THE INTEGER THAT SEPARATES FIXED FROM BROKEN: how many _YYYYMMDD_HHMMSS
# stamps the worst-off written name carries. One is the panel's convention.
# Two is the accretion the author's ruling dissolves, and it is what a replay
# through the reopened panel produced.
maxstamps=0
for n in $names; do
    c=$(printf '%s' "$n" | grep -o '_[0-9]\{8\}_[0-9]\{6\}' | wc -l)
    (( c > maxstamps )) && maxstamps=$c
done
kv save_max_stamps "$maxstamps"
# One base name for the whole press, as everywhere else the plugin saves.
kv save_distinct_stems "$(printf '%s\n' $names \
    | sed -E 's/(_tidy|_glance|_augment|_posthoc_tidy|_effectsize_tidy|_report)?\.(csv|txt|png)$//' \
    | sort -u | wc -l)"
# THE NUMBERS MUST NOT REGRESS. The audit's one unqualified finding about the
# recorder is that its numbers replay perfectly -- a replayed Welch matched the
# original to printed precision. Both legs run the same analysis and print the
# same report, so the two transcripts are compared on the statistics lines.
# Everything above changes what a replay DRAWS and WRITES; nothing above may
# change what it COMPUTES.
statlines () {
    grep -E '^ +(t|df|p|Cohen|Hedges) +' "$1" 2>/dev/null | tr -s ' '
}
if [[ -f "$OUT/save_record.log" && -f "$OUT/save_replay.log" ]]; then
    statlines "$OUT/save_record.log" > "$OUT/stats_record.txt"
    statlines "$OUT/save_replay.log" > "$OUT/stats_replay.txt"
    kv save_stat_lines "$(wc -l < "$OUT/stats_record.txt")"
    kv save_stats_identical \
       "$(cmp -s "$OUT/stats_record.txt" "$OUT/stats_replay.txt" && echo 1 || echo 0)"
else
    kv save_stat_lines 0
    kv save_stats_identical 0
fi
kv save_report_bytes "$(cat "$OUT/saved"/*_report.txt 2>/dev/null | wc -c)"

sem="$OUT/save_emitted.praat"
sgrepc () { local n; n=$(grep -c -- "$1" "$sem" 2>/dev/null); echo "${n:-0}"; }
kv save_emit_savepanel   "$(sgrepc '@emlSavePanel:')"
kv save_emit_replaysave  "$(sgrepc '@emlRecordReplaySave:')"
kv save_emit_beginpause  "$(sgrepc 'beginPause')"

# ===========================================================================
# LEG META — the record tables removed the way a user can remove them
# ===========================================================================
# ONE PRAAT PROCESS, SEVERAL SCOPES, because that is the only way the defect
# exists: re-attaching to the record tables across a script boundary is the
# whole design, and a stale table can only be inherited by a scope that did
# not create it. runScript: gives separate scopes inside one process, which is
# what a menu command gets — the model harness/record_e2e established.
cat > "$OUT/meta_op.praat" <<PRAAT
form: "op"
    word: "Mode", ""
    word: "Session", "X"
endform
$INCLUDES
@emlRecordInit
if mode\$ = "begin"
    @emlRecordBegin: ""
    # NO emlRecordPluginRoot$ OVERRIDE HERE, unlike the other legs. What this
    # leg measures is precisely the value @emlRecordBegin resolved, and
    # whether it reaches the flush in another scope.
    @emlRecordLoadPhrases: "$PLUG/data/eml-record-phrases.csv"
    @emlRecordHeader: "Table vt", 40, 2, "SESSION_" + session$
elsif mode\$ = "step"
    nocheck selectObject: "Table vt"
    @emlRecordSource: selected ("Table")
    @emlRecordStep: "analysis", "a recorded step", "", "; nothing", ""
elsif mode\$ = "flush"
    @emlRecordFlush: "$OUT/meta_emitted.praat"
    appendInfoLine: "FLUSHED written=", emlRecordFlush.written
elsif mode\$ = "flush2"
    @emlRecordFlush: "$OUT/meta_emitted2.praat"
    appendInfoLine: "FLUSHED2 written=", emlRecordFlush.written
elsif mode\$ = "report"
    appendInfoLine: "ACTIVE=", emlRecordActive, " META=", emlRecordMetaId,
    ... " STAMP=", emlRecordStamp\$
endif
PRAAT

cat > "$OUT/meta_driver.praat" <<PRAAT
$FIXTURE
writeInfoLine: "meta driver"

runScript: "$OUT/meta_op.praat", "begin", "A"
runScript: "$OUT/meta_op.praat", "step", ""

# The user removes the BUFFER from the Objects window. Measured behaviour: the
# recording silently ends, and the meta table is left behind.
nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
if numberOfSelected () = 1
    Remove
endif
select all
nMetaAfterKill = 0
for o from 1 to numberOfSelected ()
    if selected\$ (o) = "Table emlRecordMeta"
        nMetaAfterKill = nMetaAfterKill + 1
    endif
endfor
appendInfoLine: "ORPHANMETA=", nMetaAfterKill
runScript: "$OUT/meta_op.praat", "report", ""

# A NEW SESSION STARTS WITH THE ORPHAN STILL THERE. This is the audit's
# sequence exactly, and it is the state that stamped a live session with a
# dead one's time.
runScript: "$OUT/meta_op.praat", "begin", "B"
select all
nMetaAfterBegin = 0
for o from 1 to numberOfSelected ()
    if selected\$ (o) = "Table emlRecordMeta"
        nMetaAfterBegin = nMetaAfterBegin + 1
    endif
endfor
appendInfoLine: "METAAFTERBEGIN=", nMetaAfterBegin

# THE SECOND HALF OF THE DEFECT: a decoy meta from a session that is gone,
# planted so that a lookup by NAME can find it. The pairing is what has to
# refuse it — the sweep above cannot, because this one arrives after the live
# session started, which is exactly how the audit's user reached it (they
# deleted the wrong one of two identically named rows).
Create Table with column names: "emlRecordMeta", 0, "key value"
decoy = selected ("Table")
Append row
Set string value: 1, "key", "stamp"
Set string value: 1, "value", "SESSION_DEAD"
Append row
Set string value: 2, "key", "buffer"
Set string value: 2, "value", "999999"
Append row
Set string value: 3, "key", "input"
Set string value: 3, "value", "Table deadTable"

runScript: "$OUT/meta_op.praat", "step", ""
runScript: "$OUT/meta_op.praat", "flush", ""

# ---- THE AUDIT'S OWN SEQUENCE, TO THE END -------------------------------
# The user then deleted the LIVE meta, not the decoy — two rows with the same
# name, and they picked the wrong one. That leaves a session whose only
# reachable store belongs to a recording that is gone, and it is what stamped
# a live emission with a dead session's time. The sweep cannot help here: the
# decoy arrived after this session started.
runScript: "$OUT/meta_op.praat", "begin", "C"
Create Table with column names: "emlRecordMeta", 0, "key value"
Append row
Set string value: 1, "key", "stamp"
Set string value: 1, "value", "SESSION_DEAD2"
Append row
Set string value: 2, "key", "buffer"
Set string value: 2, "value", "999998"
Append row
Set string value: 3, "key", "input"
Set string value: 3, "value", "Table deadTable2"
decoy2 = selected ("Table")
# Remove every meta table EXCEPT this decoy: the live one this session made,
# and the earlier decoy, so the only store left names a recording that is
# gone. That is the state the audit's user was in, reached the way they
# reached it -- two rows with the same name, and they deleted the wrong one.
select all
nKill = 0
for o from 1 to numberOfSelected ()
    if selected$ (o) = "Table emlRecordMeta" and selected (o) <> decoy2
        nKill = nKill + 1
        killMeta[nKill] = selected (o)
    endif
endfor
for k from 1 to nKill
    nocheck removeObject: killMeta[k]
endfor
appendInfoLine: "METAKILLED=", nKill
runScript: "$OUT/meta_op.praat", "step", ""
runScript: "$OUT/meta_op.praat", "flush2", ""
PRAAT
# THE META LEG RUNS UNDER A PREF DIR INSIDE $HOME, AND ONLY THIS LEG DOES.
#
# The home-relative rewrite in @emlRecordBegin fires only when
# preferencesDirectory$ actually sits under homeDirectory$ — which it does for
# every real user and does NOT under the --pref-dir=<harness>/... isolation the
# rest of this rig uses. plugin/dev/tests/phase1/test-record.praat records the
# same trap: asserting the tilde under the harness's own invocation failed for
# a reason that looked like a version regression for an afternoon.
#
# So this leg, which is the only one that flushes in a DIFFERENT scope from the
# one that began the recording, runs where the rewrite can happen. That makes
# the include root a two-state answer — "~/..." if the resolution survived the
# script boundary, "/root/..." if a fresh scope re-defaulted it — instead of
# one value that looks the same either way. The emitted file is read, never
# run, so nothing has to be installed there.
META_PREFS="$HOME/.eml_replay_meta_prefs"
rm -rf "$META_PREFS"
mkdir -p "$META_PREFS"
echo "# leg META" > "$OUT/meta.log"
( cd "$ROOT" && timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$META_PREFS" \
    --run "$OUT/meta_driver.praat" >>"$OUT/meta.log" 2>&1 )
rm -rf "$META_PREFS"

kv meta_orphan_after_buffer_kill \
   "$(sed -n 's/^ORPHANMETA=\([0-9]*\).*/\1/p' "$OUT/meta.log" | head -1)"
kv meta_tables_after_new_begin \
   "$(sed -n 's/^METAAFTERBEGIN=\([0-9]*\).*/\1/p' "$OUT/meta.log" | head -1)"
kv meta_flush_written \
   "$(sed -n 's/^FLUSHED written=\([0-9-]*\).*/\1/p' "$OUT/meta.log" | head -1)"
if [[ -f "$OUT/meta_emitted.praat" ]]; then
    kv meta_emitted_stamp_line \
       "$(grep -m1 -- '-- *recorded on Praat' "$OUT/meta_emitted.praat" | tr -d '\r')"
    kv meta_emitted_has_dead_stamp \
       "$(grep -c 'SESSION_DEAD' "$OUT/meta_emitted.praat")"
    kv meta_emitted_has_live_stamp \
       "$(grep -c 'SESSION_B' "$OUT/meta_emitted.praat")"
    kv meta_emitted_names_dead_table \
       "$(grep -c 'deadTable' "$OUT/meta_emitted.praat")"
    # THE INCLUDE ROOT, MEASURED ACROSS A SCRIPT BOUNDARY. This is the only
    # leg that flushes in a DIFFERENT scope from the one that began the
    # recording, which is the shape of every real menu-driven session and the
    # shape no other harness has. The root resolved at Begin has to reach the
    # flush through the meta object or the emitted file carries whatever a
    # fresh scope defaulted to -- NEW-G11-1's live half.
    kv meta_emit_include_root \
       "$(sed -n 's|^include \(.*\)/stats/eml-core-utilities.praat$|\1|p' \
          "$OUT/meta_emitted.praat" | head -1)"
    kv meta_emit_root_is_home_relative \
       "$(grep -c '^include ~/' "$OUT/meta_emitted.praat" | head -1)"
    # THE DENOMINATOR FOR THE LINE ABOVE. The include block is as long as the
    # module list in setup.praat, so the count that matters is not a number
    # but a ratio: every include line home-relative, none left absolute.
    # Recording both halves here means v58 compares two measurements of this
    # file instead of one measurement against a literal.
    kv meta_emit_include_lines \
       "$(grep -c '^include ' "$OUT/meta_emitted.praat" | head -1)"
    kv meta_emit_claims_home_relative \
       "$(grep -c 'Paths are home-relative' "$OUT/meta_emitted.praat")"
    kv meta_emit_states_absolute \
       "$(grep -c 'These paths are ABSOLUTE' "$OUT/meta_emitted.praat")"

else
    kv meta_emit_include_root MISSING
    kv meta_emit_root_is_home_relative -1
    kv meta_emit_include_lines -1
    kv meta_emit_claims_home_relative -1
    kv meta_emit_states_absolute -1
    kv meta_emitted_stamp_line MISSING
    kv meta_emitted_has_dead_stamp -1
    kv meta_emitted_has_live_stamp -1
    kv meta_emitted_names_dead_table -1
fi

if [[ -f "$OUT/meta_emitted2.praat" ]]; then
    kv meta2_has_dead_stamp  "$(grep -c 'SESSION_DEAD2' "$OUT/meta_emitted2.praat")"
    kv meta2_names_dead_table "$(grep -c 'deadTable2' "$OUT/meta_emitted2.praat")"
    kv meta2_stamp_recovered_note \
       "$(grep -c "start time was lost" "$OUT/meta_emitted2.praat")"
    kv meta2_stamp_line \
       "$(grep -m1 -- '-- *recorded on Praat' "$OUT/meta_emitted2.praat" | tr -d '\r')"
else
    kv meta2_has_dead_stamp -1
    kv meta2_names_dead_table -1
    kv meta2_stamp_recovered_note -1
    kv meta2_stamp_line MISSING
fi

# ===========================================================================
# LEG FOLDER — a replayed save onto a folder two levels deep that is absent
# ===========================================================================
# createFolder: IS mkdir AND NOT mkdir -p — measured on 6.6.30, handed a path
# whose parents are missing it creates nothing. So the target here is two
# levels deep on purpose: a single createFolder: would leave this leg's
# artefacts missing and the check red, which is the property that makes it a
# check rather than a formality.
DEEP="$OUT/deep/level2/level3"
cat > "$OUT/folder_replay.praat" <<PRAAT
$INCLUDES
@emlInitDrawingDefaults
$FIXTURE
table = selected ("Table")
@emlRunTwoGroupAnalysis: table, "val", "grp", "parametric", 0
outputFolder\$ = "$DEEP"
@emlRecordReplaySave: 0, "vt_deep_20260814_120000", outputFolder\$, ""
PRAAT
echo "# leg FOLDER" > "$OUT/folder.log"
run_praat "$OUT/folder_replay.praat" "$OUT/folder.log"
kv folder_files "$( [[ -d "$DEEP" ]] && ls -1 "$DEEP" | wc -l || echo 0 )"
kv folder_created "$( [[ -d "$DEEP" ]] && echo 1 || echo 0 )"
# The transcript must be clean: an abort quoting the plugin's own source at
# the user is the failure NEW-G11-4 names, and it is visible here as Praat's
# "not performed or completed" line.
kv folder_praat_abort "$(grep -c 'not performed or completed' "$OUT/folder.log")"
kv adv_praat_abort "$(grep -c 'not performed or completed' \
    "$OUT/adv_record.log" "$OUT/adv_replay.log" | awk -F: '{s+=$2} END {print s+0}')"
kv save_praat_abort "$(grep -c 'not performed or completed' \
    "$OUT/save_record.log" "$OUT/save_replay.log" | awk -F: '{s+=$2} END {print s+0}')"

# ===========================================================================
# LEG RETARGET — the block is EDITED and the file is RUN
# ===========================================================================
# THE PROOF OF RULING 9 IS A DRIVE, NOT A DIFF, and the distinction is the
# reason this leg exists. A renderer that gathers every column name into the
# block at the top and leaves the steps below reading their own literals
# passes any grep anybody would write: the variables are there, spelled
# correctly, with the right values. It is also completely useless, because
# editing them changes nothing. The only way to tell the two apart is to edit
# the block and run the file.
#
# So: record a session, emit it, change the FIVE declaration lines and nothing
# else, and run the result against a table with different column names. The
# number of changed lines is measured (5 -- one object, four columns) so that
# "only the header block was edited" is an integer in the artefact rather than
# a claim in a commit message.
#
# THE SESSION IS CHOSEN TO EXERCISE THE ROLE RULE, not merely to be a session:
#
#   step 1  two-way ANOVA of val by grp and site
#   step 2  violin of val by grp
#
# so "val" is a value column TWICE and gets ONE variable, while "grp" is a
# two-way factor in one step and a plot's grouping column in the other and
# gets TWO. That is the ruling's own distinction -- distinct ROLE, not distinct
# LITERAL -- and it is visible in the emitted block rather than argued for.
#
# WHAT THE RETARGETED RUN HAS TO SHOW, all three of which are measured below:
#   * it runs at all -- a script still naming "val" cannot, since the new
#     table has no such column, so an abort here IS the defect;
#   * its report names the NEW columns, which only reading the variables can
#     produce;
#   * its numbers are the ORIGINAL numbers, because the twin table holds the
#     same values under different headers. Retargeting must change what is
#     read, not what is computed.
read -r -d '' FIXTURE_WT <<'PRAATWT'
Create Table with column names: "wt", 0, "grp site val"
rngState = 20260814
row = 0
for g from 1 to 2
    for s from 1 to 2
        for k from 1 to 10
            rngState = (1103515245 * rngState + 12345) mod 2147483648
            row = row + 1
            Append row
            Set string value: row, "grp", "Cohort " + string$ (g)
            Set string value: row, "site", "Room " + string$ (s)
            Set numeric value: row, "val",
            ... 1 + g * 1.2 + s * 0.4 + (rngState / 2147483648 - 0.5) * 1.4
        endfor
    endfor
endfor
PRAATWT

# THE TWIN. Same generator, same order, same numbers -- and three different
# column names on a differently named Table. Everything that separates a
# retargeted run from the original is a name.
read -r -d '' FIXTURE_RT <<'PRAATRT'
Create Table with column names: "rt", 0, "cohort room dB"
rngState = 20260814
row = 0
for g from 1 to 2
    for s from 1 to 2
        for k from 1 to 10
            rngState = (1103515245 * rngState + 12345) mod 2147483648
            row = row + 1
            Append row
            Set string value: row, "cohort", "Cohort " + string$ (g)
            Set string value: row, "room", "Room " + string$ (s)
            Set numeric value: row, "dB",
            ... 1 + g * 1.2 + s * 0.4 + (rngState / 2147483648 - 0.5) * 1.4
        endfor
    endfor
endfor
PRAATRT

cat > "$OUT/retarget_record.praat" <<PRAAT
$INCLUDES
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot\$ = "$PLUG"
@emlRecordLoadPhrases: "$PLUG/data/eml-record-phrases.csv"
@emlRecordHeader: "Table wt", 40, 3, "14 August 2026, 00:00:00"

$FIXTURE_WT
table = selected ("Table")

@emlRunTwoWayAnalysis: table, "val", "grp", "site"

selectObject: table
vMin = Get minimum: "val"
vMax = Get maximum: "val"
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
@emlDrawViolinPlot: table, "retarget violin", "Cohort", "val", 6, 4,
... "color", 1, "grp", "val", vMin, vMax
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/RET_ORIG.png"

@emlRecordFlush: "$OUT/retarget_emitted.praat"
@emlRecordDiscard
PRAAT
echo "# leg RETARGET record" > "$OUT/retarget_record.log"
run_praat "$OUT/retarget_record.praat" "$OUT/retarget_record.log"

# THE REFERENCE. The same analysis run DIRECTLY on the twin, by hand, with the
# new column names written out -- so the retargeted file is compared against
# what the plugin does when it is simply told the new names, not against the
# retargeted file's own idea of itself.
cat > "$OUT/retarget_reference.praat" <<PRAAT
$INCLUDES
@emlInitDrawingDefaults
$FIXTURE_RT
table = selected ("Table")
@emlRunTwoWayAnalysis: table, "dB", "cohort", "room"
PRAAT
echo "# leg RETARGET reference" > "$OUT/retarget_reference.log"
run_praat "$OUT/retarget_reference.praat" "$OUT/retarget_reference.log"

# ---- THE EDIT ------------------------------------------------------------
# FIVE LINES, ALL OF THEM DECLARATIONS, ALL OF THEM INSIDE THE BLOCK. sed is
# anchored on `^<name>` so it cannot touch a mention of the same text further
# down the file, and the change is then counted rather than trusted.
cp "$OUT/retarget_emitted.praat" "$OUT/retarget_edited.praat"
sed -i \
    -e 's|^data1\$ = "Table wt"|data1$ = "Table rt"|' \
    -e 's|^\(valueCol\$ *\)= "val"|\1= "dB"|' \
    -e 's|^\(factorACol\$ *\)= "grp"|\1= "cohort"|' \
    -e 's|^\(factorBCol\$ *\)= "site"|\1= "room"|' \
    -e 's|^\(groupCol\$ *\)= "grp"|\1= "cohort"|' \
    "$OUT/retarget_edited.praat"
# COUNTED LINE BY LINE AND NOT OUT OF `diff`, which was the first cut and was
# wrong in the direction that matters: a multi-line hunk header reads
# "52,56c52,56", the obvious sed for a leading line number does not match it,
# and the count silently came back 0 -- a check that could only pass. The two
# files have the same length by construction (sed -i replaces in place), so the
# honest measurement is a paired walk.
kv retarget_lines_changed "$(awk 'NR==FNR{a[FNR]=$0; next}
    $0 != a[FNR] {c++} END {print c+0}' \
    "$OUT/retarget_emitted.praat" "$OUT/retarget_edited.praat")"
# AND THE BLOCK IS WHERE THE EDIT LANDED. Every changed line must sit above
# the first step separator, or something below the block was named after all.
kv retarget_edits_below_block "$(
    first_step=$(grep -n -m1 '^# --- Step ' "$OUT/retarget_edited.praat" \
                 | cut -d: -f1)
    awk -v f="${first_step:-0}" 'NR==FNR{a[FNR]=$0; next}
        $0 != a[FNR] && FNR >= f {c++} END {print c+0}' \
        "$OUT/retarget_emitted.praat" "$OUT/retarget_edited.praat")"

cat > "$OUT/retarget_replay.praat" <<PRAAT
$FIXTURE_RT
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
include $OUT/retarget_edited.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/RET_REPLAY.png"
PRAAT
echo "# leg RETARGET replay" > "$OUT/retarget_replay.log"
run_praat "$OUT/retarget_replay.praat" "$OUT/retarget_replay.log"

kv retarget_praat_abort "$(grep -c 'not performed or completed' \
    "$OUT/retarget_record.log" "$OUT/retarget_reference.log" \
    "$OUT/retarget_replay.log" | awk -F: '{s+=$2} END {print s+0}')"

# THE REPORT NAMES THE NEW COLUMNS AND NOT THE OLD ONES. The header block of
# the plugin's own two-way report echoes what it was asked for, so this is the
# variables being READ, one layer below the numbers.
kv retarget_report_new_cols "$(grep -cE '^ +(Data column +dB|Factor 1 +cohort|Factor 2 +room)$' \
    "$OUT/retarget_replay.log")"
kv retarget_report_old_cols "$(grep -cE '^ +(Data column +val|Factor 1 +grp|Factor 2 +site)$' \
    "$OUT/retarget_replay.log")"

# THE TRANSCRIPTS. Against the reference: identical, label for label and digit
# for digit, once the wall-clock line each report stamps itself with is out of
# the way. That line is the only thing in a report that a second run may
# legitimately change.
notime () { grep -vE '^ +[A-Z][a-z][a-z] [A-Z][a-z][a-z] +[0-9]+ ' "$1"; }
notime "$OUT/retarget_reference.log" > "$OUT/retarget_ref_norm.txt"
notime "$OUT/retarget_replay.log"    > "$OUT/retarget_replay_norm.txt"
# The two logs open with their own harness banner line, which is not report
# text; dropped from both.
sed -i '1d' "$OUT/retarget_ref_norm.txt" "$OUT/retarget_replay_norm.txt"
kv retarget_matches_reference "$(cmp -s "$OUT/retarget_ref_norm.txt" \
    "$OUT/retarget_replay_norm.txt" && echo 1 || echo 0)"
kv retarget_report_lines "$(wc -l < "$OUT/retarget_replay_norm.txt")"

# AND AGAINST THE ORIGINAL RECORDING: the NUMBERS only, because the labels are
# exactly what changed. The report pads its label field to a fixed width, so
# cutting at column 21 leaves the ANOVA table's arithmetic and nothing else.
anovanum () {
    sed -n '/ANOVA Table/,/Exact p-values/p' "$1" | grep -E '^[A-Za-z]' \
        | cut -c21-
}
anovanum "$OUT/retarget_record.log" > "$OUT/retarget_num_orig.txt"
anovanum "$OUT/retarget_replay.log" > "$OUT/retarget_num_new.txt"
kv retarget_anova_rows "$(wc -l < "$OUT/retarget_num_orig.txt")"
kv retarget_numbers_unchanged "$(cmp -s "$OUT/retarget_num_orig.txt" \
    "$OUT/retarget_num_new.txt" && echo 1 || echo 0)"

# THE FIGURE, on the same terms as the ADV leg: the retargeted violin against
# the one the recording itself drew. Same numbers under different headers, so
# a faithful retarget is the same picture -- and the residual is the recorder's
# six-decimal axis, exactly as it is there.
for f in RET_ORIG RET_REPLAY; do
    if [[ -f "$OUT/$f.png" ]]; then
        kv "${f,,}_bytes" "$(stat -c%s "$OUT/$f.png")"
    else
        kv "${f,,}_bytes" 0
    fi
done
kv retarget_fig_vs_orig_over32 "$(pdiff "$OUT/RET_REPLAY.png" "$OUT/RET_ORIG.png" over)"
kv retarget_fig_vs_orig_max    "$(pdiff "$OUT/RET_REPLAY.png" "$OUT/RET_ORIG.png" max)"

# ---- THE BLOCK ITSELF, WHERE THE ROLE RULE AND THE RUN RULE ARE VISIBLE --
# The declarations name the run they belong to. This leg drives both steps in
# ONE script scope with no form between them, so both are run 1 -- and inside
# one run the role rule is what separates the variables: "val" analysed and
# then plotted is ONE variable, "grp" as a two-way factor and as the violin's
# grouping column is TWO.
# Read from the EMITTED file, before the edit. Every one of these is an exact
# line, because "a variable of about the right name exists somewhere" is the
# assertion a renderer that gathered names and wired none of them would pass.
rem="$OUT/retarget_emitted.praat"
remc () { local n; n=$(grep -c -- "$1" "$rem" 2>/dev/null); echo "${n:-0}"; }
kv retarget_block_value  "$(remc '^valueCol\$ *= "val"   ; the measured column -- run 1, steps 1 (analysis), 2 (draw)$')"
kv retarget_block_factorA "$(remc '^factorACol\$ *= "grp"   ; the first factor -- run 1, step 1 (analysis)$')"
kv retarget_block_factorB "$(remc '^factorBCol\$ *= "site"   ; the second factor -- run 1, step 1 (analysis)$')"
kv retarget_block_group   "$(remc '^groupCol\$ *= "grp"   ; the grouping column -- run 1, step 2 (draw)$')"
kv retarget_block_data    "$(remc '^data1\$ = "Table wt"   ; run 1, steps 1 (analysis), 2 (draw)$')"
# THE STEPS BELOW READ THEM. Exact call lines: the two-way's three column
# slots and the violin's two, all variables, and -- on the same line -- the
# violin's y-axis LABEL still the literal "val", which is the role rule
# stated as text: same string, one is a column and one is not.
kv retarget_call_twoway "$(remc '^@emlRunTwoWayAnalysis: data, valueCol\$, factorACol\$, factorBCol\$$')"
kv retarget_call_violin "$(remc '^@emlDrawViolinPlot: data, "retarget violin", "Cohort", "val", 6, 4, "color", 1, groupCol\$, valueCol\$,')"
# NO COLUMN LITERAL SURVIVES IN A COLUMN SLOT. Counted as the complement of
# the two lines above: any executable line that still passes a quoted name to
# a slot the block declares. `"val"` as an axis label is not one of those and
# must NOT be counted here -- which is why this counts SLOTS and not strings.
kv retarget_literal_slots "$(grep -cE '^@(emlRunTwoWayAnalysis: data, "|emlDrawViolinPlot: .*, 1, ")' "$rem")"

# ===========================================================================
# LEG LEGEND — ONE PRESS OF DRAW, ONE EMITTED STEP, AND THE FRAME RECOVERABLE
#              FROM THE BLOCK
# ===========================================================================
# AUTHOR RULING B, CHANGE ORDER 8, 16 AUGUST 2026: "one user action emits one
# draw step" carrying "the FINAL resolved range".
#
# THE DEFECT. @emlGraphsDrawWithLegendRoom draws a legend-bearing figure,
# MEASURES the legend, and draws it again on a widened axis, discarding the
# first pass. NEW-G8-3 rewound the CSV collector between the passes on 15 Aug
# 2026 and left the recorder running, so one press emitted
#
#     # --- Step 1 (draw) ---   @emlDrawGroupedViolin: ... axisYMin, axisYMax
#     # --- Step 2 (draw) ---   @emlDrawGroupedViolin: ... axisYMin, axisYMax
#
# and the block read `steps 1 (draw), 2 (draw)`. The second half is the one
# that costs a reader something: the resolved-range note quotes the FIRST step
# to use a pair (@emlRecordColumnManifest), so it named the axis of the pass
# that was thrown away -- 195.0000 .. 235.0000 beside a figure drawn at
# 195 .. 275.
#
# WHY THIS LEG INCLUDES THE FORM. Every other leg here writes the form's state
# out by hand, and could, because it drives a draw procedure directly. This one
# cannot: the two-pass loop IS the thing under test, it lives in
# eml-graphs-form.praat, and a transcription of it would test the copy. The
# file is a LIBRARY -- top-level array initialisation only, no `form:`, no
# `beginPause:`, @emlGraphsWorkflow never called from inside it -- so an
# include gets every procedure and no dialog. harness/formaxis has stood on
# that fact since 16 August; the note above the ADV leg saying the form cannot
# be included predates it and is true only of RUNNING the workflow.
#
# THE Y-RANGE IS LEFT ON AUTO, which is what makes the second half testable.
# On auto the block declares 0.0 / 0.0 -- the sentinel, per ruling 10(b) -- so
# the resolved-range NOTE is the reader's only record of where the figure sat.
# If the note names the discarded pass, a user who types its numbers into the
# block to recover their frame gets the wrong frame, and that is exactly what
# LEG_TUNED measures: the block is edited to the two numbers the note quotes,
# nothing else is touched, and the result is compared with the figure the user
# actually got. On a tree with the defect the note says 235 and the tuned
# replay is a different picture.
#
# THE PLAIN REPLAY IS MEASURED TOO, AND IT IS NOT EXPECTED TO MATCH. An
# emitted script draws once; the legend-room loop is the form's, not the
# recording's, so an unedited auto replay resolves to the axis the figure had
# BEFORE room was made for the legend. That is ruling 10(b) working as ruled
# -- the request is emitted, not the resolution -- and the gap is written into
# the TSV rather than left for someone to discover.
read -r -d '' FIXTURE_LG <<'PRAATLG'
Create Table with column names: "lg", 0, "grp sub val"
rngState = 20260816
row = 0
for g from 1 to 4
    for k from 1 to 14
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set string value: row, "sub", "S" + string$ (k)
        Set numeric value: row, "val",
        ... 200 + g * 6.0 + (rngState / 2147483648 - 0.5) * 9.0
    endfor
endfor
PRAATLG

# The dialog's own state at the point the range-validation block has just
# finished, copied from the form's dispatch block. Values, not logic.
read -r -d '' LGFORM <<'PRAATLGF'
graph_type = 11
objectId = table
title$ = "f0 by cohort"
x_axis_label$ = "Cohort"
y_axis_label$ = "f0 (Hz)"
figure_width = 6
figure_height = 4
colorMode$ = "color"
gridline_mode = 1
gvCatCol$ = "grp"
gvSubCol$ = "sub"
gvValueCol$ = "val"
groupColName$ = "grp"
valueColName$ = "val"
valueMin = 0
valueMax = 0
histFreqMax = 0
tsShowCI = 0
matrixGap = 0
matrixPanelHeight = 0
totalCanvasHeight = figure_height
config_legendPlacement = 1
config_showAdvanced = 1
config_groupSort = 1
emlGroupSortAlphabetical = 0
annotate = 0
dataYMax_forAnnotation = 0
@emlClearAnnotations
PRAATLGF

cat > "$OUT/legend_record.praat" <<PRAAT
$INCLUDES
include $PLUG/graphs/eml-graphs-form.praat
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot\$ = "$PLUG"
@emlRecordLoadPhrases: "$PLUG/data/eml-record-phrases.csv"
@emlRecordHeader: "Table lg", 56, 3, "16 August 2026, 00:00:00"

$FIXTURE_LG
table = selected ("Table")

$LGFORM

@emlGraphsPublishAxisRequest
random_initializeWithSeedUnsafelyButPredictably (20260816)
@emlGraphsDrawWithLegendRoom
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/LEG_ORIG.png"

writeInfoLine: "legend_passes=", legendRoomPass
appendInfoLine: "legend_final_min=", fixed\$ (valueMin, 6)
appendInfoLine: "legend_final_max=", fixed\$ (valueMax, 6)

@emlRecordFlush: "$OUT/legend_emitted.praat"
@emlRecordDiscard
PRAAT
echo "# leg LEGEND record" > "$OUT/legend_record.log"
run_praat "$OUT/legend_record.praat" "$OUT/legend_record.log"

for k in legend_passes legend_final_min legend_final_max; do
    kv "$k" "$(sed -n "s/^$k=//p" "$OUT/legend_record.log" | head -1)"
done

# ---- WHAT THE EMITTED FILE SAYS -------------------------------------------
lem="$OUT/legend_emitted.praat"
lemc () { local n; n=$(grep -c -- "$1" "$lem" 2>/dev/null); echo "${n:-0}"; }
# THE HEADLINE INTEGER. One press of Draw, one step separator of kind (draw),
# one call to the draw procedure. All three, because a renderer that emitted
# one heading over two calls would satisfy the first alone.
kv legend_step_headings "$(grep -cE '^# --- Step [0-9]+ \(draw\) ---$' "$lem" 2>/dev/null || echo 0)"
kv legend_draw_calls    "$(lemc '^@emlDrawGroupedViolin: data')"
kv legend_all_steps     "$(grep -cE '^# --- Step [0-9]+ ' "$lem" 2>/dev/null || echo 0)"
# THE BLOCK'S OWN WORDS. "step 1 (draw)" singular is the fixed shape; "steps
# 1 (draw), 2 (draw)" is the defect, and it is read as text because that is
# what a user sees. The run is read separately: one press of Draw is ONE run,
# and the discarded first pass must not have spent a run number on its way
# out -- a block naming run 2 over a file with one run in it would be the
# same defect wearing the other half of the name.
kv legend_block_steps "$(sed -n 's/^axisYMin  *= .*-- run [0-9]*, \(steps\? .*\)$/\1/p' "$lem" | head -1)"
kv legend_block_run   "$(sed -n 's/^axisYMin  *= .*-- run \([0-9]*\), steps\? .*$/\1/p' "$lem" | head -1)"
kv legend_block_min   "$(sed -n 's/^axisYMin  *= \([^ ]*\)  *;.*$/\1/p' "$lem" | head -1)"
kv legend_block_max   "$(sed -n 's/^axisYMax  *= \([^ ]*\)  *;.*$/\1/p' "$lem" | head -1)"
# THE NOTE, and the two numbers out of it. Parsed rather than assumed, because
# the edit below is made FROM the note: the leg has to be unable to tune the
# replay to anything the file did not say.
kv legend_note "$(sed -n 's/^axisYMax  *= .*; on the recorded data it resolved to //p' "$lem" | head -1)"
LG_NOTE_MIN="$(sed -n 's/^axisYMax  *= .*; on the recorded data it resolved to \([^ ]*\) \.\. \([^ ]*\)$/\1/p' "$lem" | head -1)"
LG_NOTE_MAX="$(sed -n 's/^axisYMax  *= .*; on the recorded data it resolved to \([^ ]*\) \.\. \([^ ]*\)$/\2/p' "$lem" | head -1)"
kv legend_note_min "${LG_NOTE_MIN:-<none>}"
kv legend_note_max "${LG_NOTE_MAX:-<none>}"

# ---- THE PLAIN REPLAY -----------------------------------------------------
cat > "$OUT/legend_replay.praat" <<PRAAT
$FIXTURE_LG
table = selected ("Table")
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260816)
include $lem
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/LEG_REPLAY.png"
PRAAT
echo "# leg LEGEND replay" > "$OUT/legend_replay.log"
run_praat "$OUT/legend_replay.praat" "$OUT/legend_replay.log"

# AND AGAIN, INTO A SECOND FILE. Byte equality between two runs of the same
# emitted script on the same data is the determinism half of the ruling's test
# requirement, and it is `cmp` rather than a pixel count: there is nothing here
# for anti-aliasing to differ about, because both runs draw the same call from
# the same seed.
cat > "$OUT/legend_replay2.praat" <<PRAAT
$FIXTURE_LG
table = selected ("Table")
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260816)
include $lem
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/LEG_REPLAY2.png"
PRAAT
echo "# leg LEGEND replay 2" > "$OUT/legend_replay2.log"
run_praat "$OUT/legend_replay2.praat" "$OUT/legend_replay2.log"

# ---- THE TUNED REPLAY: THE BLOCK EDITED TO THE NOTE'S OWN NUMBERS ---------
# Two lines, both declarations, both inside the block, and the values come out
# of the note rather than out of this script. sed is anchored on ^axisY so it
# cannot reach a mention of the same text further down the file, and the number
# of changed lines is counted afterwards rather than trusted.
cp "$lem" "$OUT/legend_tuned.praat"
if [[ -n "${LG_NOTE_MIN:-}" && -n "${LG_NOTE_MAX:-}" ]]; then
    sed -i \
        -e "s|^\(axisYMin *\)= [^ ]*|\1= $LG_NOTE_MIN|" \
        -e "s|^\(axisYMax *\)= [^ ]*|\1= $LG_NOTE_MAX|" \
        "$OUT/legend_tuned.praat"
fi
kv legend_tuned_lines_changed "$(awk 'NR==FNR{a[FNR]=$0; next}
    $0 != a[FNR] {c++} END {print c+0}' "$lem" "$OUT/legend_tuned.praat")"
kv legend_tuned_edits_below_block "$(
    first_step=$(grep -n -m1 '^# --- Step ' "$OUT/legend_tuned.praat" | cut -d: -f1)
    awk -v f="${first_step:-0}" 'NR==FNR{a[FNR]=$0; next}
        $0 != a[FNR] && FNR >= f {c++} END {print c+0}' \
        "$lem" "$OUT/legend_tuned.praat")"

cat > "$OUT/legend_tuned_replay.praat" <<PRAAT
$FIXTURE_LG
table = selected ("Table")
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260816)
include $OUT/legend_tuned.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/LEG_TUNED.png"
PRAAT
echo "# leg LEGEND tuned replay" > "$OUT/legend_tuned.log"
run_praat "$OUT/legend_tuned_replay.praat" "$OUT/legend_tuned.log"

kv legend_praat_abort "$(grep -c 'not performed or completed' \
    "$OUT/legend_record.log" "$OUT/legend_replay.log" \
    "$OUT/legend_replay2.log" "$OUT/legend_tuned.log" \
    | awk -F: '{s+=$2} END {print s+0}')"

for f in LEG_ORIG LEG_REPLAY LEG_REPLAY2 LEG_TUNED; do
    if [[ -f "$OUT/$f.png" ]]; then
        kv "${f,,}_bytes" "$(stat -c%s "$OUT/$f.png")"
        kv "${f,,}_md5"   "$(md5sum "$OUT/$f.png" | cut -d' ' -f1)"
    else
        kv "${f,,}_bytes" 0
        kv "${f,,}_md5" MISSING
    fi
done

cmpq () { if [[ -f "$1" && -f "$2" ]] && cmp -s "$1" "$2"; then echo 1; else echo 0; fi; }
kv legend_replay_deterministic "$(cmpq "$OUT/LEG_REPLAY.png" "$OUT/LEG_REPLAY2.png")"
kv legend_tuned_is_orig_bytes  "$(cmpq "$OUT/LEG_TUNED.png"  "$OUT/LEG_ORIG.png")"
kv legend_tuned_vs_orig_over32   "$(pdiff "$OUT/LEG_TUNED.png"  "$OUT/LEG_ORIG.png" over)"
kv legend_tuned_vs_orig_max      "$(pdiff "$OUT/LEG_TUNED.png"  "$OUT/LEG_ORIG.png" max)"
# THE VACUITY GUARD. If making room for the legend changed nothing, the tuned
# replay would match the original however wrong the note was, and every check
# above would be satisfied by a rig that never engaged the two-pass loop.
kv legend_plain_vs_orig_over32   "$(pdiff "$OUT/LEG_REPLAY.png" "$OUT/LEG_ORIG.png" over)"
kv legend_plain_vs_tuned_over32  "$(pdiff "$OUT/LEG_REPLAY.png" "$OUT/LEG_TUNED.png" over)"

# ---- THE SAME PRESS WITH A STEP IN FRONT OF IT ---------------------------
# A rewind that emptied the buffer would pass every check above, because the
# leg above marks at ZERO rows -- a figure drawn as the first thing in a
# recording. That is the common case and it is also the one that hides a
# rewind which discards everything rather than the pass. So: one ANOVA, then
# the same legend figure. Two steps must survive, the analysis must be the
# one that did, and the block must name the DRAW as step 2 and no other.
#
# It is also the branch that removes rows rather than replacing the buffer:
# Praat will not remove a Table's only row, so a mark at zero rows and a mark
# at one row take different paths through @emlRecordRewind, and only this
# sub-leg reaches the first of them.
cat > "$OUT/legend_after_record.praat" <<PRAAT
$INCLUDES
include $PLUG/graphs/eml-graphs-form.praat
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot\$ = "$PLUG"
@emlRecordLoadPhrases: "$PLUG/data/eml-record-phrases.csv"
@emlRecordHeader: "Table lg", 56, 3, "16 August 2026, 00:00:00"

$FIXTURE_LG
table = selected ("Table")

@emlRunAnovaAnalysis: table, "val", "grp", 0

$LGFORM

@emlGraphsPublishAxisRequest
random_initializeWithSeedUnsafelyButPredictably (20260816)
@emlGraphsDrawWithLegendRoom
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/LEG_AFTER.png"

@emlRecordFlush: "$OUT/legend_after_emitted.praat"
@emlRecordDiscard
PRAAT
echo "# leg LEGEND after-analysis record" > "$OUT/legend_after.log"
run_praat "$OUT/legend_after_record.praat" "$OUT/legend_after.log"

lea="$OUT/legend_after_emitted.praat"
kv legend_after_abort "$(grep -c 'not performed or completed' "$OUT/legend_after.log")"
kv legend_after_all_steps  "$(grep -cE '^# --- Step [0-9]+ ' "$lea" 2>/dev/null || echo 0)"
kv legend_after_draw_steps "$(grep -cE '^# --- Step [0-9]+ \(draw\) ---$' "$lea" 2>/dev/null || echo 0)"
kv legend_after_analysis_steps "$(grep -cE '^# --- Step [0-9]+ \(analysis\) ---$' "$lea" 2>/dev/null || echo 0)"
kv legend_after_anova_calls "$(grep -c '^@emlRunAnovaAnalysis: data' "$lea" 2>/dev/null || echo 0)"
kv legend_after_draw_calls  "$(grep -c '^@emlDrawGroupedViolin: data' "$lea" 2>/dev/null || echo 0)"
kv legend_after_block_steps "$(sed -n 's/^axisYMin  *= .*-- run [0-9]*, \(steps\? .*\)$/\1/p' "$lea" | head -1)"
kv legend_after_block_run   "$(sed -n 's/^axisYMin  *= .*-- run \([0-9]*\), steps\? .*$/\1/p' "$lea" | head -1)"
kv legend_after_note "$(sed -n 's/^axisYMax  *= .*; on the recorded data it resolved to //p' "$lea" | head -1)"
# The draw's own heading number, so "step 2 (draw)" in the block is checked
# against the file rather than against itself.
kv legend_after_draw_heading "$(grep -oE '^# --- Step [0-9]+ \(draw\) ---$' "$lea" | head -1)"

# ---------------------------------------------------------------------------
printf '%-32s %s\n' "key" "value"
awk -F"\t" '{printf "%-32s %s\n", $1, $2}' "$TSV"
echo
echo "replay: wrote $(wc -l < "$TSV") measurements to $TSV"
# THIS SCRIPT DOES NOT DECIDE. Every verdict is in validate/v58, so the
# measurements and the expectations live apart and a break test can move one
# without editing the other.
exit 0

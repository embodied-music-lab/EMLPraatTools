# ============================================================================
# harness/linetree/drive.praat — the object, the entry point, and the report
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_LT_LEG. This file picks the table
# the leg is about, names the graph type, and hands over to
# @emlGraphsWorkflow. Everything after that call is the shipped form: page A,
# page B, page C, the refusals and the draw. run.sh presses the keys.
#
# WHY IT DOES NOT SET THE ANSWERS ITSELF. The thing under test is the QUESTION
# TREE -- which page appears, what it offers, and what follows from the
# answer. A probe that set tsSeriesRole and tsTick[] and called the dispatch
# would be testing its own decisions and would pass with the dialogs deleted.
# The one leg that does set globals directly is script_refuse.praat, and it
# does so because its subject is precisely the caller that has no dialog.
#
# WHAT IT WRITES AFTER THE WORKFLOW RETURNS. The workflow returns only when
# Done is pressed on the post-draw dialog, so a leg with no leg_returned row
# is a leg that hung or quit, and the validator can tell that from a leg that
# finished with the wrong figure. The variables read back are the form's own,
# after its dispatch -- not this file's copies of them.
#
# Env in:  EML_LT_LEG   leg name
#          EML_LT_OUT   TSV to append to
#          EML_LT_PNG   where to save the figure
#          EML_LT_INFO  where to dump the Info window
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
include fixture.praat

ltObjId = 0
if ltLeg$ = "subjects4"
    ltObjId = ltSubjects4Id
elsif ltLeg$ = "subjects_ci"
    ltObjId = ltGroupRepId
elsif ltLeg$ = "meas2"
    ltObjId = ltMeas2Id
elsif ltLeg$ = "none_refuse"
    ltObjId = ltMeas2Id
elsif ltLeg$ = "meas2_rep"
    ltObjId = ltMeas2RepId
elsif ltLeg$ = "meas3_refuse"
    ltObjId = ltMeas3Id
elsif ltLeg$ = "seven"
    ltObjId = ltSevenId
elsif ltLeg$ = "rec_subjects4"
    ltObjId = ltSubjects4Id
elsif ltLeg$ = "rec_meas2"
    ltObjId = ltMeas2Id
# THE LONG-SHAPE LEGS. Same meaning question, same right-hand axis, a table
# stored as one value column beside a name column. long_meas2 holds exactly
# the numbers meas2 holds, which is what makes the two figures comparable.
elsif ltLeg$ = "long_meas2"
    ltObjId = ltLongMeas2Id
elsif ltLeg$ = "long_meas3_refuse"
    ltObjId = ltLongMeas3Id
elsif ltLeg$ = "rec_long_meas2"
    ltObjId = ltLongMeas2Id
# THE TWO SHAPES, SIDE BY SIDE, WITH THE TITLE TAKEN OUT OF THE ARGUMENT.
# long_titled and wide_titled hold the same numbers in the two storages and
# are driven with the same keystrokes INCLUDING a typed title, because the
# composed title is the one thing that legitimately differs: it names the
# table the figure came from, and the two tables have different names. With
# the title typed, everything the two figures could differ in is data, and
# the two PNGs are required to be the same file.
elsif ltLeg$ = "long_titled"
    ltObjId = ltLongMeas2Id
elsif ltLeg$ = "wide_titled"
    ltObjId = ltMeas2Id
else
    exitScript: "linetree: unknown leg '" + ltLeg$ + "'"
endif

@ltEmit: "leg_object", string$ (ltObjId)

# ---------------------------------------------------------------------------
# THE RECORDER, ON FOR THE TWO LEGS THAT ARE ABOUT IT.
# ---------------------------------------------------------------------------
# WHY IT IS OFF EVERYWHERE ELSE. Six of the eight legs drive the form with no
# recording running, which is the state the `variableExists ("emlRecordLoaded")
# ... emlRecordActive = 1` guards in the draw layer exist for, and which is
# what a user who never pressed Start recording has. Turning it on for all of
# them would delete that coverage and would put two extra Tables in the
# Objects window of every leg, where @emlRecordSource's duplicate-name census
# walks them.
#
# THE TEMP FOLDER IS PASSED so the crash mirror is written: a leg that hangs
# mid-dialog still leaves a readable account of what had been recorded, which
# is the only artefact a killed Praat leaves behind.
#
# THE FLUSH IS AFTER THE WORKFLOW RETURNS, i.e. after Done was pressed on the
# post-draw dialog. That is where a user's "Stop recording" sits, and it is
# after the form has removed the melt table -- which is the whole subject of
# these two legs.
#
# THE PHRASE REGISTRY IS POINTED AT, and that is not decoration either.
# @emlRecordInit reads `../data/eml-record-phrases.csv`, which resolves
# against the folder of the script that was RUN -- plugin/scripts for every
# menu wrapper, and harness/linetree for this driver. Without the override
# every step in the emitted file reads
#
#     # [MISSING PHRASE: drawstep.intent]
#
# and what the leg measured would not be what a user gets. The override is
# the recorder's own seam (emlRecordPhrasePath$), not a harness invention.
if ltRec$ <> ""
    emlRecordPhrasePath$ = "../../plugin_EML_StatsGraphs/data/eml-record-phrases.csv"
    @emlRecordBegin: ltRecDir$
    @ltEmit: "rec_begun", string$ (emlRecordActive)
endif

emlGraphsPresetType = 5
selectObject: ltObjId
@emlGraphsWorkflow: ltObjId

# ---- reached only by pressing Done on the post-draw dialog ----------------
@ltEmit: "leg_returned", ltLeg$

# WHAT THE TREE CONCLUDED, read out of the form's own variables rather than
# restated here. seriesRole is the answer to page A; tsNSeries is how many
# tickboxes came back ticked; tsSecondColName$ is empty unless page C ran.
if tsSeriesRole = 2
    @ltEmit: "series_role", "measurements"
else
    @ltEmit: "series_role", "subjects"
endif
@ltEmit: "n_series", string$ (tsNSeries)
ltCols$ = ""
for ltI from 1 to tsNSeries
    if ltI > 1
        ltCols$ = ltCols$ + ","
    endif
    ltCols$ = ltCols$ + tsSeriesCol$[ltI]
endfor
@ltEmit: "series_cols", ltCols$
@ltEmit: "time_col", timeColName$
@ltEmit: "value_col", valueColName$
@ltEmit: "group_col", groupColName$
@ltEmit: "right_col", tsSecondColName$
@ltEmit: "second_axis", string$ (tsSecondAxis)
@ltEmit: "ci_accepted", string$ (tsShowCI)
@ltEmit: "repeats_found", string$ (tsRepeatsFound)
@ltEmit: "max_per_point", string$ (tsMaxPerPoint)
@ltEmit: "ci_offered", string$ (tsCIOffer)
@ltEmit: "shape", string$ (tsShape)
# THE LONG-SHAPE ARM, read out of the form's own variables. tsLevelMode is 1
# when the series are the LEVELS of a name column rather than the columns of a
# wide table; tsPivotTableId is the two-column table the pivot built, and it is
# 0 by the time this runs because the form removes it -- which is exactly why
# the recorder has to carry the pivot as a step of its own.
if variableExists ("tsLevelMode")
    @ltEmit: "level_mode", string$ (tsLevelMode)
else
    @ltEmit: "level_mode", "absent"
endif
if variableExists ("tsLevelNameCol$")
    @ltEmit: "level_name_col", tsLevelNameCol$
else
    @ltEmit: "level_name_col", "absent"
endif
if variableExists ("tsLongValueCol$")
    @ltEmit: "long_value_col", tsLongValueCol$
else
    @ltEmit: "long_value_col", "absent"
endif
@ltEmit: "n_numeric", string$ (tsNNum)
@ltEmit: "n_text", string$ (tsNTxt)
@ltEmit: "y_label", y_axis_label$

# ---- THE EMITTED SCRIPT ---------------------------------------------------
# Flushed here and not inside the form: the form has no Stop recording button,
# and the menu command that does is a separate script scope. This stands in
# for it, which is exactly what harness/vecfig/record_drive.praat does.
if ltRec$ <> ""
    @ltEmit: "rec_steps", string$ (emlRecordN)
    ; THE PHRASE TABLE IS AN OBJECT, and whether it got loaded is the
    ; difference between an emitted file a user could read and one whose every
    ; step says [MISSING PHRASE]. Recorded rather than assumed.
    @ltEmit: "rec_phrases", string$ (emlRecordPhraseId)
    @emlRecordFlush: ltRec$
    @ltEmit: "rec_written", string$ (emlRecordFlush.written)
endif

# ---- THE AXIS THE FIGURE WAS ACTUALLY DRAWN ON, AT FULL PRECISION ---------
# The emitted block carries the axis the USER ASKED FOR -- 0 and 0 for auto --
# and a comment naming what that resolved to, at four decimals. That is ruling
# 10(b) and it is deliberate: a replay retargeted at other data must not be
# frozen to this data's frame. It also means a plain replay of a figure whose
# legend negotiated room draws on the UN-widened axis, because the
# legend-room loop is the FORM's and not the recording's.
#
# So the replay is measured twice -- as emitted, and with the two numbers
# typed in -- and the second needs more precision than the block's comment
# carries. This is the draw procedure's own published extent, which is the
# same pair the comment rounds.
#
# string$ AND NOT fixed$, AND THE DIFFERENCE IS A WHOLE PIXEL. Measured on
# rec_meas2, 19 August 2026: the figure is sensitive to the ELEVENTH decimal
# of the axis ceiling. Replayed at fixed$ (x, 10) = 283.4960897780 the bottom
# tick label "180" lands one pixel lower than the session's; replayed at
# 283.49608977801 it does not, and the two files differ in 686 bytes-worth of
# glyph. Praat's string$ prints 17 significant digits and round-trips exactly
# -- number (string$ (x)) = x, measured on 6.6.30 -- so this is the pair the
# figure was drawn on and not a rounding of it.
#
# THE BLOCK'S OWN NOTE STAYS AT FOUR DECIMALS and that is right: it is prose
# for a reader, not a reconstruction key. What this row says is what the
# harness needs to make "byte for byte" a claim about the recorder rather
# than about fixed$.
if variableExists ("emlDrawTimeSeries.axisYMin")
    @ltEmit: "axis_y_min", string$ (emlDrawTimeSeries.axisYMin)
    @ltEmit: "axis_y_max", string$ (emlDrawTimeSeries.axisYMax)
endif

# THE FIGURE, AS THE PLUGIN SAYS IT SITS ON THE PAGE. emlDrawn* is the union
# the plugin itself tracks, and @emlAssertFullViewport selects it; a driver
# that chose its own viewport would photograph a crop of its own choosing.
@emlAssertFullViewport
@ltEmit: "drawn_union", string$ (emlDrawnMinX) + " " + string$ (emlDrawnMaxX)
... + " " + string$ (emlDrawnMinY) + " " + string$ (emlDrawnMaxY)
if ltPng$ <> ""
    Save as 300-dpi PNG file: ltPng$
endif

# THE INFO WINDOW VERBATIM. The disclosures the form prints -- the dropped
# time column, the repeated-observation notice, the second-axis refusal --
# are text, and they are recorded as text rather than transcribed from a
# screenshot. GUI_HARNESS_RECIPE §9.2: Praat writes this as UTF-16 on Linux,
# and run.sh sniffs before it reads.
if ltInfo$ <> ""
    writeFileLine: ltInfo$, info$ ()
endif

# ---------------------------------------------------------------------------
# vecfig/record_drive.praat -- a recording with two figures and two DIFFERENT
#                              format choices, and the replays of it
# ---------------------------------------------------------------------------
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT IS DRIVEN. The recorder's save path end to end: @emlSavePanel's emitted
# step, @emlRecordColumnManifest's lift of the format choice into the editable
# block, and @emlRecordReplaySave writing the figure through the panel's own
# writer. The question this rig exists to answer is the one a recording is
# kept for: tick EPS today, replay next month, is the EPS there.
#
# TWO SAVES, TWO DIFFERENT CHOICES, and that is the point rather than the
# decoration. One save proves a format survives; two prove the format is
# carried PER SAVE. A serialisation that flattened both into one variable
# would pass every single-save test and hand a session that saved one figure
# as EPS and another as PDF two copies of whichever was recorded last.
#
# THE SAVE STEP IS SYNTHESISED, AND SAYING SO IS THE POINT OF SAYING IT.
# @emlSavePanel records its own step from inside a `beginPause` dialog, and a
# pause form does not return without a display -- measured. So the two steps
# below are written here in the shape the panel writes them. That makes them
# a FIXTURE standing in for real emission, and a fixture that quietly stops
# matching its original is a test of nothing: validate/v86 re-reads the
# panel's emitter and compares the shape, exactly as validate/v58 does for the
# same fixture in harness/record.
#
# THE REPLAY IS A DIFFERENT PROCESS. run.sh includes the emitted file into a
# fresh Praat with the fixture rebuilt, because that is how a user runs it --
# and because a replay in the recording's own process would be reading
# variables the recording left behind rather than the file.
#
# Output: key<TAB>value into $EML_VECFIG_TSV, plus the emitted script itself
#         under $EML_VECFIG_REC for run.sh to read, edit and run.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------

include plugin/stats/eml-core-utilities.praat
include plugin/stats/eml-core-descriptive.praat
include plugin/stats/eml-extract.praat
include plugin/stats/eml-output.praat
include plugin/stats/eml-inferential.praat
include plugin/stats/eml-result-writer.praat
include plugin/stats/eml-record.praat
include plugin/graphs/eml-graph-procedures.praat
include plugin/graphs/eml-annotation-procedures.praat
include plugin/graphs/eml-draw-procedures.praat
include plugin/stats/eml-analysis.praat

# EVERY FILE THIS DRIVE WRITES IS UTF-8. Praat converts a file to UTF-16 the
# moment a non-ASCII character is written into it, and a validator reading a
# UTF-16 TSV sees keys with NULs between the letters -- indistinguishable from
# a harness that never ran.
Text writing preferences: "UTF-8"

@emlInitDrawingDefaults
@emlClearAnnotations

tsv$ = environment$ ("EML_VECFIG_TSV")
rec$ = environment$ ("EML_VECFIG_REC")
root$ = environment$ ("EML_VECFIG_ROOT")
saveTo$ = environment$ ("EML_VECFIG_SAVEDIR")

procedure emit: .key$, .value$
    appendFile: tsv$, "rec_", .key$, tab$, .value$, newline$
endproc

# THE FIXTURE, seeded, because run.sh rebuilds the same table in the replay's
# own process: the emitted script selects its object by NAME through the
# block, and a name resolves to nothing in a fresh Praat.
t = Create Table with column names: "vt", 0, "grp val"
st = 20260817
r = 0
for g from 1 to 3
    for k from 1 to 20
        st = (1103515245 * st + 12345) mod 2147483648
        r = r + 1
        Append row
        Set string value: r, "grp", "G" + string$ (g)
        Set numeric value: r, "val",
        ... 200 + g * 18 + (st / 2147483648 - 0.5) * 80
    endfor
endfor
table = selected ("Table")

@emlRecordInit
emlRecordPluginRoot$ = root$ + "/plugin"
@emlRecordBegin: rec$
emlRecordPluginRoot$ = root$ + "/plugin"
@emlRecordLoadPhrases: root$ + "/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "vt", 60, 2, "vecfig"

# ---------------------------------------------------------------------------
# STEP 1 -- a figure
# ---------------------------------------------------------------------------
Erase all
@emlDrawViolinPlot: table, "first figure", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0

# ---------------------------------------------------------------------------
# STEP 2 -- its save, asking for EPS
# ---------------------------------------------------------------------------
# The shape is @emlSavePanel's: the folder on its own line as a variable, then
# the call, with the format choice as the fourth argument.
@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + saveTo$ + """" + newline$
... + "@emlSavePanel: 1, ""figA_20260817_120000"", outputFolder$, ""PNG, EPS""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

# ---------------------------------------------------------------------------
# STEP 3 -- a second figure, and it is a SECOND RUN
# ---------------------------------------------------------------------------
# One pass through the graphs form and the save that belongs to it is one run,
# and the recorder names the emitted block's variables by it. The form marks
# the boundary at the top of each pass; this driver stands in for the form, so
# it marks it here -- without that, a driver that presses Draw twice would be
# describing one press to the recorder.
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: table, "second figure", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 300

# ---------------------------------------------------------------------------
# STEP 4 -- its save, asking for PDF instead
# ---------------------------------------------------------------------------
@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + saveTo$ + """" + newline$
... + "@emlSavePanel: 1, ""figB_20260817_120000"", outputFolder$, ""PNG, PDF""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

@emlRecordFlush: rec$ + "/emitted.praat"
@emit: "flushed", string$ (emlRecordFlush.written)
; NOT "finished": validate/v86 censuses the format legs by looking for keys
; spelled <leg>_finished, and this leg is not one of them -- it is asserted on
; by its own section. A key that joined that census would report a leg the
; table does not list.
@emit: "complete", "1"

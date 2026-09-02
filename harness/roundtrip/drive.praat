# ============================================================================
# harness/roundtrip/drive.praat — one session, eight user actions, one recording
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE PRAAT PROCESS. eml-record-start.praat's own header states the limit:
# `praat --run` starts a fresh process per script, so a recording cannot span
# invocations. Every action below therefore happens inside this one session,
# and the ones that a user reaches through a menu are reached through
# `runScript:` — which gives a script its OWN variable scope inside ONE
# process, exactly as a menu command gets. harness/record_e2e established
# that shape; this file is the eight-action journey rather than a sweep.
#
# WHAT IS RUN, IN ORDER, AND BY WHAT ROUTE
#
#   0. START      runScript: "eml-record-start.praat"   — the shipped wrapper.
#                 The START wrapper IS script-callable. The STOP and SAVE
#                 wrappers are not: `runScript: "eml-record-save.praat"` after
#                 a live recording aborts Praat 6.6.30 at its beginPause with
#                 SIGTRAP (shell exit 133). So the recording is stopped and
#                 saved from a script with @emlRecordFlush + @emlRecordDiscard,
#                 which is what those wrappers call underneath.
#   1. create_demo  runScript: the headless twin of eml-create-demo.praat
#   2. load_file    Read Table from comma-separated file: — Praat's own Open.
#                   MEASURED: setup.praat registers no CSV loader of its own
#                   (43 Add menu/action commands, none of them a reader), so
#                   this is the only route a user has to a table on disk.
#   3. edit_cell    runScript: the headless twin of eml-edit-table.praat
#   4. refusal      @emlRunAnovaAnalysis with the speaker column in the Data
#                   slot -- the wrong column, picked the way a user picks it.
#                   THE ONE ACTION THAT IS NOT REACHED THROUGH ITS WRAPPER,
#                   and the reason is in the wrapper rather than here: a
#                   refused analysis lands in @emlErrorDialog, whose region
#                   holds two `endPause` lines on opposite arms of an `if`,
#                   and run.sh refuses to excise a region like that. The
#                   orchestrator IS the call the wrapper makes, one line above
#                   the dialog, and it is the call that records the step. What
#                   is not exercised is the wrapper's error window.
#   5. analysis     runScript: the headless twin of eml-compare-k-groups.praat
#   6. draw         inside that wrapper, at its Draw button's call site
#   7. save         inside that wrapper, its Save button -> @emlSavePanel
#   8. convert      @emlConvertForGraph on a mono Sound, with the two pitch
#                   arguments the form passes it (eml-graphs-form.praat:3940,
#                   prev_f0_pitchFloor and prev_f0_pitchCeiling * 2). The
#                   form's acquire path is a `beginPause:` loop, so what is
#                   driven is the procedure that path calls -- the same
#                   substitution, and for the same reason, as the draw chain.
#
# WHY 4 AND 8 ARE HERE AT ALL. The recorder can express seven step kinds and
# the other six actions produce five of them. A recording that never exercises
# a kind says nothing about it, and `convert` and `refusal` are exactly the two
# a session built out of tables cannot reach by accident.
#
# WHY 4, 5 AND 6 SHARE ONE SCOPE, AND WHY THAT IS THE FAITHFUL ARRANGEMENT
# RATHER THAN A CONVENIENCE. @emlSavePanel decides whether there is anything
# to write by reading emlResult_declared / emlCSV_n and the drawn-extent union
# — all of them SCRIPT-SCOPE globals. A `runScript:`ed script does not hand
# its variables back, so a save called from this driver after the wrapper
# returned would find no results and no figure and write nothing. The plugin
# is built the other way round: every one of the thirteen wrappers calls
# @emlSavePanel from inside its own Done | Save | Draw | New loop, and
# eml-output.praat's own note says why the panel also asks the PAGE — "a
# wrapper's Draw button sends the user into the graphs workflow and RETURNS to
# the same loop, so the very next Save was a 0 standing over a figure". This
# drive walks exactly that path: Run, then Draw, then Save, one loop, one
# scope, results and figure in one press.
#
# THE ADVERSARIAL EDIT. The CSV holds three cohorts whose f0 columns do not
# overlap (alpha 100..107, bravo 300..307, charlie 900..907) and the editor
# writes 4242 into row 1. That single cell moves cohort alpha's mean from
# 103.5 to 621.25 and its SD from 2.4 to about 1465, so the ANOVA's F falls
# by orders of magnitude. A replay that skips the edit, or an analysis that
# silently ran on the demo table instead, cannot land on the same numbers by
# accident.
#
# Env in:
#   EML_RT_OUT      artefact folder (emitted script, saved outputs)
#   EML_RT_CSV      the adversarial CSV to load
#   EML_RT_PLUGIN   absolute plugin root to write into the emitted include block
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
include eml-lib.praat

@emlInitializeDrawingDefaults

rtOut$ = environment$ ("EML_RT_OUT")
rtCsv$ = environment$ ("EML_RT_CSV")
rtPlug$ = environment$ ("EML_RT_PLUGIN")

writeInfoLine: "RT|begin|", rtOut$

# ===========================================================================
# 0. START THE RECORDING — the shipped wrapper, pressed
# ===========================================================================
runScript: "eml-record-start.praat"

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStarted = numberOfSelected ()
appendInfoLine: "RT|record_started|", rtStarted

# RE-ATTACH IN THIS SCOPE AND THEN OVERRIDE THE PLUGIN ROOT.
#
# @emlRecordBegin ran inside the wrapper's scope and stamped the meta table
# with a root derived from preferencesDirectory$ — which under --pref-dir is
# this harness's throwaway prefs folder, not a plugin anyone can include. The
# assignment below is the seam harness/record/replay.sh uses for the same
# reason: @emlRecordInit fills emlRecordPluginRoot$ from the meta table only
# `if not variableExists`, so setting it first wins, and the renderer's own
# tilde substitution runs again over whatever it is handed.
#
# AND IT IS DELIBERATELY *NOT* PRECEDED BY @emlRecordInit, WHICH COST AN
# AFTERNOON. MEASURED, 21 August 2026, eml-record.praat:190-198: the buffer's
# row count is copied into emlRecordN only on the branch that ATTACHES —
# `if emlRecordBufferId = 0`. A scope that calls @emlRecordInit before the
# first step is recorded therefore pins emlRecordN at 0 for the rest of its
# life, and since every step here is added in some OTHER scope, the flush at
# the end of this file saw `emlRecordN < 1`, wrote nothing, and returned
# written = 0 with no error anywhere. The shipped GUI never meets this: every
# menu command is a fresh scope, so eml-record-save.praat always attaches
# cold. A one-scope headless driver is the only thing that can, and the cure
# is simply to leave the first @emlRecordInit to the flush.
emlRecordPluginRoot$ = rtPlug$

# ===========================================================================
# 1. create_demo — the plugin's demo generator
# ===========================================================================
# SEEDED, because the generator is randomGauss throughout and an artefact this
# harness commits must not change on every run.
random_initializeWithSeedUnsafelyButPredictably (20260821)
runScript: "_rt_create_demo.praat"

rtDemoRows = -1
rtDemoCols = -1
nocheck selectObject: "Table demo_3groups"
rtDemo = numberOfSelected ()
if rtDemo = 1
    rtDemoRows = Get number of rows
    rtDemoCols = Get number of columns
endif
appendInfoLine: "RT|create_demo|", rtDemo, "|", rtDemoRows, "|", rtDemoCols

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStepsAfter1 = -1
if numberOfSelected () = 1
    rtStepsAfter1 = Get number of rows
endif
appendInfoLine: "RT|steps_after|create_demo|", rtStepsAfter1

# ===========================================================================
# 2. load_file — a table read from a CSV on disk
# ===========================================================================
rtTable = 0
rtLoaded = 0
if fileReadable (rtCsv$)
    Read Table from comma-separated file: rtCsv$
    rtTable = selected ("Table")
    rtLoaded = 1
endif
rtLoadRows = -1
rtLoadCols = -1
rtLoadName$ = "<none>"
if rtLoaded = 1
    selectObject: rtTable
    rtLoadRows = Get number of rows
    rtLoadCols = Get number of columns
    rtLoadName$ = selected$ ()
endif
appendInfoLine: "RT|load_file|", rtLoaded, "|", rtLoadRows, "|", rtLoadCols,
... "|", rtLoadName$

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStepsAfter2 = -1
if numberOfSelected () = 1
    rtStepsAfter2 = Get number of rows
endif
appendInfoLine: "RT|steps_after|load_file|", rtStepsAfter2

# ===========================================================================
# 3. edit_cell — the Table editor, driven through its own code
# ===========================================================================
selectObject: rtTable
rtCellBefore$ = Get value: 1, "f0_Hz"
appendInfoLine: "RT|cell_before|", rtCellBefore$

selectObject: rtTable
runScript: "_rt_edit_table.praat", "editor"

selectObject: rtTable
rtCellAfter$ = Get value: 1, "f0_Hz"
rtEdited = 0
if rtCellAfter$ <> rtCellBefore$
    rtEdited = 1
endif
appendInfoLine: "RT|edit_cell|", rtEdited, "|", rtCellAfter$

# The whole column, so a reader can see the edit is the ONLY change.
selectObject: rtTable
rtAlphaMean = Get mean: "f0_Hz"
appendInfoLine: "RT|table_mean_after_edit|", fixed$ (rtAlphaMean, 6)

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStepsAfter3 = -1
if numberOfSelected () = 1
    rtStepsAfter3 = Get number of rows
endif
appendInfoLine: "RT|steps_after|edit_cell|", rtStepsAfter3

# ===========================================================================
# 4. refusal — the wrong column in the Data slot
# ===========================================================================
# speaker holds A01..C08, so @emlRequireNumericColumn refuses and
# @emlRunAnovaAnalysis returns with .error$ set. @emlRecordAnova, which the
# orchestrator calls on both arms, writes a `refusal` step carrying the
# sentence rather than dropping the attempt: a log that shows only the
# analyses that worked lies by omission.
selectObject: rtTable
@emlRunAnovaAnalysis: rtTable, "speaker", "cohort", 1
rtRefusal$ = emlRunAnovaAnalysis.error$
rtRefused = 0
if rtRefusal$ <> ""
    rtRefused = 1
endif
appendInfoLine: "RT|refusal|", rtRefused, "|", rtRefusal$

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStepsAfter4 = -1
if numberOfSelected () = 1
    rtStepsAfter4 = Get number of rows
endif
appendInfoLine: "RT|steps_after|refusal|", rtStepsAfter4

# ===========================================================================
# 5, 6, 7 — analysis, draw and save, through the wrapper's own loop
# ===========================================================================
selectObject: rtTable
runScript: "_rt_compare_k.praat"

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStepsAfter6 = -1
if numberOfSelected () = 1
    rtStepsAfter6 = Get number of rows
endif
appendInfoLine: "RT|steps_after|analysis_draw_save|", rtStepsAfter6

# ===========================================================================
# 8. convert — a Sound asked for as a figure the Sound cannot draw
# ===========================================================================
# ONE CHANNEL, so @emlGraphsChannelGate passes it through untouched: the gate
# only asks a question of a Sound with two or more channels, and a dialog here
# would take the process down. The Sound is built by formula so the Spectrum
# is the same Spectrum on every run.
Create Sound from formula: "rt_tone", 1, 0, 0.5, 44100, "0.5 * sin (2 * pi * 220 * x)"
rtSound = selected ("Sound")
rtSoundName$ = selected$ ()

@emlConvertForGraph: rtSound, "Spectrum", 50, 800
rtConverted = 0
rtConvertName$ = "<none>"
if emlConvertForGraph.result > 0
    rtConverted = 1
    selectObject: emlConvertForGraph.result
    rtConvertName$ = selected$ ()
endif
appendInfoLine: "RT|convert|", rtConverted, "|", rtSoundName$, "|",
... rtConvertName$, "|", emlConvertForGraph.temporary

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtStepsAfter8 = -1
if numberOfSelected () = 1
    rtStepsAfter8 = Get number of rows
endif
appendInfoLine: "RT|steps_after|convert|", rtStepsAfter8

# ===========================================================================
# STOP AND SAVE THE RECORDING
# ===========================================================================
# @emlRecordFlush writes the script and does NOT end the session;
# @emlRecordDiscard ends it. That pair is what eml-record-save.praat does
# either side of its dialog, and it is the only route a script has, because
# the wrapper itself takes the process down at its beginPause.
rtEmit$ = rtOut$ + "/emitted.praat"
@emlRecordFlush: rtEmit$
appendInfoLine: "RT|flush|", emlRecordFlush.written, "|", rtEmit$

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtBufferBeforeDiscard = numberOfSelected ()
@emlRecordDiscard
nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
rtBufferAfterDiscard = numberOfSelected ()
appendInfoLine: "RT|discard|", rtBufferBeforeDiscard, "|",
... rtBufferAfterDiscard

appendInfoLine: "RT|end|ok"

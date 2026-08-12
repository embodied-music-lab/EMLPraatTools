# ============================================================================
# EML Praat Tools — Save recorded script
# ============================================================================
# Purpose: render the recording started by 'Start recording script' to a
#          runnable Praat file, and end the session.
# Date: 12 August 2026
# Version: 1.0
#
# WHY SAVING AND ENDING ARE ONE COMMAND, AND WHY THERE IS STILL A CHOICE.
# @emlRecordFlush deliberately does NOT end the recording — the proposal asks
# for flush on demand as well as flush on stop, and a flush that silently
# ended the session would make the on-demand case a trap. That decision lives
# in the recorder and is not overridden here; instead the DIALOG asks, so the
# user says which they meant rather than discovering it afterwards.
#
# NOTHING RECORDED IS NOT AN ERROR. Starting a recording and saving without
# running an analysis is a reasonable thing to do by accident, and the right
# response is to say so plainly and leave the session alone.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy.
# ============================================================================

include eml-lib.praat

@emlRecordInit

if emlRecordActive = 0
    writeInfoLine: "EML: no recording is in progress."
    appendInfoLine: ""
    appendInfoLine: "Run 'Start recording script' first, then the analyses"
    appendInfoLine: "and figures you want captured."
    goto END_RECORD_SAVE
endif

selectObject: emlRecordBufferId
nSteps = Get number of rows

if nSteps = 0
    beginPause: "Nothing recorded yet"
        comment: "The recording is running but no analysis has been"
        comment: "captured yet, so there is nothing to save."
    clicked = endPause: "Keep recording", "Stop recording", 1, 1
    if clicked = 2
        @emlRecordDiscard
        writeInfoLine: "EML: recording stopped. Nothing was saved."
    endif
    goto END_RECORD_SAVE
endif

# The default folder is the one the graphs form last saved a figure into when
# that is known, so a session's script lands beside its figures rather than
# wherever Praat happened to start.
defaultFolder$ = homeDirectory$
if variableExists ("config_lastPNGFolder$")
    if config_lastPNGFolder$ <> ""
        defaultFolder$ = config_lastPNGFolder$
    endif
endif

beginPause: "Save recorded script"
    comment: "Recorded " + string$ (nSteps) + " step(s)."
    word: "File name", "eml_recorded_workflow.praat"
    folder: "Folder", defaultFolder$
    comment: "Keep recording after saving, or stop the session?"
    boolean: "Stop recording after saving", 1
clicked = endPause: "Cancel", "Save", 2, 1

if clicked = 1
    goto END_RECORD_SAVE
endif

name$ = file_name$
if name$ = ""
    name$ = "eml_recorded_workflow.praat"
endif
if right$ (name$, 6) <> ".praat"
    name$ = name$ + ".praat"
endif
outPath$ = folder$ + "/" + name$

# Non-destructive, the same rule the figure save path follows: an existing
# file is never overwritten silently.
if fileReadable (outPath$)
    @emlGenerateUniquePath: outPath$
    outPath$ = emlGenerateUniquePath.result$
endif

@emlRecordFlush: outPath$

if emlRecordFlush.written = 0
    writeInfoLine: "EML: nothing was written."
    goto END_RECORD_SAVE
endif

writeInfoLine: "EML: recorded script saved."
appendInfoLine: ""
appendInfoLine: outPath$
appendInfoLine: ""
appendInfoLine: string$ (nSteps), " step(s) written."

if stop_recording_after_saving = 1
    @emlRecordDiscard
    appendInfoLine: "Recording stopped."
else
    appendInfoLine: "Still recording — later steps will be added to the next save."
endif

label END_RECORD_SAVE

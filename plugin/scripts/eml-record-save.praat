# ============================================================================
# EML Praat Tools — Stop recording and save
# ============================================================================
# Purpose: render the recording started by 'Record script' to a runnable Praat
#          file at a place the user chooses, and end the session.
# Date: 13 August 2026
# Version: 2.0
#
# THE MENU ITEM NAME IS THE CONTRACT. Author ruling, 13 August 2026: three
# commands — 'Record script', 'Stop recording and open', 'Stop recording and
# save' — each saying in its own name what it does. So the "Stop recording
# after saving" tickbox this file used to carry is gone: a user who picked a
# command called 'Stop recording and save' has already answered that question,
# and asking again is the dialog second-guessing the menu.
#
# @emlRecordFlush still does NOT end the recording on its own — flush on
# demand is a separate capability that lives in the recorder and is not
# overridden here. Ending the session is this FILE's decision, made once,
# after the write succeeds.
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
    appendInfoLine: "Run 'Record script' first, then the analyses and"
    appendInfoLine: "figures you want captured."
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

beginPause: "Stop recording and save"
    comment: "Recorded " + string$ (nSteps) + " step(s)."
    comment: "The recording ends when this is saved."
    word: "File name", "eml_recorded_workflow.praat"
    folder: "Folder", defaultFolder$
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

# THE RECORDING ENDS AFTER THE WRITE, never before it: a failed write must
# leave the session intact, or a full disk costs the user the whole recording.
@emlRecordDiscard
appendInfoLine: "Recording stopped."
appendInfoLine: ""
appendInfoLine: "To read or edit it now, use 'Stop recording and open'"
appendInfoLine: "next time — it puts the script straight into an editor."

label END_RECORD_SAVE

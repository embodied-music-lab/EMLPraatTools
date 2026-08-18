# ============================================================================
# EML Stats & Graphs — Stop recording and save
# ============================================================================
# Purpose: render the recording started by 'Record script' to a runnable Praat
#          file at a place the user chooses, and end the session.
# Date: 13 August 2026
# Version: 2.0
#
# THE MENU ITEM NAME IS THE CONTRACT. Three
# commands — 'Record script', 'Stop recording and open', 'Stop recording and
# save' — each saying in its own name what it does. So the "Stop recording
# after saving" tickbox has no place here: a user who picked a
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
    # The same distinction 'Stop recording and open' makes, and for the same
    # reason: a recording that ended because its buffer was removed from the
    # Objects window leaves the meta table behind, and that is the only trace
    # there is. Saying so is the difference between "you never started one"
    # and "yours stopped at some point and nothing told you".
    @emlRecordOrphanCheck
    if emlRecordOrphanCheck.orphan = 1
        writeInfoLine: "EML: the recording ended when its buffer was removed."
        appendInfoLine: ""
        appendInfoLine: "'Table emlRecording_DO_NOT_REMOVE' is gone from the"
        appendInfoLine: "Objects window — that table IS the recording, so"
        appendInfoLine: "removing it stopped it. Anything run since was not"
        appendInfoLine: "captured and cannot be recovered."
        appendInfoLine: ""
        appendInfoLine: "Run 'Record script' to start again."
        goto END_RECORD_SAVE
    endif
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

# ONE PLUGIN, ONE NAMING SCHEME (audit §6, fixed 14 August 2026).
#
# This dialog does not propose a bare "eml_recorded_workflow.praat" and
# resolve a collision AFTER the press, silently, by appending _1. The Save
# panel in stats/eml-output.praat resolves the same question the other way and
# does: it proposes a STAMPED name in
# the dialog, so the user sees the name they are about to get, one stamp per
# press shared by every file that press writes, and the numeric suffix is only
# a backstop for the case a stamp cannot separate. Two schemes in one plugin
# is one scheme too many, and this is the junior of the two: the panel's rule
# is the author's, it is the one v51 already pins, and it is the one that
# sorts chronologically in a file browser.
#
# So the stamp is taken ONCE, here, before the dialog -- @emlFileStamp is
# called exactly once per press for exactly that reason -- and it arrives in
# an editable field, which is where a user who does not want it deletes it.
@emlFileStamp
proposed$ = "eml_recorded_workflow_" + emlFileStamp.result$ + ".praat"

beginPause: "Stop recording and save"
    comment: "Recorded " + string$ (nSteps) + " step(s)."
    comment: "The recording ends when this is saved."
    word: "File name", proposed$
    folder: "Folder", defaultFolder$
clicked = endPause: "Cancel", "Save", 2, 1

if clicked = 1
    goto END_RECORD_SAVE
endif

name$ = file_name$
if name$ = ""
    name$ = proposed$
endif
if right$ (name$, 6) <> ".praat"
    name$ = name$ + ".praat"
endif

# THE FOLDER IS MADE, AND MADE ALL THE WAY DOWN.
#
# `folder:` is a freely editable text field with a Browse button beside it, so
# a user can type a path that does not exist yet -- and typing one is the
# natural thing to do when you want this session's script in its own place.
# Without a createFolder: here, an ordinary path walks straight into
# what that costs: Praat's own abort, quoting the plugin's internals
#
#     Script line 15215 not performed or completed:
#     « writeFileLine: .outPath$, emlRecordRender.text$ »
#     ... or click Cancel in that window.
#
# -- raw source at the user, and an instruction pointing at a pause window
# that had already closed. The panel has done this correctly since 13 August;
# this command diverged from it.
#
# AND createFolder: IS mkdir, NOT mkdir -p. Measured on 6.6.30, 14 Aug 2026:
# handed a path whose parents are absent it creates nothing. So the ancestors
# are walked explicitly -- @emlRecordMakeFolder in stats/eml-record.praat.
outFolder$ = folder$
while endsWith (outFolder$, "/") and length (outFolder$) > 1
    outFolder$ = left$ (outFolder$, length (outFolder$) - 1)
endwhile
@emlRecordMakeFolder: outFolder$

# ASKED, NOT ASSUMED. A folder can be unmakeable (a read-only mount, a
# permission the user does not have, a path element that is really a file)
# and the flush is the wrong place to find out: @emlRecordFlush's writeFileLine
# aborts the script, and an abort here would end the session that the whole
# command exists to preserve. So the target is probed with a real write first,
# and a refusal is a sentence rather than a stack trace.
probe$ = outFolder$ + "/.eml_record_write_probe"
nocheck deleteFile: probe$
nocheck writeFileLine: probe$, "eml"
if not fileReadable (probe$)
    writeInfoLine: "EML: that folder cannot be written to."
    appendInfoLine: ""
    appendInfoLine: outFolder$
    appendInfoLine: ""
    appendInfoLine: "Nothing was saved and the recording is STILL RUNNING —"
    appendInfoLine: "no steps were lost. Run 'Stop recording and save' again"
    appendInfoLine: "and choose a folder you can write to, or use"
    appendInfoLine: "'Stop recording and open' to get the script into an"
    appendInfoLine: "editor and save it from there."
    goto END_RECORD_SAVE
endif
nocheck deleteFile: probe$

outPath$ = outFolder$ + "/" + name$

# Non-destructive, the same rule the figure save path follows: an existing
# file is never overwritten silently. A BACKSTOP, not the naming scheme --
# the stamp above is what normally separates two saves, and this catches the
# two cases a stamp cannot: two presses inside one second, and a user who
# deleted the stamp out of the field and reused a name.
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

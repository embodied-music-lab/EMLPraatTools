# ============================================================================
# EML Stats & Graphs — Start recording a script
# ============================================================================
# Purpose: begin a recording session. Every EML analysis, figure and table
#          edit run after this, until the session is saved, is captured as one
#          runnable Praat script. The message it prints states at the outset
#          what the recorder can and cannot capture, and how to recover the
#          one kind of change it cannot.
# Date: 21 August 2026
# Version: 1.1
#
# HOW THE SESSION SURVIVES BETWEEN MENU COMMANDS, which is the only
# interesting thing about this file. A script run from a menu ends and takes
# every variable it set with it — emlRecordActive and emlRecordBufferId are
# gone before the next analysis starts. What does NOT end is the Objects
# window, which belongs to the running Praat instance.
#
# So the recording lives in an object: a Table named
# emlRecording_DO_NOT_REMOVE, created here and read by @emlRecordInit at the
# top of every later step. Its EXISTENCE is the state. There is no flag file
# and no preference key, which means there is nothing that can drift out of
# agreement with the data — the switch and the buffer are the same object.
#
# One consequence worth stating rather than hiding: the buffer is visible in
# the user's Objects window, and removing it there ends the recording. That is
# a reasonable thing for it to mean, and it is what the dialog says.
#
# WHICH IS WHY THE OBJECT IS CALLED WHAT IT IS CALLED. A name like
# emlRecordBuffer reads as scratch — the one thing it is not. There is no
# per-step signal, so the message below and the name
# in the Objects list are the entire warning, and the name is the half that is
# in front of the user at the moment the mistake is available to them.
#
# NOT AVAILABLE HEADLESS. `praat --run` starts a fresh process per script, so
# objects do not persist between invocations and a recording cannot span them.
# Recording is a GUI feature; a headless harness must drive one Praat session.
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

if emlRecordActive = 1
    # ALREADY RECORDING. The buffer is not silently replaced: a session in
    # progress may hold work the user has not saved, and starting over is a
    # destructive act that has to be chosen.
    selectObject: emlRecordBufferId
    nSoFar = Get number of rows

    beginPause: "Already recording"
        comment: "A recording is already in progress with " + string$ (nSoFar)
        ... + " step(s)."
        comment: "Continue it, or discard it and start again?"
    clicked = endPause: "Continue recording", "Discard and restart", 1, 1

    if clicked = 1
        writeInfoLine: "EML: still recording — ", nSoFar, " step(s) so far."
        appendInfoLine: "Finish with 'Stop recording and open' or"
        appendInfoLine: "'Stop recording and save'."
        goto END_RECORD_START
    endif
    @emlRecordDiscard
endif

@emlRecordBegin: ""

# NOTHING IS SELECTED WHEN RECORDING STARTS.
# @emlRecordBegin leaves the recording's own buffer table selected, because
# that is the object it just wrote to. That table is never what the user
# wants to work on next — it is bookkeeping — and a selected object is an
# invitation: the next menu command they run would act on it. Clear the
# selection so the first thing they pick is the thing they meant to pick.
nocheck selectObject ( )

writeInfoLine: "EML: recording started."
appendInfoLine: ""
appendInfoLine: "Every EML analysis, figure and table edit from now on is"
appendInfoLine: "added to one script. Finish with 'Stop recording and open'"
appendInfoLine: "to read it in an editor, or 'Stop recording and save' to"
appendInfoLine: "file it directly."
appendInfoLine: ""
# WHAT THIS RECORDER CAN AND CANNOT SEE, SAID AT THE START.
#
# A recorder that only reports its limits when the session ends has told the
# user too late to act on it: by then the work is done and the gap between
# the script and what happened is already in the file. Said here, it is a
# choice the user can still make -- edit through EML's own editor rather than
# Praat's, keep a stray script out of the session -- which is the whole
# reason it is at the start rather than at the flush.
#
# THE THREE CASES ARE MEASURED, not assumed, and the measurements are in
# harness/GUI_HARNESS_RECIPE.md §12.3 to §12.5. An action taken through this
# plugin's own dialogs is captured. A hand edit committed in Praat's native
# TableEditor is not -- it never enters the interpreter, and no script can
# read Praat's command history -- but it DOES enter that history in
# replayable syntax, so it is recoverable by hand and the way to recover it
# is named. Work done by a foreign script is in neither place.
#
# THE ONE RECOVERABLE CASE GETS THE INSTRUCTION, and the other does not,
# because there is nothing to instruct: naming a remedy that does not exist
# would be worse than saying plainly that there is none.
appendInfoLine: "WHAT GOES INTO IT, AND WHAT DOES NOT:"
appendInfoLine: ""
appendInfoLine: "    Recorded — anything you do through an EML command:"
appendInfoLine: "        analyses, figures, saves, and changes you make"
appendInfoLine: "        in EML's own 'EML: Edit Table...' window."
appendInfoLine: ""
appendInfoLine: "    Not recorded — a cell you type into Praat's own"
appendInfoLine: "        table window, and anything a script of your own"
appendInfoLine: "        does to your data."
appendInfoLine: ""
appendInfoLine: "An edit made in Praat's own table window can still be"
appendInfoLine: "got back by hand: open a script window and choose"
appendInfoLine: "Edit > Paste history. Praat writes out what you did in a"
appendInfoLine: "form that runs, and you can paste it into the recorded"
appendInfoLine: "script where it belongs. Work done by a script of your"
appendInfoLine: "own leaves no trace in either place."
appendInfoLine: ""
appendInfoLine: "To keep the whole session reproducible, edit your tables"
appendInfoLine: "through 'EML: Edit Table...' and they are recorded with"
appendInfoLine: "everything else."
appendInfoLine: ""
# BOTH TABLES ARE NAMED, because both are visible.
#
# This message does not stop at naming the buffer, because the Objects
# window filled with emlRecordMeta as well — and, after the first recorded
# step, the shipped phrase table too. A user looking at three unexplained
# objects with the plugin's prefix on them has been told about one of them,
# which is worse than being told about none: it reads as though the other two
# arrived from somewhere else.
appendInfoLine: "Two Tables now sit in the Objects window:"
appendInfoLine: ""
appendInfoLine: "    emlRecording_DO_NOT_REMOVE"
appendInfoLine: "        the steps — this IS the recording, and removing it"
appendInfoLine: "        ends the session, which is why it is named that way"
appendInfoLine: "    emlRecordMeta"
appendInfoLine: "        when it started and what it ran on"
appendInfoLine: ""
appendInfoLine: "A third, 'eml-record-phrases', appears after the first step;"
appendInfoLine: "it is the shipped wording the script is written from. Leave"
appendInfoLine: "all three alone and they are cleaned up when you stop."
appendInfoLine: ""
appendInfoLine: "'Stop recording and open' puts the script in an editor and"
appendInfoLine: "keeps a review copy at:"
appendInfoLine: preferencesDirectory$ + "/eml-recorded-scripts"

label END_RECORD_START

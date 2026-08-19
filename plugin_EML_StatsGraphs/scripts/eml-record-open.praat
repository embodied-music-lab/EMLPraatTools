# ============================================================================
# EML Stats & Graphs — Stop recording and open
# ============================================================================
# Purpose: end the recording started by 'Record script' and put the resulting
#          script in front of the user in a Praat ScriptEditor, where it can
#          be read, edited, run, and saved wherever they like.
# Date: 13 August 2026
# Version: 1.0
#
# WHY THIS IS NOT PRINTED TO THE INFO WINDOW.
# The recorded script must NEVER be written into the Info window. That window
# holds the analysis reports — it is the thing 'Save Info' writes and the
# thing a user copies into a paper — and a script dumped into it destroys the
# deliverable. The Info window is append-only by design (see the REPORT
# PROVENANCE note in stats/eml-output.praat), so there is no undo for that.
#
# HOW A SCRIPT GETS INTO AN EDITOR, which took three wrong guesses to find.
# Praat's own documentation for `Read from file...` says:
#
#     "Read from file... recognizes script files if they begin with #!"
#
# So `Read from file:` on a file whose first two characters are `#!` raises a
# ScriptEditor titled  Script "<path>" . @emlRecordRender emits that line, and
# eml-record.praat's header records the measurement.
#
# WHAT DOES NOT WORK, so nobody tries them again:
#   * `Open Praat script: "<path>"` opens an EMPTY editor and then a file
#     chooser, ignoring the path it was handed, and blocks on the chooser.
#   * `New Praat script` opens an empty editor and returns. No way to put
#     text in it.
#   * `Open Praat script from file:` is not a command. It was invented.
# All three measured under Xvfb on Praat 6.6.30, 13 August 2026.
#
# THE FILE STILL HAS TO EXIST, because an editor opens a file and not a
# string. It is written into a folder the plugin owns rather than into the
# user's home or working folder — a review copy is not a deliverable, and
# scattering half-finished scripts where a user keeps their data is the same
# mistake as the batch tool writing STOP.txt into a corpus folder. From the
# editor, Praat's own Save As puts it wherever the user actually wants it.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

# THE BARREL, as eml-record-save.praat does. A relative path inside an
# included file resolves against the TOP-LEVEL script's folder, not against
# the file holding the include (eml-lib-stats.praat:13) -- so a menu script
# must include the barrel by its own neighbour name and let the barrel do the
# rest. Including ../stats/... directly works when the menu runs this file and
# breaks the moment anything else includes it, which is a trap not worth
# leaving for the next person.
include eml-lib.praat

@emlRecordInit

if emlRecordActive = 0
    # WHY THERE IS NOTHING, WHEN THAT IS KNOWABLE (audit §6, 14 Aug 2026).
    #
    # Removing the buffer from the Objects window ends the recording, and the
    # audit measured what that felt like from the outside: analyses ran
    # normally, nothing was captured, nothing said so, and this command
    # answered "nothing is being recorded" — true, unhelpful, and identical
    # to the message a user who never pressed Record gets. The meta table is
    # left behind by that path and nothing else, so it is evidence, and it is
    # the only evidence there is.
    @emlRecordOrphanCheck
    if emlRecordOrphanCheck.orphan = 1
        appendInfoLine: ""
        appendInfoLine: "------------------------------------------------------------"
        appendInfoLine: "EML: the recording ended when its buffer was removed."
        appendInfoLine: ""
        appendInfoLine: "'Table emlRecording_DO_NOT_REMOVE' is gone from the"
        appendInfoLine: "Objects window — that table IS the recording, so"
        appendInfoLine: "removing it stopped it. Anything run since was not"
        appendInfoLine: "captured and cannot be recovered."
        appendInfoLine: ""
        appendInfoLine: "Run 'Record script' to start again."
        goto END_RECORD_OPEN
    endif
    appendInfoLine: ""
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: "EML: nothing is being recorded."
    appendInfoLine: ""
    appendInfoLine: "Run 'Record script' first, then any EML analysis or"
    appendInfoLine: "figure, then this command."
    goto END_RECORD_OPEN
endif

nSteps = emlRecordN
if nSteps < 1
    # STOP MEANS STOP (author's ruling, 19 August 2026). This branch used to
    # refuse: it left the session running on the grounds that an empty
    # recording was one the user might still want. That is OVERRULED. The
    # menu item is called 'Stop recording and open' and the name is the
    # contract -- it stops, whether or not there was anything to open, and it
    # says so rather than leaving the user to guess whether the session is
    # still live.
    @emlRecordDiscard
    appendInfoLine: ""
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: "EML: recording stopped; nothing had been recorded, so no"
    appendInfoLine: "script was written."
    appendInfoLine: ""
    appendInfoLine: "'Record script' starts a new one."
    goto END_RECORD_OPEN
endif

# A FOLDER THE PLUGIN OWNS. preferencesDirectory$ is where the plugin already
# keeps its config, so it is writable and predictable on every platform.
reviewFolder$ = preferencesDirectory$ + "/eml-recorded-scripts"
createFolder: reviewFolder$

# The stamp is the recording's own, so the file name matches the header line
# inside it. Spaces and colons are stripped: a Praat script path is easier to
# retype without them, and Windows will not accept a colon at all.
stamp$ = emlRecordStamp$
stamp$ = replace$ (stamp$, " ", "_", 0)
stamp$ = replace$ (stamp$, ":", "", 0)
if stamp$ = ""
    stamp$ = "session"
endif

openPath$ = reviewFolder$ + "/eml-recorded-" + stamp$ + ".praat"
@emlGenerateUniquePath: openPath$
openPath$ = emlGenerateUniquePath.result$

@emlRecordFlush: openPath$

if emlRecordFlush.written = 0
    appendInfoLine: ""
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: "EML: nothing was written, so nothing was opened."
    appendInfoLine: "The recording is still running."
    goto END_RECORD_OPEN
endif

# THE RECORDING ENDS HERE, not before the write. A failed write must leave the
# session intact — otherwise a full disk costs the user the whole recording.
@emlRecordDiscard

# This is the line the whole file exists for.
Read from file: openPath$

appendInfoLine: ""
appendInfoLine: "------------------------------------------------------------"
appendInfoLine: "EML: recording stopped, and the script is open."
appendInfoLine: ""
appendInfoLine: string$ (nSteps), " step(s) recorded."
appendInfoLine: ""
appendInfoLine: "It is in a script window, where you can read it, edit it,"
appendInfoLine: "run it, and use File > Save as... to keep it."
appendInfoLine: ""
appendInfoLine: "The review copy is at:"
appendInfoLine: openPath$

label END_RECORD_OPEN

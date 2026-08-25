# ============================================================================
# EML Stats & Graphs — record one table edit
# ============================================================================
# Purpose: add a single step to a running recording describing an edit the
#          user just committed in the EML Table Editor, so that replaying the
#          recorded script re-performs that edit.
#
# Date: 21 August 2026
# Version: 1.0
#
# WHY THE EDITOR CALLS THIS INSTEAD OF RECORDING FOR ITSELF.
#
# scripts/eml-edit-table.praat includes nothing. Its own header sets out the
# reason and this file does not overturn it: a cell editor that pulls in the
# statistics and graphing barrel to reach one procedure has paid some 26,000
# lines for it, and harness/edittable/run.sh derives a headless twin of the
# editor by copying it into a scratch folder — where any relative `include`
# resolves against a folder that holds nothing.
#
# `runScript:` has neither cost. Measured on Praat 6.6.30, 21 August 2026:
#
#   · a bare filename resolves against the folder of the script that CALLED
#     it, which is plugin/scripts for the editor, for both of its launchers
#     and for this file — so one relative name serves an installed plugin and
#     this repository alike;
#   · object ids cross the boundary. `runScript:` starts a fresh script
#     scope, not a fresh process, so the Objects window is the same one and
#     `selectObject:` on an id taken in the caller selects the same Table;
#   · a `text:` field carries newlines and embedded double quotes through
#     unaltered, so a multi-command edit arrives as the several lines it is;
#   · only `choice`, `optionmenu` and `boolean` fields accept a NUMBER from
#     `runScript:`. Everything else must be handed a string, which is why the
#     object id arrives as `objectid$` and is converted here.
#
# THE EDITOR CALLS THIS ONLY WHEN A RECORDING IS LIVE, and it decides that
# without loading the recorder: the buffer Table's existence IS the recording
# — @emlRecordInit says so and re-attaches on exactly that test — so
# `nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"` answers the
# question in the editor's own scope. With no recording there is no call, so
# a Praat that does not have this file installed never reaches it.
#
# WHAT IS PASSED AND WHAT IS COMPOSED HERE.
#
# The editor passes a phrase KEY and up to four values, never a sentence. The
# wording lives in data/eml-record-phrases.csv with every other sentence the
# recorder writes into a generated script, so it is edited there rather than
# inside a cell editor. The caveat and the GUI route are composed here, beside
# the operation they describe, which is the rule stats/eml-analysis.praat
# already follows for its own.
#
# THE CODE IS PASSED VERBATIM AND IS NOT REWRITTEN. It is the Praat the
# editor actually ran — including the private-name rename @colLock performs
# on a table with duplicate labels — so replaying it reaches the same column
# the user pointed at. @emlRecordColumnManifest rewrites only lines beginning
# with `@` whose procedure it knows, so `Set string value:` and its siblings
# pass into the emitted file untouched.
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

form: "EML: record a table edit"
    word: "Objectid", "0"
    word: "Phrasekey", ""
    sentence: "Arg1", ""
    sentence: "Arg2", ""
    sentence: "Arg3", ""
    sentence: "Arg4", ""
    text: "Code", ""
endform

include ../stats/eml-record.praat

@emlRecordInit

# NO RECORDING, NO STEP. The editor tests the same thing before calling, so
# this is the belt to that brace: a stale call, a hand-run of this file, or a
# recording ended between the edit and this line all land here and do nothing.
if emlRecordActive = 0
    goto END_RECORD_EDIT_STEP
endif

editedId = number (objectid$)

# WHICH OBJECT THE EDIT HAPPENED TO, THROUGH THE ORDINARY DOOR.
# @emlRecordSource is what puts the table into the step's `source` column and
# into the manifest, so the renderer emits `selectObject: data1$` in front of
# the edit and the replay writes to the table this session named rather than
# to whatever happens to be selected.
@emlRecordSource: editedId

@emlPhrase: phrasekey$, arg1$, arg2$, arg3$, arg4$, "", ""

# THE ONE THING A READER OF A RECORDED SCRIPT HAS TO KNOW ABOUT AN EDIT STEP.
#
# Every other step in a recorded file reads a table and writes a report or a
# figure. This one writes to the table, so a reader scanning the file for
# what it will do to their data needs that said in the file rather than
# inferred from the command. The second sentence answers the question the
# first one raises, and it is the same fact the read step's own wording
# rests on: the plugin never writes back to the path a table came from, and
# the second line says which of the two an edit touches, in the same words
# the read step uses, so the two cannot be read as contradicting each other.
caveat$ = "This step changes the table in memory."
... + newline$
... + "Nothing here writes back to the file the table came from."

@emlRecordStep: "edit", emlPhrase.result$, caveat$, code$,
... "In the GUI: select the Table, open EML's Table editor and make"
... + newline$ + "the change there. An edit typed into Praat's own table"
... + newline$ + "window is not captured by this recorder."

label END_RECORD_EDIT_STEP

# THE TABLE THE USER WAS EDITING IS PUT BACK, because the editor's next
# command acts on the selection and this script has been moving it. A caller
# that passed an id for an object that has since gone gets nothing selected
# rather than an abort in the middle of their editing session.
nocheck selectObject: number (objectid$)

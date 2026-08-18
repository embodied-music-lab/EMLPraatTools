# ============================================================================
# EML Table Editor — Launcher (Objects window)
# ============================================================================
# Purpose: Opens the Table editor window, then launches the main editor
#          script. This wrapper exists because View & Edit opens a
#          duplicate window if the editor is already open. The TableEditor
#          menu entry points to eml-edit-table.praat directly (editor
#          already open).
#
# Date: 11 April 2026
# Version: 2.0
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
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

# THE LAUNCHER'S HALF. The same refusal, in the same words, as
# @refuseSelection in eml-edit-table.praat -- and written out here rather
# than called, because this file's whole job is to open the editor window
# before handing over, so it cannot include the editor to borrow one
# procedure from it (`include` is a textual paste and would run the editor's
# own entry block). Neither file may include eml-lib.praat to reach
# @emlErrorDialog: a cell editor does not load 26,000 lines of statistics and
# graphing for a dialog. If the author would rather these were one surface,
# it is one include and two call changes, in both files.
#
# Comments are hand-broken under 60 characters: APPENDIX_F S0-WRAP.
nTables = numberOfSelected ("Table")
if nTables <> 1
    beginPause: "Cannot Open the Table Editor"
        comment: "⚠  The editor did not open."
        comment: "──────────────────────────────────────────────"
        if nTables = 0
            comment: "No Table object is selected."
        else
            comment: "There are " + string$ (nTables) + " Table objects"
            comment: "selected, and the editor edits one at a time."
        endif
        comment: ""
        comment: "The editor works on a single Table, because every"
        comment: "cell it writes has to belong to a table it can"
        comment: "name without ambiguity."
        comment: "──────────────────────────────────────────────"
        comment: "Nothing has been changed."
        comment: ""
        comment: "Click OK, select exactly one Table in the"
        comment: "Objects window, then open the editor again."
    clicked = endPause: "OK", 1, 0
    exitScript: ""
endif
View & Edit
runScript: "eml-edit-table.praat", "button"

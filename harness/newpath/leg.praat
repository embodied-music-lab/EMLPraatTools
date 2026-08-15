# ---------------------------------------------------------------------------
# newpath -- one leg: hand a shipped wrapper a table or a file and let it run.
#
# This file does NOT transcribe any wrapper. It builds the input, selects it
# where a selection is what the wrapper reads, and hands control over with
# runScript:, so every dialog after that point -- the entry form, the analysis,
# the post-analysis loop, Draw, New -- is the code a user runs.
#
# WHY runScript: AND NOT include, measured on 6.6.30 and unchanged since
# harness/savepaths/leg.praat recorded it: `include` is a textual paste with no
# guard, so including a wrapper would land the whole plugin a second time and
# Praat would refuse at PARSE time with "Duplicate label"; and runScript:
# RE-BASES relative includes against the CALLED script's folder, so
# `include eml-lib.praat` inside the wrapper resolves exactly as it does from
# the menu.
#
# WHAT COMES BACK. Both legs end by writing the Info window to disk. That is
# the whole reason runScript: is usable here: the file-mode path of
# eml-check-data.praat and the outer loop of eml-compare-paired.praat both run
# off the END of their script rather than out of an exitScript, so control
# returns and info$ () is still holding what the user was shown. A report read
# out of the Info window is the report, not a transcription of it.
#
# THE ENCODING IS SET, NOT INHERITED. Praat writes text files in the encoding
# its preferences name, and a scratch pref dir does not guarantee which one
# that is -- a first pass of this harness produced UTF-16 and every grep for a
# phrase in the report came back empty, which reads as "the plugin did not say
# it" rather than as "the file is not the encoding you assumed".
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------

Text writing preferences: "UTF-8"

leg$ = environment$ ("EML_NEWPATH_LEG")
out$ = environment$ ("EML_NEWPATH_OUT")
wrapDir$ = environment$ ("EML_NEWPATH_WRAPDIR")

if leg$ = "paired"
    # THE TABLE IS WIDE, and its columns are named nothing like the reshape's
    # role names. That is the whole point of the fixture: after a Draw the
    # entry form used to come back offering Subject / Condition / Value, and a
    # table whose own columns were called anything similar could not tell the
    # two apart.
    Create Table with column names: "np_paired", 0,
    ... "subject jitter_pre jitter_post"
    for k to 12
        Append row
        row = Get number of rows
        Set string value: row, "subject", "P" + string$ (k)
        Set numeric value: row, "jitter_pre", 2.40 + (k mod 5) * 0.13
        Set numeric value: row, "jitter_post", 1.70 + (k mod 4) * 0.11
    endfor

    tableId = selected ("Table")
    selectObject: tableId
    runScript: wrapDir$ + "/eml-compare-paired.praat"

    writeFile: out$ + "/PAIRED_INFO.txt", info$ ()

    # WHAT IS LEFT IN THE OBJECT LIST, and it is evidence rather than tidiness.
    # The reshape the spaghetti plot is drawn from is created and removed
    # inside the Draw branch; a leg that ended with it still present would mean
    # the branch had not completed.
    select all
    nObj = numberOfSelected ()
    objList$ = ""
    for iObj to nObj
        objList$ = objList$ + selected$ (iObj) + newline$
    endfor
    writeFile: out$ + "/PAIRED_OBJECTS.txt", objList$

elsif leg$ = "filecheck"
    # ONE SESSION, EVERY CASE. The wrapper is re-entered per file rather than
    # once per Praat process because the cost of a process is the cost of the
    # whole GUI, and because re-entry is itself worth exercising: file mode
    # writes the Info window with writeInfoLine, so each case must arrive
    # clean rather than appended under the last one.
    # RESUMABLE, and that is not a convenience. This sandbox loses a Praat
    # mid-chain often enough that a leg which had to be perfect or nothing
    # could go three attempts without ever finishing; a case whose verdict is
    # already on disk was already driven through the real dialogs, so it is
    # skipped rather than re-driven. The driving shell decides which cases are
    # outstanding by exactly this rule, so the two lists cannot come apart —
    # and they must not, because the shell types the path the wrapper's file
    # chooser is waiting for, and a list off by one files every verdict under
    # the wrong case.
    caseDir$ = environment$ ("EML_NEWPATH_CASES")
    Create Strings as file list: "npCases", caseDir$ + "/*.csv"
    nCases = Get number of strings
    for iCase to nCases
        selectObject: "Strings npCases"
        case$ = Get string: iCase
        if not fileReadable (out$ + "/verdict_" + case$ + ".txt")
            runScript: wrapDir$ + "/eml-check-data.praat"
            writeFile: out$ + "/verdict_" + case$ + ".txt", info$ ()
        endif
    endfor
    removeObject: "Strings npCases"
endif

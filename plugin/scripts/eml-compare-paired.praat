# ============================================================================
# EML Praat Tools — Compare Paired Observations
# ============================================================================
# Purpose: Compare two paired columns using parametric (paired t-test)
#          and/or nonparametric (Wilcoxon signed-rank) tests.
# Date: 11 May 2026
# Version: 3.1
# v3.1: D90 — the spaghetti plot's axis labels no longer come from the
#        wide->long reshape's role names ("Condition", "Value"). The measure
#        and the contrast are derived from the two column names and
#        registered against the role names with the graph layer's D90
#        label-override registry (@emlSetLabelOverride).
# v3.0: Wrapper infrastructure refactor. repeat/until replaces goto/label.
# v2.0: Full convergence — orchestrator + @emlGuessColumnRoles.
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

include eml-lib.praat

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessCol1Idx = emlWrapperInit.guessDataIdx
guessCol2Idx = emlWrapperInit.guessDataIdx2
if guessCol2Idx = 0
    guessCol2Idx = min (2, nCols)
endif

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# the D93 fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# what the user had set. (D93)
# Hoisted out of the loop. @emlWrapperInit has already run
# @emlGuessColumnRoles, so this is loop-invariant, and the seed below needs
# it before the first iteration. It was assigned inside the loop until
# 5 August, which made "Unknown variable: guessSubjectIdx" the first thing
# this wrapper did once the seed was added.
guessSubjectIdx = emlGuessColumnRoles.subjectIdx

selTest = 1
# +1 because this menu carries a leading "(row number)" entry.
selSubjectIdx = guessSubjectIdx + 1
selGroupIdx = 1

allDone = 0
repeat
    beginPause: "Compare Paired Observations"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        comment: "Select two numeric columns with paired data (same N)."
        optionmenu: "Column 1", guessCol1Idx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Column 2", guessCol2Idx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Test", selTest
            option: "Paired t-test"
            option: "Wilcoxon signed-rank"
            option: "Both"
        comment: ""
        comment: "For spaghetti plot (optional):"
        optionmenu: "Subject column", selSubjectIdx
            option: "(row number)"
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Group column", selGroupIdx
            option: "(none)"
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    col1$ = column_1$
    col2$ = column_2$
    testChoice = test
    # Carry the answers forward so a return to this form shows them. (D93)
    @emlKeepChoice: col1$, guessCol1Idx
    guessCol1Idx = emlKeepChoice.idx
    @emlKeepChoice: col2$, guessCol2Idx
    guessCol2Idx = emlKeepChoice.idx
    selTest = testChoice
    # These two menus carry a leading "(none)" entry, so the stored
    # value is the menu position, not a column index.
    selSubjectIdx = subject_column
    selGroupIdx = group_column
    @emlHandleCommonFields

    # Subject column: index 1 = "(row number)", 2+ = actual column
    hasSubjectCol = 0
    subjectCol$ = ""
    if subject_column > 1
        hasSubjectCol = 1
        subjectCol$ = emlTableColumnNames.name$ [subject_column - 1]
    endif

    # Group column: index 1 = "(none)", 2+ = actual column
    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = emlTableColumnNames.name$ [group_column - 1]
    endif

    if col1$ = col2$
        # D93: uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Please select two different columns.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        if testChoice = 1
            testType$ = "parametric"
        elsif testChoice = 2
            testType$ = "nonparametric"
        else
            testType$ = "both"
        endif

        selectObject: tableId
        @emlRunPairedAnalysis: tableId, col1$, col2$, testType$
        if emlRunPairedAnalysis.error$ <> ""
            # D93: an error must not strand the user on a form the error has
            # just ruled out. Present it with guidance, and honour Quit.
            @emlErrorDialog: emlRunPairedAnalysis.error$, emlRunPairedAnalysis.remedy$, "menu"
            if not emlErrorDialog.back
                allDone = 1
            endif
        else
            runAgain = 0
            repeat
                beginPause: "Analysis complete"
                    comment: "📊 Results are in the Info window."
                clicked = endPause: "Done", "CSV", "Draw", "New", 3, 0

                if clicked = 1
                    allDone = 1
                elsif clicked = 2
                    @emlWrapperExportCSV: tableName$, "paired"
                elsif clicked = 3
                    # Reshape to long format for spaghetti plot
                    selectObject: tableId
                    nRows = Get number of rows

                    if hasGroupCol
                        longTableId = Create Table with column names: "pairedLong",
                        ... nRows * 2, { "Subject", "Condition", "Value", "Group" }
                    else
                        longTableId = Create Table with column names: "pairedLong",
                        ... nRows * 2, { "Subject", "Condition", "Value" }
                    endif

                    for iRow from 1 to nRows
                        selectObject: tableId
                        val1 = Get value: iRow, col1$
                        val2 = Get value: iRow, col2$
                        if hasSubjectCol
                            subjectLabel$ = Get value: iRow, subjectCol$
                        else
                            subjectLabel$ = string$ (iRow)
                        endif
                        if hasGroupCol
                            groupLabel$ = Get value: iRow, groupCol$
                        endif

                        longRow1 = (iRow - 1) * 2 + 1
                        longRow2 = (iRow - 1) * 2 + 2
                        selectObject: longTableId
                        Set string value: longRow1, "Subject", subjectLabel$
                        Set string value: longRow1, "Condition", col1$
                        Set numeric value: longRow1, "Value", val1
                        Set string value: longRow2, "Subject", subjectLabel$
                        Set string value: longRow2, "Condition", col2$
                        Set numeric value: longRow2, "Value", val2
                        if hasGroupCol
                            Set string value: longRow1, "Group", groupLabel$
                            Set string value: longRow2, "Group", groupLabel$
                        endif
                    endfor

                    # ── D90: axis labels that name the measure ──────────
                    # The long table's columns are ROLE names — Subject,
                    # Condition, Value — and the graph layer derives its axis
                    # labels from column names, so the figure's y-axis read
                    # "Value": the one place the measured quantity could
                    # appear said nothing about it. The real names are right
                    # here at the call site, so they are registered against
                    # the role names rather than left to the reshape.
                    #
                    # The measure is the two columns' common stem when they
                    # have one (jitter_pre / jitter_post -> "jitter", with the
                    # stem trimmed back to a word boundary so it cannot come
                    # out as "jitter p"), and both names otherwise. What is
                    # left over after the stem names the contrast the x-axis
                    # actually shows ("pre vs post") — which is what
                    # "Condition" was standing in for.
                    lblCommon = 0
                    lblStop = 0
                    for lblK from 1 to min (length (col1$), length (col2$))
                        if lblStop = 0
                            if left$ (col1$, lblK) = left$ (col2$, lblK)
                                lblCommon = lblK
                            else
                                lblStop = 1
                            endif
                        endif
                    endfor
                    lblStem$ = left$ (col1$, lblCommon)
                    lblAtBoundary = 0
                    while lblStem$ <> "" and lblAtBoundary = 0
                        if right$ (lblStem$, 1) = "_"
                        ... or right$ (lblStem$, 1) = " "
                        ... or right$ (lblStem$, 1) = "."
                            lblAtBoundary = 1
                        else
                            lblStem$ = left$ (lblStem$,
                            ... length (lblStem$) - 1)
                        endif
                    endwhile
                    if lblStem$ <> ""
                        lblSep = length (lblStem$)
                        lblStem$ = left$ (lblStem$, lblSep - 1)
                    endif
                    # Registered RAW, underscores and all: the graph layer's
                    # own token formatter is what turns SPL_dB into
                    # "SPL (dB)" and F0_Hz into "F0 (Hz)". De-underscoring
                    # here would hand it "SPL dB" and lose the unit.
                    if lblStem$ <> ""
                        lblMeasure$ = lblStem$
                        lblFactor$ = mid$ (col1$, length (lblStem$) + 2, 1000)
                        ... + " vs "
                        ... + mid$ (col2$, length (lblStem$) + 2, 1000)
                    else
                        lblMeasure$ = col1$ + " / " + col2$
                        lblFactor$ = col1$ + " vs " + col2$
                    endif

                    emlGraphsPresetType = 13
                    if hasGroupCol
                        emlGraphsPresetGroupCol$ = "Group"
                    endif
                    # The graph layer's D90 half is a registry keyed by column
                    # name (graphs/eml-graph-procedures.praat), which the
                    # spaghetti page's @emlCapitalizeLabel calls on
                    # spCondCol$ / spValueCol$ consult. Registering the role
                    # names is therefore all this side has to do — and the
                    # registry is cleared straight after the figure, since it
                    # is keyed on names as generic as "Value" and would
                    # otherwise leak into the next graph of the session.
                    @emlSetLabelOverride: "Value", lblMeasure$
                    @emlSetLabelOverride: "Condition", lblFactor$
                    @emlGraphsWorkflow: longTableId
                    @emlClearLabelOverrides
                    removeObject: longTableId
                    selectObject: tableId
                elsif clicked = 4
                    runAgain = 1
                endif
            until allDone or runAgain
        endif
    endif
    endif
until allDone

# ============================================================================
# EML Praat Tools — Compare Paired Observations
# ============================================================================
# Purpose: Compare two paired columns using parametric (paired t-test)
#          and/or nonparametric (Wilcoxon signed-rank) tests.
# Date: 11 May 2026
# Version: 3.0
# v3.0: Wrapper infrastructure refactor. repeat/until replaces goto/label.
# v2.0: Full convergence — orchestrator + @emlGuessColumnRoles.
# ============================================================================

include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat
include ../stats/eml-analysis.praat
include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
include ../graphs/eml-draw-procedures.praat
include ../graphs/eml-graphs-form.praat

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

                    emlGraphsPresetType = 14
                    if hasGroupCol
                        emlGraphsPresetGroupCol$ = "Group"
                    endif
                    @emlGraphsWorkflow: longTableId
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

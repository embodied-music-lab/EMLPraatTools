# ============================================================================
# EML Stats & Graphs — Pairwise Comparisons
# ============================================================================
# Purpose: All-pairs comparisons from a Table using pairwise t-test,
#          pairwise Wilcoxon, or Scheffe, with p-value adjustment.
# Date: 2 August 2026
# Version: 3.1
# ============================================================================

include eml-lib.praat

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# The fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# What the user had set.
selTest = 1
selAdj = 1
selTVariant = 1
selGroupOrder = 1

allDone = 0
repeat
    beginPause: "Pairwise Comparisons"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        optionmenu: "Data column", guessDataIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Group column", guessGroupIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Test", selTest
            option: "Pairwise t-test"
            option: "Pairwise Wilcoxon (Mann-Whitney)"
            option: "Scheffe"
        optionmenu: "Adjustment (t and Wilcoxon only)", selAdj
            option: "Bonferroni"
            option: "Holm"
            option: "Benjamini-Hochberg"
        optionmenu: "T test type (pairwise t only)", selTVariant
            option: "Welch"
            option: "Student"
        optionmenu: "Group order", selGroupOrder
            option: "Table order"
            option: "Alphabetical"
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    dataCol$ = data_column$
    groupCol$ = group_column$
    testChoice = test
    adjChoice = adjustment
    tVariantChoice = t_test_type
    # Carry the answers forward so a return to this form shows them.
    @emlKeepChoice: dataCol$, guessDataIdx
    guessDataIdx = emlKeepChoice.idx
    @emlKeepChoice: groupCol$, guessGroupIdx
    guessGroupIdx = emlKeepChoice.idx
    selTest = testChoice
    selAdj = adjChoice
    selTVariant = tVariantChoice
    selGroupOrder = group_order

    if group_order = 2
        emlGroupSortAlphabetical = 1
    else
        emlGroupSortAlphabetical = 0
    endif
    @emlHandleCommonFields

    if adjChoice = 1
        adjMethod$ = "bonferroni"
    elsif adjChoice = 2
        adjMethod$ = "holm"
    else
        adjMethod$ = "bh"
    endif

    if testChoice = 1
        if tVariantChoice = 1
            test$ = "welch"
        else
            test$ = "student"
        endif
    elsif testChoice = 2
        test$ = "wilcoxon"
    else
        test$ = "scheffe"
    endif

    selectObject: tableId
    @emlRunPairwiseAnalysis: tableId, dataCol$, groupCol$, test$, adjMethod$
    if emlRunPairwiseAnalysis.error$ <> ""
        # An error must not strand the user on a form the error has
        # just ruled out. Present it with guidance, and honour Quit.
        @emlErrorDialog: emlRunPairwiseAnalysis.error$, emlRunPairwiseAnalysis.remedy$, "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        runAgain = 0
        repeat
            beginPause: "Analysis complete"
                comment: "📊 Results are in the Info window."
            clicked = endPause: "Done", "Save", "Draw", "New", 3, 0

            if clicked = 1
                allDone = 1
            elsif clicked = 2
                # ONE PANEL FOR EVERY OUTPUT. This was @emlWrapperExportCSV,
                # which wrote only the numbers and remembered its own folder.
                # @emlSavePanel offers the results AND the Info window report
                # under one folder and one stem. 0 = there is no figure here;
                # nothing has been drawn at the end of an analysis.
                @emlSavePanel: 0, tableName$ + "_pairwise",
                ... emlLastCSVFolder$
                if emlSavePanel.cancelled = 0
                    emlLastCSVFolder$ = emlSavePanel.folder$
                endif
            elsif clicked = 3
                if test$ = "wilcoxon"
                    presetTestType$ = "nonparametric"
                else
                    presetTestType$ = "parametric"
                endif
                emlGraphsPresetType = 7
                emlGraphsPresetDataCol$ = dataCol$
                emlGraphsPresetGroupCol$ = groupCol$
                emlGraphsPresetTestType$ = presetTestType$
                emlGraphsPresetAnnotate = 1
                emlGraphsPresetCorrection$ = adjMethod$
                @emlGraphsWorkflow: tableId
            elsif clicked = 4
                runAgain = 1
            endif
        until allDone or runAgain
    endif
    endif
until allDone

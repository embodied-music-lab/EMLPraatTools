# ============================================================================
# EML Praat Tools — Pairwise Comparisons
# ============================================================================
# Purpose: All-pairs comparisons from a Table using pairwise t-test,
#          pairwise Wilcoxon, or Scheffe, with p-value adjustment.
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
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

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
        optionmenu: "Test", 1
            option: "Pairwise t-test"
            option: "Pairwise Wilcoxon (Mann-Whitney)"
            option: "Scheffe"
        optionmenu: "Adjustment (t and Wilcoxon only)", 1
            option: "Bonferroni"
            option: "Holm"
            option: "Benjamini-Hochberg"
        optionmenu: "T test type (pairwise t only)", 1
            option: "Welch"
            option: "Student"
        optionmenu: "Group order", 1
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
        pauseScript: emlRunPairwiseAnalysis.error$
    else
        runAgain = 0
        repeat
            beginPause: "Analysis complete"
                comment: "📊 Results are in the Info window."
            clicked = endPause: "Done", "CSV", "Draw", "New", 3, 0

            if clicked = 1
                allDone = 1
            elsif clicked = 2
                @emlWrapperExportCSV: tableName$
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
                @emlGraphsWorkflow: tableId
            elsif clicked = 4
                runAgain = 1
            endif
        until allDone or runAgain
    endif
    endif
until allDone

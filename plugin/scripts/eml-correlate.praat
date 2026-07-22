# ============================================================================
# EML Praat Tools — Correlate Two Columns
# ============================================================================
# Purpose: Correlate two numeric columns using Pearson r, Spearman rho,
#          or both. Reports correlation coefficient, t, df, p, and n.
# Date: 11 May 2026
# Version: 3.2
# v3.2: Per-group correlation output replaced with shared reporter
#       (@emlReportCorrelationAnalysis) for rich Info window output.
# v3.1: Use emlGraphsPresetCorrType$ global instead of direct annotCorrType$
#        set (survives per-call reset in graphs form).
# v3.0: Wrapper infrastructure refactor. Shared @emlWrapperInit,
#        @emlWrapperExportCSV. repeat/until replaces goto/label.
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
guessXIdx = emlWrapperInit.guessDataIdx
guessYIdx = emlWrapperInit.guessDataIdx2
if guessYIdx = 0
    guessYIdx = min (2, nCols)
endif

allDone = 0
repeat
    beginPause: "Correlate Two Columns"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        optionmenu: "Column X", guessXIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Column Y", guessYIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        comment: ""
        optionmenu: "Group column", 1
            option: "(none — overall only)"
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Test", 1
            option: "Pearson r"
            option: "Spearman rho"
            option: "Both"
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    colX$ = column_X$
    colY$ = column_Y$
    testChoice = test

    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = emlTableColumnNames.name$ [group_column - 1]
    endif

    @emlHandleCommonFields

    if colX$ = colY$
        pauseScript: "Please select two different columns."
    else
        if testChoice = 1
            testType$ = "pearson"
        elsif testChoice = 2
            testType$ = "spearman"
        else
            testType$ = "both"
        endif

        selectObject: tableId
        @emlRunCorrelationAnalysis: tableId, colX$, colY$, testType$
        if emlRunCorrelationAnalysis.error$ <> ""
            pauseScript: emlRunCorrelationAnalysis.error$
        else
            # Per-group correlations (if group column selected)
            if hasGroupCol
                selectObject: tableId
                @emlCountGroups: tableId, groupCol$
                for iGroup from 1 to emlCountGroups.nGroups
                    .gLabel$ = emlCountGroups.groupLabel$ [iGroup]
                    .gDisplay$ = replace$ (.gLabel$, "_", " ", 0)
                    selectObject: tableId
                    @eml_getGroupData: tableId, colX$, groupCol$, .gLabel$
                    .gXData# = eml_getGroupData.data#
                    .gN = eml_getGroupData.n
                    @eml_getGroupData: tableId, colY$, groupCol$, .gLabel$
                    .gYData# = eml_getGroupData.data#
                    if .gN >= 3
                        if testType$ = "pearson" or testType$ = "both"
                            @emlPearsonCorrelation: .gXData#, .gYData#, 2
                        endif
                        if testType$ = "spearman" or testType$ = "both"
                            @emlSpearmanCorrelation: .gXData#, .gYData#, 2
                        endif
                        @emlReportCorrelationAnalysis: tableName$
                        ... + " -- " + .gDisplay$,
                        ... colX$, colY$, .gN, testType$
                    else
                        appendInfoLine: ""
                        appendInfoLine: "  " + .gDisplay$ + ": Skipped (n < 3)"
                    endif
                endfor
            endif

            # Post-analysis loop
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
                    if testChoice = 2
                        emlGraphsPresetCorrType$ = "spearman"
                    elsif testChoice = 3
                        emlGraphsPresetCorrType$ = "both"
                    else
                        emlGraphsPresetCorrType$ = "pearson"
                    endif
                    emlGraphsPresetType = 8
                    emlGraphsPresetXCol$ = colX$
                    emlGraphsPresetYCol$ = colY$
                    emlGraphsPresetAnnotate = 1
                    emlGraphsPresetAnalysisType = 1
                    if hasGroupCol
                        emlGraphsPresetGroupCol$ = groupCol$
                    endif
                    @emlGraphsWorkflow: tableId
                elsif clicked = 4
                    runAgain = 1
                endif
            until allDone or runAgain
        endif
    endif
    endif
until allDone

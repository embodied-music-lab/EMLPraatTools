# ============================================================================
# EML Praat Tools — Simple Linear Regression
# ============================================================================
# Purpose: OLS simple linear regression (slope, intercept, R², SE, F, p)
#          with Theil-Sen robust alternative.
# Date: 11 May 2026
# Version: 2.1
# v2.1: Use emlGraphsPresetRegressionLine and emlGraphsPresetCorrType$
#        globals instead of direct variable set (survive per-call reset).
# v2.0: Wrapper infrastructure refactor. repeat/until replaces goto/label.
# v1.0: Initial release with orchestrator.
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
guessPredIdx = emlWrapperInit.guessDataIdx
guessRespIdx = emlWrapperInit.guessDataIdx2
if guessRespIdx = 0
    guessRespIdx = min (2, nCols)
endif

allDone = 0
repeat
    beginPause: "Simple Linear Regression"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        comment: ""
        comment: "Select the predictor (X) and response (Y) columns."
        comment: "The model will estimate: Y = slope x X + intercept"
        comment: ""
        optionmenu: "Predictor column", guessPredIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Response column", guessRespIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        comment: ""
        optionmenu: "Group column", 1
            option: "(none — overall only)"
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    predCol$ = predictor_column$
    respCol$ = response_column$
    @emlHandleCommonFields

    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = emlTableColumnNames.name$ [group_column - 1]
    endif

    if predCol$ = respCol$
        pauseScript: "Please select two different columns."
    else
        selectObject: tableId
        @emlRunRegressionAnalysis: tableId, respCol$, predCol$
        if emlRunRegressionAnalysis.error$ <> ""
            pauseScript: emlRunRegressionAnalysis.error$
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
                    emlGraphsPresetCorrType$ = "pearson"
                    emlGraphsPresetType = 8
                    emlGraphsPresetXCol$ = predCol$
                    emlGraphsPresetYCol$ = respCol$
                    emlGraphsPresetAnnotate = 1
                    emlGraphsPresetAnalysisType = 2
                    emlGraphsPresetRegressionLine = 1
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

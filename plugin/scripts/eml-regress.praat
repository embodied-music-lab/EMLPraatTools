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

include eml-lib.praat

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessPredIdx = emlWrapperInit.guessDataIdx
guessRespIdx = emlWrapperInit.guessDataIdx2
if guessRespIdx = 0
    guessRespIdx = min (2, nCols)
endif

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# the D93 fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# what the user had set. (D93)
selGroupIdx = 1

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
        optionmenu: "Group column", selGroupIdx
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
    # Carry the answers forward so a return to this form shows them. (D93)
    @emlKeepChoice: predCol$, guessPredIdx
    guessPredIdx = emlKeepChoice.idx
    @emlKeepChoice: respCol$, guessRespIdx
    guessRespIdx = emlKeepChoice.idx
    # Leading "(none)" entry: this is a menu position, not a column index.
    selGroupIdx = group_column
    @emlHandleCommonFields

    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = emlTableColumnNames.name$ [group_column - 1]
    endif

    if predCol$ = respCol$
        # D93: uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Please select two different columns.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        selectObject: tableId
        @emlRunRegressionAnalysis: tableId, respCol$, predCol$
        if emlRunRegressionAnalysis.error$ <> ""
            # D93: an error must not strand the user on a form the error has
            # just ruled out. Present it with guidance, and honour Quit.
            @emlErrorDialog: emlRunRegressionAnalysis.error$, emlRunRegressionAnalysis.remedy$, "menu"
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
                    @emlWrapperExportCSV: tableName$, "regression"
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

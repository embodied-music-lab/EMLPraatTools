# ============================================================================
# EML Stats & Graphs — Simple Linear Regression
# ============================================================================
# Purpose: OLS simple linear regression (slope, intercept, R², SE, F, p).
#          OLS is the only estimator this wrapper offers. The plugin also
#          ships a Theil-Sen robust estimator (@emlTheilSen), but it is
#          reachable only from the draw layer, and only on a Spearman
#          scatter — not from here.
# Date: 11 May 2026
# Version: 2.2
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
guessPredIdx = emlWrapperInit.guessDataIdx
guessRespIdx = emlWrapperInit.guessDataIdx2
if guessRespIdx = 0
    guessRespIdx = min (2, nCols)
endif

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# The fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# What the user had set.
selGroupIdx = 1

allDone = 0
repeat
    beginPause: "Simple Linear Regression"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        comment: ""
        comment: "Select the predictor (X) and response (Y) columns."
        comment: "The model will estimate: Y = (slope · X) + intercept"
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
    # Carry the answers forward so a return to this form shows them.
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
        # Uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Please select two different columns.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        selectObject: tableId
        @emlRunRegressionAnalysis: tableId, respCol$, predCol$
        if emlRunRegressionAnalysis.error$ <> ""
            # An error must not strand the user on a form the error has
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
                clicked = endPause: "Done", "Save", "Draw", "New", 3, 0

                if clicked = 1
                    allDone = 1
                elsif clicked = 2
                    # ONE PANEL FOR EVERY OUTPUT. This was @emlWrapperExportCSV,
                    # which wrote only the numbers and remembered its own folder.
                    # @emlSavePanel offers the results AND the Info window report
                    # under one folder and one stem. 0 = there is no figure here;
                    # nothing has been drawn at the end of an analysis.
                    @emlSavePanel: 0, tableName$ + "_regression",
                    ... emlLastCSVFolder$
                    if emlSavePanel.cancelled = 0
                        emlLastCSVFolder$ = emlSavePanel.folder$
                    endif
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

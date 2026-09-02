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
selGroupName$ = ""

allDone = 0
repeat
    ; ── candidate grouping columns ──────────────────────────────────
    ; SAME FILTER as the correlate dialog (eml-correlate.praat): a grouping
    ; column has to be able to grade the regression, which rules out the
    ; predictor and response columns themselves (a variable cannot group
    ; itself), single-valued columns, and near-unique columns. Filtered by
    ; INDEX (guessPredIdx/guessRespIdx), not by name -- predCol$/respCol$ are
    ; not yet set on the loop's first pass, and filtering by the previous
    ; pass's guessed indices is what creates (and what the stale-column
    ; refusal below exists to catch) the same hazard v102 documents for the
    ; correlate dialog: this list is necessarily built from the PREVIOUS
    ; pass's predictor/response, not the one about to be chosen.
    selectObject: tableId
    grpNRows = Get number of rows
    grpMaxLevels = min (12, max (2, floor (grpNRows / 3)))
    grpN = 0
    for iCol from 1 to nCols
        if iCol <> guessPredIdx and iCol <> guessRespIdx
            grpCand$ = emlTableColumnNames.name$ [iCol]
            grpLevels = 0
            grpOver = 0
            for iRow from 1 to grpNRows
                if grpOver = 0
                    selectObject: tableId
                    grpCell$ = Get value: iRow, grpCand$
                    @eml_normalizeLabel: grpCell$
                    grpNorm$ = eml_normalizeLabel.result$
                    grpSeen = 0
                    for iLev from 1 to grpLevels
                        if grpLevel$ [iLev] = grpNorm$
                            grpSeen = 1
                        endif
                    endfor
                    if grpSeen = 0
                        grpLevels = grpLevels + 1
                        grpLevel$ [grpLevels] = grpNorm$
                        if grpLevels > grpMaxLevels
                            grpOver = 1
                        endif
                    endif
                endif
            endfor
            if grpOver = 0 and grpLevels >= 2
                grpN = grpN + 1
                grpName$ [grpN] = grpCand$
            endif
        endif
    endfor

    # Seed the menu from the user's last choice by NAME: the filtered list
    # is rebuilt each time round and its indices are not stable.
    selGroupIdx = 1
    for iG from 1 to grpN
        if grpName$ [iG] = selGroupName$
            selGroupIdx = iG + 1
        endif
    endfor

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
        for iCol from 1 to grpN
            option: grpName$ [iCol]
        endfor
        if grpN = 0
            comment: "     (no column in this Table has a usable number"
            comment: "     of groups — overall only)"
        endif
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

    # Leading "(none)" entry: this is a position in the FILTERED list, not
    # a column index — same idiom as the menu door's correlate dialog.
    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = grpName$ [group_column - 1]
    endif
    selGroupName$ = groupCol$

    @emlHandleCommonFields

    if predCol$ = respCol$
        # Uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Please select two different columns.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    elsif hasGroupCol and (groupCol$ = predCol$ or groupCol$ = respCol$)
        # THE STALE GROUP LIST -- same hazard v102 covers for the correlate
        # dialog: the candidate list is built from the PREVIOUS pass's
        # predictor/response, before this page's own choices are read, so a
        # user who moves the predictor or response onto a column that was
        # offered as a grouping column can pick a column that groups itself.
        # Refused, not silently run.
        staleMsg$ = "The grouping column """ + groupCol$ + """ is now one of"
        staleMsg$ = staleMsg$ + " the two columns being regressed, so it"
        staleMsg$ = staleMsg$ + " cannot also group them. Nothing was run."
        staleMsg$ = staleMsg$ + " The list of grouping columns was built"
        staleMsg$ = staleMsg$ + " before you changed the predictor or"
        staleMsg$ = staleMsg$ + " response column; click Back and it will be"
        staleMsg$ = staleMsg$ + " rebuilt for the columns you have now chosen."
        @emlErrorDialog: staleMsg$, "", "menu"
        selGroupName$ = ""
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
            # ── Per-group regression (punch list 4.5) ─────────────────
            # Rides the port in stats/eml-analysis.praat: @emlLinearRegression
            # ran once above, for the WHOLE table, and its globals still hold
            # that overall fit -- nothing has run since. @emlRunGroupedRegressionAnalysis
            # reads them before doing anything else.
            if hasGroupCol
                selectObject: tableId
                @emlRunGroupedRegressionAnalysis: tableId, predCol$,
                ... respCol$, groupCol$
            endif

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

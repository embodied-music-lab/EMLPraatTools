# ============================================================================
# EML Praat Tools — Correlate Two Columns
# ============================================================================
# Purpose: Correlate two numeric columns using Pearson r, Spearman rho,
#          or both. Reports correlation coefficient, t, df, p, and n.
# Date: 11 May 2026
# Version: 3.3
# v3.3: Missing-data fix (correctness). Per-group correlation now uses
#       @eml_getGroupPairedData (row-wise complete-case within the group)
#       instead of two independent @eml_getGroupData calls, which
#       misaligned X and Y when cells were missing; excluded-row note added.
# v3.2: Per-group correlation output replaced with shared reporter
#       (@emlReportCorrelationAnalysis) for rich Info window output.
# v3.1: Use emlGraphsPresetCorrType$ global instead of direct annotCorrType$
#        set (survives per-call reset in graphs form).
# v3.0: Wrapper infrastructure refactor. Shared @emlWrapperInit,
#        @emlWrapperExportCSV. repeat/until replaces goto/label.
# v2.0: Full convergence — orchestrator + @emlGuessColumnRoles.
# ============================================================================

include eml-lib.praat

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessXIdx = emlWrapperInit.guessDataIdx
guessYIdx = emlWrapperInit.guessDataIdx2
if guessYIdx = 0
    guessYIdx = min (2, nCols)
endif

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# the D93 fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# what the user had set. (D93)
selTest = 1
selGroupIdx = 1

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
        optionmenu: "Group column", selGroupIdx
            option: "(none — overall only)"
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Test", selTest
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
    # Carry the answers forward so a return to this form shows them. (D93)
    @emlKeepChoice: colX$, guessXIdx
    guessXIdx = emlKeepChoice.idx
    @emlKeepChoice: colY$, guessYIdx
    guessYIdx = emlKeepChoice.idx
    selTest = testChoice
    # Leading "(none)" entry: this is a menu position, not a column index.
    selGroupIdx = group_column

    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = emlTableColumnNames.name$ [group_column - 1]
    endif

    @emlHandleCommonFields

    if colX$ = colY$
        # D93: uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Please select two different columns.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
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
            # D93: an error must not strand the user on a form the error has
            # just ruled out. Present it with guidance, and honour Quit.
            @emlErrorDialog: emlRunCorrelationAnalysis.error$, emlRunCorrelationAnalysis.remedy$, "menu"
            if not emlErrorDialog.back
                allDone = 1
            endif
        else
            # Per-group correlations (if group column selected)
            if hasGroupCol
                selectObject: tableId
                @emlCountGroups: tableId, groupCol$
                for iGroup from 1 to emlCountGroups.nGroups
                    .gLabel$ = emlCountGroups.groupLabel$ [iGroup]
                    .gDisplay$ = replace$ (.gLabel$, "_", " ", 0)
                    selectObject: tableId
                    # Row-wise complete-case within the group so X and Y stay
                    # aligned; per-column extraction would misalign the pairs.
                    @eml_getGroupPairedData: tableId, colX$, colY$, groupCol$, .gLabel$
                    .gXData# = eml_getGroupPairedData.dataX#
                    .gYData# = eml_getGroupPairedData.dataY#
                    .gN = eml_getGroupPairedData.n
                    .gExcluded = eml_getGroupPairedData.nExcluded
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
                        if .gExcluded > 0
                            .gExclNote$ = "  Note: " + string$ (.gExcluded) + " row(s) excluded for missing data (analyzed n = " + string$ (.gN) + " complete pairs)."
                            appendInfoLine: .gExclNote$
                        endif
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
                    @emlWrapperExportCSV: tableName$, "correlation"
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

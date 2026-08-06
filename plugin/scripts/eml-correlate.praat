# ============================================================================
# EML Praat Tools — Correlate Two Columns
# ============================================================================
# Purpose: Correlate two numeric columns using Pearson r, Spearman rho,
#          or both. Reports correlation coefficient, t, df, p, and n.
# Date: 11 May 2026
# Version: 3.4
# v3.4: D47 — the "Group column" menu is filtered: it now offers only
#       columns with 2..(n/3) distinct levels, and never the columns
#       currently bound to X and Y. D51 — Draw sets
#       emlGraphsPresetRegressionLine so the scatter carries the line whose
#       R-squared it annotates. D53 — the Test menu carries a one-line
#       Pearson/Spearman assumption note.
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
selGroupName$ = ""

allDone = 0
repeat
    ; ── D47: candidate grouping columns ──────────────────────────────────
    ; A grouping column has to be able to grade the correlation. That rules
    ; out the two columns currently bound to X and Y (a variable cannot
    ; group itself), single-valued columns (one group is not a grouping),
    ; and near-unique columns such as a speaker ID, which would give one
    ; group per row. The ceiling is 12 levels or n/3, whichever is smaller:
    ; n/3 keeps each group above the n >= 3 the per-group loop below
    ; enforces, and past a dozen levels a grouped scatter stops being
    ; readable. Labels are normalised the same way @emlCountGroups
    ; normalises them, so the count here and the groups actually analysed
    ; cannot disagree. The scan stops counting once a column is over the
    ; ceiling, so an ID column costs one pass rather than a full
    ; distinct-count.
    selectObject: tableId
    grpNRows = Get number of rows
    grpMaxLevels = min (12, max (2, floor (grpNRows / 3)))
    grpN = 0
    for iCol from 1 to nCols
        if iCol <> guessXIdx and iCol <> guessYIdx
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

    ; Seed the menu from the user's last choice by NAME: the filtered list
    ; is rebuilt each time round and its indices are not stable. (D93)
    selGroupIdx = 1
    for iG from 1 to grpN
        if grpName$ [iG] = selGroupName$
            selGroupIdx = iG + 1
        endif
    endfor

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
        for iCol from 1 to grpN
            option: grpName$ [iCol]
        endfor
        if grpN = 0
            comment: "     (no column in this Table has a usable number"
            comment: "     of groups — overall only)"
        endif
        comment: ""
        comment: "ℹ️ Pearson assumes a straight-line relation and roughly"
        comment: "     normal variables; Spearman ranks first, so it suits"
        comment: "     skewed data, outliers, or curved-but-monotonic trends."
        comment: "     Unsure? Run Check normality on both columns first."
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

    # Leading "(none)" entry: this is a position in the FILTERED list, not
    # a column index. (D47)
    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = grpName$ [group_column - 1]
    endif
    selGroupName$ = groupCol$

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
                    ; D51: the annotation carries R-squared, so the figure
                    ; has to carry the line it describes. AnalysisType 1
                    ; does not imply a line (only >= 2 does), so the
                    ; regression preset is set explicitly here.
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

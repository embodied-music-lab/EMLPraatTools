# ============================================================================
# EML Praat Tools — Correlate Two Columns
# ============================================================================
# Purpose: Correlate two numeric columns using Pearson r, Spearman rho,
#          or both. Reports correlation coefficient, t, df, p, and n.
# Date: 11 May 2026
# Version: 3.5
# v3.5: D48/D49 — the per-group block is announced with its own header and
#       counts, so it no longer reads as loose output past the end of the
#       overall report, and the groups too small to analyse are named on one
#       summary line inside the block rather than two orphan lines each.
#       D104 — a grouped run exports ONE tidy frame in which every row is
#       labelled in `term` ("(overall)" / "<group column> = <level>"),
#       instead of dropping the per-group results from the export and
#       accumulating them in the legacy buffer under a fabricated table name.
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
            # ── Per-group correlations (if a group column was selected) ──
            #
            # TWO PASSES, and the first one exists for the reader. Pass 1 asks
            # only how many complete pairs each group has. That is what lets
            # the whole block be ANNOUNCED — its own header, its own counts —
            # before any group prints, instead of appearing as loose output
            # past the closing rule of the overall report (D48); and it is
            # what lets the groups that cannot be analysed be named on ONE
            # summary line at the end instead of costing two orphan lines
            # each (D49: 30 singleton groups used to cost 60 lines).
            #
            # Pass 1 screens on the same @eml_getGroupPairedData that pass 2
            # analyses with, so the n the header counts and the n the report
            # shows cannot disagree.
            #
            # Main-body code: undotted variable names (Rule 5C); the pg
            # prefix keeps them clear of the D47 grouping scan's grp names.
            if hasGroupCol
                selectObject: tableId
                @emlCountGroups: tableId, groupCol$
                pgTotal = emlCountGroups.nGroups
                pgRun = 0
                pgSkipped = 0
                pgSkipList$ = ""
                pgSkipMore = 0
                for pgI from 1 to pgTotal
                    pgLabel$ [pgI] = emlCountGroups.groupLabel$ [pgI]
                    selectObject: tableId
                    @eml_getGroupPairedData: tableId, colX$, colY$,
                    ... groupCol$, pgLabel$ [pgI]
                    pgN [pgI] = eml_getGroupPairedData.n
                    if pgN [pgI] >= 3
                        pgRun = pgRun + 1
                    else
                        pgSkipped = pgSkipped + 1
                        ; The Info window does not wrap, so the summary names
                        ; as many skipped groups as fit on one line and counts
                        ; the rest rather than running off the right edge.
                        if length (pgSkipList$) < 45
                            if pgSkipList$ <> ""
                                pgSkipList$ = pgSkipList$ + ", "
                            endif
                            pgSkipList$ = pgSkipList$
                            ... + replace$ (pgLabel$ [pgI], "_", " ", 0)
                        else
                            pgSkipMore = pgSkipMore + 1
                        endif
                    endif
                endfor
                if pgSkipMore > 0
                    pgSkipList$ = pgSkipList$ + ", and "
                    ... + string$ (pgSkipMore) + " more"
                endif

                @emlUnderscoreToSpace: groupCol$
                pgColDisplay$ = emlUnderscoreToSpace.result$
                @emlReportHeader: "Correlation by " + pgColDisplay$
                @emlReportLineString: "Grouping column", pgColDisplay$
                @emlReportLine: "Groups", pgTotal, 0
                @emlReportLine: "Analysed", pgRun, 0

                ; ── D104: ONE export, with the grouping in a real column ──
                ;
                ; @emlRunCorrelationAnalysis has already declared the OVERALL
                ; fit into the tidy/glance collectors (and cleared the legacy
                ; buffer). Re-invoking @emlReportCorrelationAnalysis per group
                ; below does NOT re-declare, so before this block a grouped
                ; run exported the overall rows only — every group's numbers
                ; were printed and then silently dropped from the CSV — while
                ; the legacy single-file buffer quietly accumulated them under
                ; a FABRICATED table name ("v12corr -- 30s"), which a second
                ; press of CSV would have written out.
                ;
                ; Chosen behaviour: one export, not one per group. A grouped
                ; correlation is one question asked of one table; splitting it
                ; into k files would put k save dialogs in front of the user
                ; and force a join to get back what they asked for. So the
                ; tidy frame is rebuilt here with EVERY row labelled in
                ; `term` — "(overall)" for the whole-table fit and
                ; "<group column> = <level>" for each group — which is the
                ; column the result writer already has for "what this row is
                ; about". glance stays the overall model, because glance is
                ; one row per model by definition; n.groups records how many
                ; per-group fits are in tidy.
                ;
                ; @emlTidyClear empties tidy only (glance survives), and the
                ; overall rows are re-emitted from the orchestrator's own
                ; captured values, so emlResult_declared stays 1 throughout
                ; and the frame is never left half-built: by the time the
                ; group loop starts, tidy already holds the overall rows.
                ;
                ; pgCsvN is the legacy buffer's length before the group
                ; reports append to it; restoring it afterwards is what keeps
                ; the fabricated "table -- group" rows out of the legacy file.
                pgCsvN = emlCSV_n
                @emlTidyClear
                if testType$ = "pearson" or testType$ = "both"
                    @emlTidyRow: "(overall)"
                    @emlTidyNum: "estimate", emlRunCorrelationAnalysis.pearR
                    @emlTidyNum: "statistic", emlRunCorrelationAnalysis.pearT
                    @emlTidyNum: "p.value", emlRunCorrelationAnalysis.pearP
                    @emlTidyNum: "parameter", emlRunCorrelationAnalysis.pearDf
                    @emlTidyStr: "method",
                    ... "Pearson's product-moment correlation"
                    @emlTidyStr: "alternative", "two.sided"
                endif
                if testType$ = "spearman" or testType$ = "both"
                    @emlTidyRow: "(overall)"
                    @emlTidyNum: "estimate", emlRunCorrelationAnalysis.spearRho
                    @emlTidyNum: "statistic", emlRunCorrelationAnalysis.spearT
                    @emlTidyNum: "p.value", emlRunCorrelationAnalysis.spearP
                    @emlTidyNum: "parameter", emlRunCorrelationAnalysis.spearDf
                    @emlTidyStr: "method", "Spearman's rank correlation rho"
                    @emlTidyStr: "alternative", "two.sided"
                endif

                for pgI from 1 to pgTotal
                    if pgN [pgI] >= 3
                        pgDisplay$ = replace$ (pgLabel$ [pgI], "_", " ", 0)
                        selectObject: tableId
                        # Row-wise complete-case within the group so X and Y
                        # stay aligned; per-column extraction would misalign
                        # the pairs.
                        @eml_getGroupPairedData: tableId, colX$, colY$,
                        ... groupCol$, pgLabel$ [pgI]
                        pgX# = eml_getGroupPairedData.dataX#
                        pgY# = eml_getGroupPairedData.dataY#
                        pgThisN = eml_getGroupPairedData.n
                        pgExcluded = eml_getGroupPairedData.nExcluded
                        pgTerm$ = groupCol$ + " = " + pgLabel$ [pgI]
                        # Each test's outputs are captured immediately after
                        # its own call, the way the orchestrator does it, so
                        # nothing run in between can be reported under the
                        # wrong heading.
                        if testType$ = "pearson" or testType$ = "both"
                            @emlPearsonCorrelation: pgX#, pgY#, 2
                            pgPearR = emlPearsonCorrelation.r
                            pgPearT = emlPearsonCorrelation.t
                            pgPearDf = emlPearsonCorrelation.df
                            pgPearP = emlPearsonCorrelation.p
                            pgPearErr$ = emlPearsonCorrelation.error$
                        endif
                        if testType$ = "spearman" or testType$ = "both"
                            @emlSpearmanCorrelation: pgX#, pgY#, 2
                            pgSpearRho = emlSpearmanCorrelation.rho
                            pgSpearT = emlSpearmanCorrelation.t
                            pgSpearDf = emlSpearmanCorrelation.df
                            pgSpearP = emlSpearmanCorrelation.p
                            pgSpearErr$ = emlSpearmanCorrelation.error$
                        endif
                        # The report title names the grouping column as well
                        # as the level, so a reader scrolling the Info window
                        # can see WHAT the block is grouped by. (D48)
                        @emlReportCorrelationAnalysis: tableName$
                        ... + " -- " + pgColDisplay$ + " = " + pgDisplay$,
                        ... colX$, colY$, pgThisN, testType$
                        if pgExcluded > 0
                            pgExclNote$ = "  Note: " + string$ (pgExcluded)
                            ... + " row(s) excluded for missing data"
                            ... + " (analyzed n = " + string$ (pgThisN)
                            ... + " complete pairs)."
                            appendInfoLine: pgExclNote$
                        endif
                        if testType$ = "pearson" or testType$ = "both"
                            if pgPearErr$ = ""
                                @emlTidyRow: pgTerm$
                                @emlTidyNum: "estimate", pgPearR
                                @emlTidyNum: "statistic", pgPearT
                                @emlTidyNum: "p.value", pgPearP
                                @emlTidyNum: "parameter", pgPearDf
                                @emlTidyStr: "method",
                                ... "Pearson's product-moment correlation"
                                @emlTidyStr: "alternative", "two.sided"
                            endif
                        endif
                        if testType$ = "spearman" or testType$ = "both"
                            if pgSpearErr$ = ""
                                @emlTidyRow: pgTerm$
                                @emlTidyNum: "estimate", pgSpearRho
                                @emlTidyNum: "statistic", pgSpearT
                                @emlTidyNum: "p.value", pgSpearP
                                @emlTidyNum: "parameter", pgSpearDf
                                @emlTidyStr: "method",
                                ... "Spearman's rank correlation rho"
                                @emlTidyStr: "alternative", "two.sided"
                            endif
                        endif
                    endif
                endfor

                ; The legacy rows the per-group reporter calls appended carry
                ; a fabricated table name and duplicate what tidy now holds
                ; properly labelled, so the buffer is truncated back to the
                ; overall analysis. (D104)
                emlCSV_n = pgCsvN
                @emlGlanceNum: "n.groups", pgRun

                ; ONE line for every skipped group, naming them and the
                ; reason, inside the block — followed by the closing rule that
                ; terminates it. (D48/D49)
                if pgSkipped > 0
                    @emlReportBlank
                    @emlReportLineString: "Skipped (n < 3)",
                    ... string$ (pgSkipped) + " of " + string$ (pgTotal)
                    ... + ": " + pgSkipList$
                endif
                if pgRun = 0
                    appendInfoLine: "  No group has 3 or more complete "
                    ... + "pairs — a coarser grouping column would give"
                    appendInfoLine: "  correlations that can be computed."
                endif
                ; The same rule @emlReportHeader draws, taken from it rather
                ; than copied, so the two cannot drift apart.
                appendInfoLine: emlReportHeader.border$
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

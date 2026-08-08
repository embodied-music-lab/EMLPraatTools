# ============================================================================
# EML Praat Tools — Check Normality (Multi-Column)
# ============================================================================
# Purpose: Test normality for one or more numeric columns, optionally
#          broken out by group. Reports Shapiro-Wilk, skewness, kurtosis,
#          and a parametric/nonparametric recommendation per column.
# Version: 2.2
# Date: 8 August 2026
# v2.2: D137 — per-group mode no longer carries its own normality rule. It
#        had hard-coded thresholds of 1 and 3 against the shared constants
#        of 2 and 7, and the pre-5-August `skKurtFail or swFail` gate, while
#        the SAME script's overall mode called @emlRunNormalityAnalysis,
#        which had neither. One wrapper, two answers for the same data
#        depending on whether a grouping column was picked: a group with
#        |skew| >= 1 that Shapiro-Wilk did not reject came out nonparametric
#        grouped and parametric ungrouped. Both modes now reach the one
#        shared rule, @emlNormalityRecommendation (stats/eml-analysis.praat).
#        This CHANGES per-group verdicts, which is the point.
# v2.1: Draw button on the completion dialog — a normal Q-Q plot for ONE
#        column at a time, behind an explicit column picker. The picker is
#        not optional: this checker tests every numeric column in one run,
#        so a figure drawn from an assumed column would be a silently wrong
#        figure. In grouped mode the picker asks for the group as well,
#        because in that mode a column is not what was tested — a column
#        within a group is.
# v2.0: Full convergence — @emlWrapperInit for Table check,
#        @emlRunNormalityAnalysis orchestrator for overall mode (fixes
#        double-report bug and wrong-type 4th parameter in v1.0).
#        repeat/until replaces goto/label.
# v1.0: Initial release.
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
# @emlDrawQQPlot is not part of eml-lib-graphs yet, so it is pulled in here.
# The path is relative to the TOP-LEVEL script's folder — this file's own
# folder, plugin/scripts — which is why it reads ../graphs and not ./graphs.
# Praat tolerates the same procedure being defined twice (the later
# definition wins), so adding this file to eml-lib-graphs.praat later will
# not collide with this line. Verified 7 Aug 2026.
include ../graphs/eml-draw-qq.praat

# ── Init ───────────────────────────────────────────────────────────────────

@emlWrapperInit: 1
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
displayTable$ = replace$ (tableName$, "_", " ", 0)

# ── Identify numeric columns ──────────────────────────────────────────────

selectObject: tableId
nRows = Get number of rows

nNumericCols = 0
for iCol from 1 to nCols
    .colName$ = emlTableColumnNames.name$ [iCol]
    @emlCheckNumericColumn: tableId, .colName$
    if emlCheckNumericColumn.isNumeric
        nNumericCols = nNumericCols + 1
        numericCol$ [nNumericCols] = .colName$
    endif
endfor

if nNumericCols = 0
    exitScript: "No numeric columns found in the selected Table."
endif

# ── Main loop ─────────────────────────────────────────────────────────────

allDone = 0
repeat
    beginPause: "Check Normality"
        comment: "📋 Table: " + displayTable$ + " (" + string$ (nNumericCols) + " numeric columns, " + string$ (nRows) + " rows)"
        comment: "─────────────────────────────────────"
        comment: ""
        comment: "Will test normality for all " + string$ (nNumericCols)
        ... + " numeric columns:"
        for iCol from 1 to min (nNumericCols, 8)
            comment: "  • " + numericCol$ [iCol]
        endfor
        if nNumericCols > 8
            comment: "  ... and " + string$ (nNumericCols - 8) + " more"
        endif
        comment: ""
        comment: "Optional: test per group"
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

    @emlHandleCommonFields

    hasGroupCol = 0
    groupCol$ = ""
    if group_column > 1
        hasGroupCol = 1
        groupCol$ = emlTableColumnNames.name$ [group_column - 1]
    endif

    # ── Run normality tests ───────────────────────────────────────────────

    appendInfoLine: "══════════════════════════════════════════════"
    appendInfoLine: "  Normality Assessment"
    appendInfoLine: "  Table: ", displayTable$
    if hasGroupCol
        displayGroup$ = replace$ (groupCol$, "_", " ", 0)
        appendInfoLine: "  Grouped by: ", displayGroup$
    endif
    appendInfoLine: "══════════════════════════════════════════════"
    appendInfoLine: ""

    nParametric = 0
    nNonparametric = 0

    # ── Q-Q picker state ──────────────────────────────────────────────────
    # qqNGroups stays 0 unless the grouped branch fills it. It is read only
    # under `if hasGroupCol`, but it is initialised here anyway: Praat does
    # not short-circuit `and`/`or`, so a guard is never a substitute for an
    # initialised variable, and an undefined global aborts the whole script.
    # qqLastCol / qqLastGroup remember the previous choice so a second Draw
    # opens where the last one left off; reset per run because the column
    # list and the group list belong to THIS run.
    qqNGroups = 0
    qqLastCol = 1
    qqLastGroup = 1

    for iSel from 1 to nNumericCols
        col$ = numericCol$ [iSel]
        displayCol$ = replace$ (col$, "_", " ", 0)

        if hasGroupCol
            # Per-group normality
            appendInfoLine: "── ", displayCol$, " ──"
            appendInfoLine: ""
            selectObject: tableId
            @emlCountGroups: tableId, groupCol$
            .allGroupsOK = 1

            # Group labels for the Q-Q picker, captured from the same
            # @emlCountGroups call the analysis used rather than recomputed
            # later. The grouping column does not change within a run, so
            # the first column's labels are every column's labels.
            if iSel = 1
                qqNGroups = emlCountGroups.nGroups
                for iQQg from 1 to qqNGroups
                    qqGroupLabel$ [iQQg] = emlCountGroups.groupLabel$ [iQQg]
                endfor
            endif

            for iGroup from 1 to emlCountGroups.nGroups
                .gLabel$ = emlCountGroups.groupLabel$ [iGroup]
                .gDisplay$ = replace$ (.gLabel$, "_", " ", 0)
                selectObject: tableId
                @eml_getGroupData: tableId, col$, groupCol$, .gLabel$

                if eml_getGroupData.n >= 3
                    .data# = eml_getGroupData.data#
                    .n = eml_getGroupData.n

                    @emlShapiroWilk: .data#
                    .swW = emlShapiroWilk.w
                    .swP = emlShapiroWilk.p

                    @emlSkewness: .data#
                    .skew = emlSkewness.result
                    @emlKurtosis: .data#
                    .kurt = emlKurtosis.result

                    # ── The decision ──────────────────────────────────────
                    #
                    # This branch used to carry its OWN copy of the rule,
                    # and it was the copy that had drifted furthest:
                    #
                    #   .skKurtFail = (abs(.skew) >= 1) or (abs(.kurt) >= 3)
                    #   ... elsif .skKurtFail or .swFail
                    #
                    # Two defects in three lines. The thresholds were
                    # hard-coded 1 and 3 against shared constants of 2 and 7
                    # (emlSkewThreshold / emlKurtosisThreshold in
                    # stats/eml-output.praat), and the gate was the
                    # pre-5-August `skKurtFail or swFail` rule that lets a
                    # descriptive rule of thumb overrule a formal test.
                    #
                    # It mattered because the OVERALL branch of this very
                    # script (the else below) calls
                    # @emlRunNormalityAnalysis, which had neither defect. So
                    # one wrapper gave two different answers for the same
                    # data depending on whether the user picked a grouping
                    # column: any group with |skew| >= 1 that Shapiro-Wilk
                    # did not reject was called nonparametric here and
                    # parametric there. Both branches now reach the same
                    # rule, @emlNormalityRecommendation. (D137)
                    #
                    # emlShapiroWilk.p is undefined whenever .error$ is set,
                    # so it is passed straight through with the error string
                    # rather than tested here; the shared procedure guards
                    # it with a NESTED if, because Praat's `and` evaluates
                    # both sides. The line replaced above,
                    # `.swP < 0.05 and emlShapiroWilk.error$ = ""`, was that
                    # comparison against undefined — benign by accident.
                    @emlNormalityRecommendation: .skew, .kurt, .n,
                    ... emlShapiroWilk.p, emlShapiroWilk.error$
                    .largeNOverride = emlNormalityRecommendation.largeNOverride
                    .rec$ = emlNormalityRecommendation.recommendation$
                    .groupNonparametric = 0
                    if .rec$ = "nonparametric"
                        .groupNonparametric = 1
                    endif

                    appendInfoLine: "  ", .gDisplay$, " (n = ", .n, "):"
                    appendInfoLine: "    W = ", fixed$ (.swW, 4),
                    ... "  p = ", fixed$ (.swP, 4)
                    appendInfoLine: "    Skewness = ", fixed$ (.skew, 3),
                    ... "  Kurtosis (excess) = ", fixed$ (.kurt, 3)

                    if .largeNOverride
                        appendInfoLine: "    → Parametric (large-n override:"
                        ... + " shape within limits)"
                    elsif .groupNonparametric
                        appendInfoLine: "    → Nonparametric recommended"
                        .allGroupsOK = 0
                    else
                        appendInfoLine: "    → Normality OK"
                    endif
                else
                    appendInfoLine: "  ", .gDisplay$, " (n = ",
                    ... eml_getGroupData.n, "): skipped (n < 3)"
                endif
            endfor

            appendInfoLine: ""
            if .allGroupsOK
                appendInfoLine: "  Summary: all groups pass → parametric"
                nParametric = nParametric + 1
            else
                appendInfoLine: "  Summary: one or more groups fail → nonparametric"
                nNonparametric = nNonparametric + 1
            endif
        else
            # Overall normality — orchestrator handles test + report
            selectObject: tableId
            @emlRunNormalityAnalysis: tableId, col$, "both"
            if emlRunNormalityAnalysis.error$ <> ""
                appendInfoLine: "── ", displayCol$, " ──"
                appendInfoLine: "  Error: ", emlRunNormalityAnalysis.error$
            else
                if emlRunNormalityAnalysis.recommendation$ = "parametric"
                    nParametric = nParametric + 1
                else
                    nNonparametric = nNonparametric + 1
                endif
            endif
        endif

        appendInfoLine: ""
    endfor

    # ── Summary ───────────────────────────────────────────────────────────

    appendInfoLine: "══════════════════════════════════════════════"
    appendInfoLine: "  SUMMARY: ", nNumericCols, " columns tested"
    appendInfoLine: "  Parametric OK:     ", nParametric
    appendInfoLine: "  Nonparametric rec: ", nNonparametric
    if nNonparametric = 0
        appendInfoLine: ""
        appendInfoLine: "  All columns pass → parametric tests appropriate."
    elsif nParametric = 0
        appendInfoLine: ""
        appendInfoLine: "  All columns fail → consider nonparametric tests."
    else
        appendInfoLine: ""
        appendInfoLine: "  Mixed results — consider variable-by-variable."
    endif
    appendInfoLine: "══════════════════════════════════════════════"

    selectObject: tableId

    # ── Post-analysis ─────────────────────────────────────────────────────
    #
    # Three buttons, in the house order the other wrappers use (Done, Draw,
    # New — see eml-compare-groups.praat and eml-correlate.praat, which sit
    # a CSV button between the first two). Draw returns here rather than
    # ending the run, so several columns can be plotted from one analysis.

    runAgain = 0
    repeat
        beginPause: "Normality assessment complete"
            comment: "📊 Results are in the Info window."
            comment: ""
            comment: "Draw plots a normal Q-Q plot for one column."
        clicked = endPause: "Done", "Draw", "New", 2, 0

        if clicked = 1
            allDone = 1

        elsif clicked = 2

            # ── Column picker ─────────────────────────────────────────────
            # NOT optional, and not inferred. This wrapper tests every
            # numeric column in one pass, so there is no "the" column to
            # draw; a figure drawn from a guess would carry a real column's
            # name over another column's data. The menu holds exactly the
            # columns this run tested, in the order it tested them.
            beginPause: "Draw Q-Q plot"
                comment: "📈 A normal Q-Q plot is drawn for one column at a time."
                comment: "─────────────────────────────────────"
                comment: "Points on the line mean the column matches a normal"
                comment: "distribution; systematic curves away from it do not."
                comment: ""
                optionmenu: "Plot column", qqLastCol
                for iCol from 1 to nNumericCols
                    option: numericCol$ [iCol]
                endfor
                if hasGroupCol
                    comment: ""
                    comment: "This run tested each column WITHIN a group, so the"
                    comment: "plot needs a group too."
                    optionmenu: "Plot group", qqLastGroup
                    for iQQg from 1 to qqNGroups
                        option: qqGroupLabel$ [iQQg]
                    endfor
                endif
            qqClicked = endPause: "Cancel", "Draw plot", 2, 0

            if qqClicked = 2
                qqLastCol = plot_column
                qqCol$ = numericCol$ [plot_column]
                qqLabel$ = qqCol$
                qqReady = 0
                qqFail$ = ""

                if hasGroupCol
                    qqLastGroup = plot_group
                    qqGroup$ = qqGroupLabel$ [plot_group]
                    qqLabel$ = qqCol$ + " — " + qqGroup$
                    selectObject: tableId
                    @eml_getGroupData: tableId, qqCol$, groupCol$, qqGroup$
                    if eml_getGroupData.error$ <> ""
                        qqFail$ = eml_getGroupData.error$
                    else
                        qqData# = eml_getGroupData.data#
                        qqReady = 1
                    endif
                else
                    # Every row, undefined cells included: @emlDrawQQPlot
                    # drops them itself and counts them onto the figure, so
                    # the vector it sees is the vector the checker read.
                    qqData# = zero# (nRows)
                    for iRow from 1 to nRows
                        selectObject: tableId
                        qqData# [iRow] = Get value: iRow, qqCol$
                    endfor
                    qqReady = 1
                endif

                # Nested, not ANDed. Praat evaluates BOTH sides of `and`,
                # so `if qqReady = 1 and emlDrawQQPlot.drew = 1` would read
                # a variable that does not exist yet on the failure path.
                if qqReady = 1
                    @emlDrawQQPlot: qqData#, qqLabel$, 6, 4.5, "color", 1
                    if emlDrawQQPlot.drew = 0
                        qqFail$ = emlDrawQQPlot.error$
                    else
                        appendInfoLine: ""
                        appendInfoLine: "Q-Q plot drawn: ", qqLabel$,
                        ... "  (n = ", emlDrawQQPlot.n, ")"
                        if emlDrawQQPlot.nDropped > 0
                            appendInfoLine: "  ", emlDrawQQPlot.nDropped,
                            ... " row(s) excluded as missing."
                        endif
                    endif
                endif

                if qqFail$ <> ""
                    beginPause: "Cannot draw this Q-Q plot"
                        comment: "⚠  No figure was drawn."
                        comment: "─────────────────────────────────────"
                        @emlWrapText: qqFail$, 62
                        for iWrap from 1 to emlWrapText.nLines
                            comment: emlWrapText.line$ [iWrap]
                        endfor
                        comment: "─────────────────────────────────────"
                        comment: ""
                        comment: "Column: " + replace$ (qqLabel$, "_", " ", 0)
                        comment: "The results already in the Info window are"
                        comment: "unaffected. Choose another column and try again."
                    qqDismissed = endPause: "OK", 1, 0
                endif

                selectObject: tableId
            endif

        elsif clicked = 3
            runAgain = 1
        endif
    until allDone or runAgain
until allDone

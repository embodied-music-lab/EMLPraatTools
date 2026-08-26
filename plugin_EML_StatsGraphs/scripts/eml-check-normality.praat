# ============================================================================
# EML Stats & Graphs — Check Normality (Multi-Column)
# ============================================================================
# Purpose: Test normality for one or more numeric columns, optionally
#          broken out by group. Reports Shapiro-Wilk, skewness and
#          kurtosis, and flags columns whose marginal distribution
#          departs strongly from normal. It recommends no test: the
#          intended analysis is not known on this screen.
# Version: 2.2
# Date: 8 August 2026
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
    # ROUTED THROUGH THE PLUGIN'S ERROR SURFACE. This was a raw
    # `exitScript:` with a message, which Praat presents in its own error
    # window under "Script exited. ... Command ... not executed." — the
    # interpreter's stack where a refusal belongs. "entry" mode is the one
    # written for a refusal that happens before the dialog exists: it names
    # what was looked for, it does not offer a Back there is nothing behind,
    # and it does not suggest another test, because no other EML tool reads a
    # table with no numeric column either.
    @emlErrorDialog: "Normality is a property of a numeric variable, and "
    ... + "none of the " + string$ (nCols) + " column(s) in """
    ... + displayTable$ + """ reads as numbers.", "", "entry"
    exitScript: ""
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

    # One counter, and it counts alarms. See the SUMMARY block below.
    nFlagged = 0

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
            # COVERAGE. A group too small to test (n < 3) is skipped below,
            # not tested -- and the column summary must never generalise
            # over a group it never examined. .nAssessed counts groups that
            # actually ran; the summary compares it against
            # emlCountGroups.nGroups rather than assuming the two are equal.
            .nAssessed = 0

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
                    .nAssessed = .nAssessed + 1
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
                    # This branch does NOT carry its own copy of the rule,
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
                    # Rule, @emlNormalityRecommendation.
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

                    # THE DISPLAY STANDARD: no raw double reaches
                    # the Info window. Statistics print at fixed decimals, p
                    # prints in APA style, and full precision belongs to the
                    # CSV export.
                    #
                    # These four numbers are the EXACT TWIN of the wizard's
                    # normality preview, and the resemblance is not an
                    # accident: this per-group branch is the third copy of
                    # that report, the same third copy that would otherwise carry
                    # its own decision rule. The wizard's copy was repaired
                    # earlier today (scripts/eml-wizard.praat, "Skewness:"),
                    # and repairing one twin and not the other is how the two
                    # answers came to disagree in the first place.
                    #
                    # THE MECHANISM IS fixed$, NOT THESE LINES. Praat's fixed$
                    # returns the LARGER of the precision asked for and the
                    # decimals needed to show one significant digit, and a
                    # bare "0" for an exact zero -- so `fixed$ (.skew, 3)` on
                    # a symmetric group prints seventeen decimals of
                    # arithmetic noise, and `fixed$ (.swP, 4)` on a strongly
                    # skewed one printed "0.00000000001". @eml_fixed
                    # (stats/eml-output.praat) is the one formatter that
                    # closes it; there is no second implementation and this
                    # file does not start one. Praat cannot nest a procedure
                    # call inside an expression, so each value is hoisted into
                    # a temporary first.
                    #
                    # NOTHING COMPUTED MOVES. @emlNormalityRecommendation is
                    # called above with the raw .skew, .kurt and
                    # emlShapiroWilk.p, and the per-group verdict printed
                    # below reads that call and not these strings.
                    @eml_fixed: .skew, 3
                    .skewTxt$ = eml_fixed.result$
                    @eml_fixed: .kurt, 3
                    .kurtTxt$ = eml_fixed.result$
                    appendInfoLine: "  ", .gDisplay$, " (n = ", .n, "):"
                    # Shapiro-Wilk errors on this group -- zero range, every
                    # value identical -- leave .swW and .swP undefined, so the
                    # error is read before either is printed and the producer's
                    # own text stands in for them. A reader told
                    # "W = --undefined--" learns nothing about their data;
                    # told the range is zero, they learn everything.
                    # @wizardNormDiag guards its own call the same way.
                    if emlShapiroWilk.error$ = ""
                        @eml_fixed: .swW, 4
                        .wTxt$ = eml_fixed.result$
                        @emlFormatP: .swP
                        appendInfoLine: "    W = ", .wTxt$,
                        ... "  ", emlFormatP.formatted$
                    else
                        appendInfoLine: "    Shapiro-Wilk: ", emlShapiroWilk.error$
                    endif
                    appendInfoLine: "    Skewness = ", .skewTxt$,
                    ... "  Kurtosis (excess) = ", .kurtTxt$

                    # ── WHAT WAS MEASURED, NOT WHAT TO DO ─────────────────
                    #
                    # This wrapper is a DIAGNOSTIC. It is reached from the
                    # Describe menu with no question attached: it does not
                    # know whether the user is heading for a t test, a
                    # regression, a Kruskal-Wallis or nothing at all. The
                    # choice of test depends on the design, on what the
                    # numbers mean, on the sample size and on what the user
                    # is willing to assume -- none of which is in scope here.
                    # A line that named a family of tests would be answering
                    # a question this screen was never asked.
                    #
                    # So each line states the reading and the thresholds it
                    # was read against, and stops. The Shapiro-Wilk W, its p,
                    # the skewness and the excess kurtosis are printed
                    # immediately above; these lines say which side of the
                    # line those numbers fell, in this column, for this group.
                    # "Marginal distribution" is meant literally -- what was
                    # examined is the spread of this group's values on its
                    # own, which is not the residual distribution a
                    # parametric model would actually assume.
                    # THE THRESHOLDS ARE PRINTED AS CRITERIA, NOT AS CLAIMS
                    # ABOUT THIS GROUP. The gate is not a conjunction of all
                    # three readings: a group whose Shapiro-Wilk does not
                    # reject is not flagged even when its skewness is past the
                    # limit. So a line saying "|skew| < 2" would be asserting
                    # something the branch it prints from does not establish.
                    # What is printed instead is the set of thresholds the
                    # reading was made against; the group's own W, p, skewness
                    # and excess kurtosis are on the two lines above, where a
                    # reader can hold them against these numbers directly.
                    @eml_fixed: emlSkewThreshold, 0
                    .skewLimit$ = eml_fixed.result$
                    @eml_fixed: emlKurtosisThreshold, 0
                    .kurtLimit$ = eml_fixed.result$
                    .criteria$ = "thresholds: Shapiro-Wilk p < .05, |skew| >= "
                    ... + .skewLimit$ + ", |excess kurt| >= " + .kurtLimit$
                    if .largeNOverride
                        appendInfoLine: "    → Shapiro-Wilk rejects at the 5%"
                        ... + " level; shape statistics are within the"
                        ... + " thresholds at n = " + string$ (.n)
                        ... + " (" + .criteria$ + ")"
                    elsif .groupNonparametric
                        appendInfoLine: "    → Strong departure from normality"
                        ... + " in this group's marginal distribution ("
                        ... + .criteria$ + ")"
                        .allGroupsOK = 0
                    else
                        appendInfoLine: "    → No strong departure in this"
                        ... + " group's marginal distribution ("
                        ... + .criteria$ + ")"
                    endif
                else
                    appendInfoLine: "  ", .gDisplay$, " (n = ",
                    ... eml_getGroupData.n, "): skipped (n < 3)"
                endif
            endfor

            appendInfoLine: ""
            if .allGroupsOK
                if .nAssessed < emlCountGroups.nGroups
                    # COVERAGE was incomplete: at least one group was too
                    # small to test and never examined. "no group ... shows
                    # a strong departure" is a claim about every group in
                    # the column; this loop did not examine all of them, so
                    # that claim is false about the data in front of the
                    # reader. Language batch item 13, verbatim.
                    appendInfoLine: "  Summary: No strong departure in the"
                    ... + " groups large enough to test (",
                    ... .nAssessed, " of ", emlCountGroups.nGroups,
                    ... " assessed)."
                else
                    appendInfoLine: "  Summary: no group in this column shows a"
                    ... + " strong departure"
                endif
            else
                appendInfoLine: "  Summary: one or more groups in this column"
                ... + " show a strong departure"
                nFlagged = nFlagged + 1
            endif
        else
            # Overall normality — orchestrator handles test + report
            selectObject: tableId
            @emlRunNormalityAnalysis: tableId, col$, "both"
            if emlRunNormalityAnalysis.error$ <> ""
                appendInfoLine: "── ", displayCol$, " ──"
                appendInfoLine: "  Error: ", emlRunNormalityAnalysis.error$
            else
                if emlRunNormalityAnalysis.recommendation$ <> "parametric"
                    nFlagged = nFlagged + 1
                endif
            endif
        endif

        appendInfoLine: ""
    endfor

    # ── Summary ───────────────────────────────────────────────────────────

    # AN ALARM COUNT, NOT A SCORE. The number below says how many columns
    # tripped the threshold, and that is the only thing it says. It is not a
    # tally of columns that "passed", because nothing here is being graded and
    # no test has been proposed to pass it for. A count of columns needing a
    # closer look is a fact about this table; a count of columns cleared for
    # parametric testing would be a recommendation about an analysis this
    # screen has not been told about.
    appendInfoLine: "══════════════════════════════════════════════"
    appendInfoLine: "  SUMMARY: ", nNumericCols, " columns tested"
    appendInfoLine: "  Columns flagged for a strong departure: ", nFlagged
    appendInfoLine: ""
    if nFlagged = 0
        appendInfoLine: "  No column showed a strong departure from normality"
        appendInfoLine: "  in its marginal distribution."
    elsif nFlagged = nNumericCols
        appendInfoLine: "  Every column showed a strong departure from"
        appendInfoLine: "  normality in its marginal distribution."
    else
        appendInfoLine: "  Some columns showed a strong departure and some"
        appendInfoLine: "  did not; the per-column readings are above."
    endif
    appendInfoLine: ""
    appendInfoLine: "  What was checked: the marginal distribution of each"
    appendInfoLine: "  numeric column, on its own. Normality of model"
    appendInfoLine: "  residuals, independence and equality of variance were"
    appendInfoLine: "  not examined here."
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
        clicked = endPause: "Done", "Save", "Draw", "New", 3, 0

        if clicked = 1
            allDone = 1

        elsif clicked = 2
            # Every path through every
            # approach must reach the export step. This wrapper had no Save
            # at all -- it ran @emlRunNormalityAnalysis, which has declared
            # into the broom collectors since before the panel existed, and
            # then offered the user no way to keep the result. Found by v49
            # enumerating wrappers that run an orchestrator and asking which
            # of them call the panel; it was one of two, and the other is the
            # tabled LMM module.
            #
            # 0 = no figure. The Q-Q plot is drawn from the branch below,
            # which has its own picker because this wrapper tests every
            # numeric column in one pass and there is no "the" column.
            @emlSavePanel: 0, tableName$ + "_normality", emlLastCSVFolder$
            if emlSavePanel.cancelled = 0
                emlLastCSVFolder$ = emlSavePanel.folder$
            endif

        elsif clicked = 3

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

        elsif clicked = 4
            runAgain = 1
        endif
    until allDone or runAgain
until allDone

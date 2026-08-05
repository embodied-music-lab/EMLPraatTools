# ============================================================================
# EML Praat Tools — Check Normality (Multi-Column)
# ============================================================================
# Purpose: Test normality for one or more numeric columns, optionally
#          broken out by group. Reports Shapiro-Wilk, skewness, kurtosis,
#          and a parametric/nonparametric recommendation per column.
# Version: 2.0
# Date: 11 May 2026
# v2.0: Full convergence — @emlWrapperInit for Table check,
#        @emlRunNormalityAnalysis orchestrator for overall mode (fixes
#        double-report bug and wrong-type 4th parameter in v1.0).
#        repeat/until replaces goto/label.
# v1.0: Initial release.
#
# ATTRIBUTION
# Framework: EML Praat Tools by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# ============================================================================

include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-inferential.praat
include ../stats/eml-output.praat
include ../stats/eml-analysis.praat
include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
include ../graphs/eml-draw-procedures.praat
include ../graphs/eml-graphs-form.praat

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
                    .skKurtFail = (abs (.skew) >= 1) or (abs (.kurt) >= 3)
                    .swFail = (.swP < 0.05 and emlShapiroWilk.error$ = "")

                    appendInfoLine: "  ", .gDisplay$, " (n = ", .n, "):"
                    appendInfoLine: "    W = ", fixed$ (.swW, 4),
                    ... "  p = ", fixed$ (.swP, 4)
                    appendInfoLine: "    Skewness = ", fixed$ (.skew, 3),
                    ... "  Kurtosis (excess) = ", fixed$ (.kurt, 3)

                    if .swFail and (not .skKurtFail) and .n > 50
                        appendInfoLine: "    → Parametric (large-n override:"
                        ... + " shape within limits)"
                    elsif .skKurtFail or .swFail
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

    beginPause: "Normality assessment complete"
        comment: "📊 Results are in the Info window."
    clicked = endPause: "Done", "New", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone
    endif
until allDone

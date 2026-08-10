# ---------------------------------------------------------------------------
# One OVER-CAP disclosure case. Companion to case.praat, which drives the ten
# procedures on one ordinary table; this drives the three shapes that push a
# procedure past a limit it holds, where the v1.21 disclosure work found the
# next three silences.
#
# Driven by harness/disclosure/run.sh, which sets:
#   EML_CASE      scatter8 | scatter21 | barmix | barzero | gviolin25 | gbox25
#   EML_ANNOTATE  0 or 1     — the user's Annotate tick
#   EML_OUT       PNG path   — read by @stressSave in the shared prelude
#
# THE SIX CASES
# -------------
#   scatter8    Eight groups, Correlation type = Both, formula on. Three
#               annotation lines per group = 24, into a block whose limit is
#               20. Measured 7 Aug 2026 before the fix: annotBlockN = 24, the
#               box ran off the bottom edge of the figure, and the dropped-row
#               disclosure that followed was refused by the budget and never
#               appeared. This is the case the fix is named for.
#
#   scatter21   Twenty-one groups with the FORMULA ONLY and no correlations.
#               One line per group, so the block overflows on 21 lines whether
#               or not Annotate is ticked. That is what makes it the gate
#               probe: scatter8 with Annotate OFF contributes only its eight
#               formula lines and fits, so it cannot show the over-cap
#               disclosure being withheld from the figure. This one can.
#
#   barmix      Four groups. G2 holds a single observation, so its SE is
#               undefined by definition and its whisker cannot be drawn. G3
#               holds no usable observation at all.
#
#   barzero     BYTE-FOR-BYTE the same construction as barmix except that G3's
#               three rows carry a genuine measured 0.0 instead of a blank.
#               The pair is the whole point of defect 2: before the fix
#               @emlMeasureBarData handed both cases mean = 0, so both drew
#               the same bar of height zero and the reader could not tell a
#               missing group from a measured one. The two PNGs are compared
#               by content in validate/v29_figure_disclosure.R.
#
#   gviolin25   Four categories x TWENTY-FIVE sub-groups. @emlSetColorPalette
#   gbox25      holds 8 hues x 3 fill patterns = 24 distinguishable styles, so
#               the twenty-fifth would be drawn exactly like one already on the
#               figure, and is dropped. The cap is legitimate; before v1.22 the
#               drop was silent, and the legend still listed the sub-group that
#               had no violin anywhere on the figure. The cap was TEN until
#               v1.23 — a number that was wrong in both directions, since slots
#               9 and 10 of the old palette were literal duplicates of 1 and 2
#               (D127) while eight genuinely distinct styles went unused.
#
# Prints the same LEDGER / FIGLINE / SUBTITLE records case.praat prints, plus
# one case-specific record per family so the validator can read the counts and
# the names out of a real render rather than out of the source.
# ---------------------------------------------------------------------------
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder, which is two levels below the repository root, the same
; depth as harness/stress_cases/. So the prelude's own "../../plugin/..."
; lines resolve correctly too. Absolute paths here meant a copy of the repo
; silently tested the ORIGINAL tree. See harness/_env.sh.
include ../stress_cases/_prelude.praat

case$ = environment$ ("EML_CASE")
annotate = number (environment$ ("EML_ANNOTATE"))
if annotate = undefined
    annotate = 0
endif

# The same sentinel case.praat uses. emlSubtitle$ is the user's field and no
# draw procedure may touch it; asserted on every one of these cases too.
emlSubtitle$ = "SENTINEL-SUBTITLE"

annotStyle$ = "stars"
chartName$ = ""

if case$ = "scatter8" or case$ = "scatter21"
    # --- Over-cap scatter -------------------------------------------------
    chartName$ = "Scatter plot"
    if case$ = "scatter8"
        nG = 8
        annotCorrType$ = "both"
    else
        nG = 21
        # No correlations: the formula line alone, one per group, so the
        # overflow does not depend on Annotate.
        annotCorrType$ = ""
    endif
    nPer = 8
    scatterRegressionLine = 1
    scatterShowFormula = 1
    scatterShowDots = 1
    # 0 = no reporter output. The reporters print several screens per group
    # and none of it is what this case measures.
    scatterAnalysisType = 0
    scatterDotSize = 2

    tbl = Create Table with column names: "oc", nG * nPer, "grp x y"
    for i to nG * nPer
        g = (i - 1) div nPer + 1
        k = (i - 1) mod nPer + 1
        Set string value: i, "grp", "Group" + string$ (g)
        Set numeric value: i, "x", k
        ; Three blank cells, so the dropped-row disclosure is in play too:
        ; before the fix it was the line the over-cap box pushed out.
        if i = 17 or i = 34 or i = 51
            Set string value: i, "y", ""
        else
            Set numeric value: i, "y", g * 5 + k * 1.5 + (k mod 3)
        endif
    endfor
    Erase all
    @emlDrawScatterPlot: tbl, "Over-cap scatter", "X", "Y", 6, 4, "color", 1,
    ... "x", "y", "grp", 0, 0, 0, 0, annotate
    appendInfoLine: "SCATSTAT nGroups=", emlDrawScatterPlot.nGroups,
    ... " buffered=", emlDrawScatterPlot.pgN,
    ... " room=", emlDrawScatterPlot.pgRoom,
    ... " annotBlockN=", annotBlockN

elsif case$ = "barmix" or case$ = "barzero"
    # --- Missing group vs measured zero -----------------------------------
    # Identical tables but for G3's three value cells. G1 and G4 carry several
    # observations (SE defined); G2 carries exactly one (SE undefined by
    # definition); G3 is the group under test.
    #
    # G4 IS NEGATIVE ON PURPOSE. A bar chart of all-positive data puts the
    # zero baseline exactly on the axis floor, where a zero-height bar's
    # outline is drawn and then painted over by @emlDrawInnerBoxIf: measured
    # 7 Aug 2026, an all-positive barzero and barmix produced the SAME
    # ImageMagick pixel signature, so the figure could not tell a measured
    # zero from a missing group whichever way the guard went. With a negative
    # group present the axis floor drops below zero, the baseline lifts into
    # the panel, and a measured zero draws a visible bar outline there while
    # a missing group draws nothing at all. That is the pixel difference this
    # pair exists to assert, and it holds with Annotate OFF — where the
    # ruling puts no words on the figure at all.
    chartName$ = "Bar chart"
    tbl = Create Table with column names: "bz", 10, "grp val"
    for i to 10
        if i <= 3
            g$ = "G1"
            v = 18 + i
        elsif i = 4
            g$ = "G2"
            v = 25
        elsif i <= 7
            g$ = "G3"
            v = 0
        else
            g$ = "G4"
            v = -4 - i
        endif
        Set string value: i, "grp", g$
        if g$ = "G3" and case$ = "barmix"
            Set string value: i, "val", ""
        else
            Set numeric value: i, "val", v
        endif
    endfor
    Erase all
    ; errorMode 1 = SE, so G2's single observation yields an undefined error.
    @emlDrawBarChart: tbl, "Zero or absent", "Group", "Value", 6, 4,
    ... "color", 1, "grp", "val", 1, "", 0, 0
    appendInfoLine: "BARSTAT nGroups=", emlBarData_nGroups,
    ... " skippedBars=", emlDrawBarChart.nSkippedBars,
    ... " skippedErrors=", emlDrawBarChart.nSkippedErrors,
    ... " invalidGroups=", emlBarData_nInvalidGroups,
    ... " names=[", emlDrawBarChart.skippedBars$, "]"
    for g to emlBarData_nGroups
        meanDef = 1
        if emlBarData_mean[g] = undefined
            meanDef = 0
        endif
        errDef = 1
        if emlBarData_error[g] = undefined
            errDef = 0
        endif
        meanShown$ = "undefined"
        if meanDef = 1
            meanShown$ = fixed$ (emlBarData_mean[g], 4)
        endif
        ; valid/errorDefined are the FLAGS the measurement sets; meanDefined
        ; and errorSlotDefined are read back off the stored values. v3.23's
        ; invariant is that each pair agrees, and only printing both lets the
        ; validator say so.
        appendInfoLine: "BARGROUP ", g, " label=", emlBarData_label$[g],
        ... " valid=", emlBarData_valid[g],
        ... " meanDefined=", meanDef, " mean=", meanShown$,
        ... " errorDefined=", emlBarData_errorDefined[g],
        ... " errorSlotDefined=", errDef
    endfor

elsif case$ = "gviolin25" or case$ = "gbox25"
    # --- Twenty-fifth sub-group --------------------------------------------
    # Labels are zero-padded so alphabetical order and encounter order agree:
    # P25 is the twenty-fifth either way, and it is the one that must be named.
    nCat = 4
    nSub = 25
    nPer = 4
    tbl = Create Table with column names: "gs", nCat * nSub * nPer,
    ... "cond sub v"
    row = 0
    for c to nCat
        for s to nSub
            for k to nPer
                row = row + 1
                Set string value: row, "cond", "C" + string$ (c)
                if s < 10
                    Set string value: row, "sub", "P0" + string$ (s)
                else
                    Set string value: row, "sub", "P" + string$ (s)
                endif
                Set numeric value: row, "v", 10 + c * 2 + s + (k mod 3)
            endfor
        endfor
    endfor
    Erase all
    if case$ = "gviolin25"
        chartName$ = "Grouped violin"
        @emlDrawGroupedViolin: tbl, "Twenty-five sub-groups", "Condition",
        ... "Value", 6, 4, "color", 1, "cond", "sub", "v", 0, 0
        appendInfoLine: "SUBSTAT nSubs=", emlDrawGroupedViolin.nSubs,
        ... " drawn=", emlDrawGroupedViolin.nSubsDrawn,
        ... " dropped=", emlDrawGroupedViolin.nSubsDropped,
        ... " droppedRows=", emlDrawGroupedViolin.nDroppedSubRows,
        ... " legendN=", legendN,
        ... " names=[", emlDrawGroupedViolin.droppedSubs$, "]"
    else
        chartName$ = "Grouped box plot"
        @emlDrawGroupedBoxPlot: tbl, "Twenty-five sub-groups", "Condition",
        ... "Value", 6, 4, "color", 1, "cond", "sub", "v", 0, 0
        appendInfoLine: "SUBSTAT nSubs=", emlDrawGroupedBoxPlot.nSubs,
        ... " drawn=", emlDrawGroupedBoxPlot.nSubsDrawn,
        ... " dropped=", emlDrawGroupedBoxPlot.nSubsDropped,
        ... " droppedRows=", emlDrawGroupedBoxPlot.nDroppedSubRows,
        ... " legendN=", legendN,
        ... " names=[", emlDrawGroupedBoxPlot.droppedSubs$, "]"
    endif

else
    exitScript: "unknown EML_CASE: ", case$, newline$
endif

appendInfoLine: "LEDGER case=", case$, " chart=", emlDiscloseChart$,
... " annotate=", annotate,
... " info=", emlDiscloseInfoN, " fig=", emlDiscloseFigN
for li to emlDiscloseFigN
    appendInfoLine: "FIGLINE ", li, ": ", emlDiscloseFigLabel$[li]
endfor
appendInfoLine: "SUBTITLE [", emlSubtitle$, "]"
appendInfoLine: "CHARTNAME [", chartName$, "]"

@stressSave: 6, 4

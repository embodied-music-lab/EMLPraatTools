# ============================================================================
# Q-Q drive — headless exercise of @emlDrawQQPlot for ONE column.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Drawing procedures do not call beginPause:, so the whole Q-Q path runs under
# `praat --run` with no X server. That is what makes it testable: this driver
# calls exactly the procedure the Draw button calls, with exactly the vector
# the wrapper hands it, and records three things —
#
#   <case>_points.csv   the plotted point pairs, theoretical against sample
#   <case>_status.csv   n, dropped rows, refusal flag, refusal text, fit line
#   <case>.png          the rendered figure, as visual evidence
#
# The column is extracted with the same "Get value: row, col — keep if not
# undefined" loop @emlRunNormalityAnalysis uses, so the vector under test is
# the vector the checker tested, not a cleaner one prepared for the occasion.
#
# CSV headers are written UNQUOTED. Praat's own CSV reader does not strip
# quotes from header cells, so a quoted header would come back with the quotes
# embedded in the column name.
#
# Environment:
#   EML_QQ_INPUT   path to the input CSV
#   EML_QQ_COL     column to plot
#   EML_QQ_CASE    case name, used for the output filenames
#   EML_QQ_OUTDIR  directory for the three outputs
# ============================================================================

include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/graphs/eml-draw-qq.praat

# Praat writes UTF-16 on Linux unless told otherwise, and R's read.csv reads
# UTF-8. Without this every output file is unreadable by the validator.
Text writing preferences: "UTF-8"

@emlInitDrawingDefaults

src$ = environment$ ("EML_QQ_INPUT")
col$ = environment$ ("EML_QQ_COL")
case$ = environment$ ("EML_QQ_CASE")
outDir$ = environment$ ("EML_QQ_OUTDIR")

pointsOut$ = outDir$ + "/" + case$ + "_points.csv"
statusOut$ = outDir$ + "/" + case$ + "_status.csv"
figOut$ = outDir$ + "/" + case$ + ".png"
chromeOut$ = outDir$ + "/" + case$ + "_chrome.png"

writeInfoLine: "QQ drive: case=", case$, " col=", col$, " src=", src$

tbl = Read Table from comma-separated file: src$
selectObject: tbl
nRows = Get number of rows

# Same extraction as @emlRunNormalityAnalysis: every row, undefined dropped.
raw# = zero# (nRows)
for iRow from 1 to nRows
    selectObject: tbl
    raw# [iRow] = Get value: iRow, col$
endfor

@emlDrawQQPlot: raw#, col$, 6, 4.5, "color", 1

# Object-leak assertion, taken HERE and not after the save: @emlDrawQQPlot
# builds a temporary Table, and the input Table is the only object that should
# survive the call. Counting after the pre-save "select all / Remove" would
# assert nothing, because that clears the list either way.
select all
objectsAfterDraw = numberOfSelected ()

drew = emlDrawQQPlot.drew
err$ = emlDrawQQPlot.error$
nPts = emlDrawQQPlot.n
nDrop = emlDrawQQPlot.nDropped

# Refusal text goes into a CSV cell, so commas are neutralised rather than
# quoted — Praat's reader would not strip the quotes on the way back in and
# the validator reads this file with read.csv either way.
errClean$ = replace$ (err$, ",", ";", 0)
if errClean$ = ""
    errClean$ = "-"
endif

slope$ = "NA"
intercept$ = "NA"
swW$ = "NA"
swP$ = "NA"
if drew = 1
    slope$ = fixed$ (emlDrawQQPlot.slope, 12)
    intercept$ = fixed$ (emlDrawQQPlot.intercept, 12)
    swW$ = fixed$ (emlDrawQQPlot.w, 12)
    swP$ = fixed$ (emlDrawQQPlot.p, 12)
endif

refused = 1 - drew

writeFile: statusOut$, "case,column,nrows,n,ndropped,refused,reason,"
... + "slope,intercept,sw_w,sw_p,objects_after_draw" + newline$
appendFile: statusOut$, case$, ",", col$, ",", string$ (nRows), ",",
... string$ (nPts), ",", string$ (nDrop), ",", string$ (refused), ",",
... errClean$, ",", slope$, ",", intercept$, ",", swW$, ",", swP$, ",",
... string$ (objectsAfterDraw), newline$

# The plotted pairs. On a refusal the file is written with a header and no
# rows, so the validator can tell "refused" from "the driver never ran".
writeFile: pointsOut$, "i,theoretical,sample" + newline$
if drew = 1
    for i from 1 to nPts
        appendFile: pointsOut$, string$ (i), ",",
        ... fixed$ (emlShapiroWilk.m# [i], 15), ",",
        ... fixed$ (emlShapiroWilk.sorted# [i], 15), newline$
    endfor
endif

# Figure. Clearing the object list first is the only reliable way to reach a
# Picture-window command from a script (see harness/stress_cases/_prelude).
if drew = 1
    select all
    nSel = numberOfSelected ()
    if nSel > 0
        Remove
    endif
    @emlAssertFullViewport
    Save as 300-dpi PNG file: figOut$
    appendInfoLine: "SAVED ", figOut$

    # ── Chrome-only companion figure ──────────────────────────────────────
    # A figure that renders title, axes, gridlines and NOTHING ELSE is a
    # valid PNG and passes every numeric check — the BLANK_FRAME defect
    # elsewhere in this repo is exactly that. A fixed ink-fraction threshold
    # cannot separate it from a legitimately sparse Q-Q: the n = 3 case is
    # 1.8% ink and an empty frame of the same chrome is 1.5%.
    #
    # So the threshold is measured rather than guessed. This redraws the SAME
    # figure with the dots and the reference line suppressed and saves it
    # beside the real one; the shell driver then requires the real figure to
    # carry strictly more ink than its own chrome. Nothing here touches
    # @emlDrawQQPlot — the point table is rebuilt in the harness from the
    # normal scores the procedure left behind.
    chrome = Create Table with column names: "eml_qq_chrome", nPts,
    ... "theoretical sample"
    selectObject: chrome
    for i from 1 to nPts
        Set numeric value: i, "theoretical", emlShapiroWilk.m# [i]
        Set numeric value: i, "sample", emlShapiroWilk.sorted# [i]
    endfor

    @emlSanitizeLabel: col$
    disp$ = emlSanitizeLabel.result$
    emlSubtitle$ = "n = " + string$ (nPts) + ", Blom plotting positions"
    if nDrop > 0
        emlSubtitle$ = emlSubtitle$ + "; " + string$ (nDrop)
        ... + " row(s) excluded as missing"
    endif
    scatterShowDots = 0
    scatterRegressionLine = 0

    Erase all
    @emlResetDrawnExtent
    Select outer viewport: 0, 6, 0, 4.5
    @emlDrawScatterPlot: chrome, "Normal Q-Q plot: " + disp$,
    ... "Theoretical quantiles (z)", "Sample quantiles: " + disp$,
    ... 6, 4.5, "color", 1, "theoretical", "sample", "", 0, 0, 0, 0, 0

    select all
    nSel = numberOfSelected ()
    if nSel > 0
        Remove
    endif
    @emlAssertFullViewport
    Save as 300-dpi PNG file: chromeOut$
    appendInfoLine: "SAVED-CHROME ", chromeOut$
else
    appendInfoLine: "EXPECTED-REFUSAL ", err$
endif

appendInfoLine: "OBJECTS-AFTER-DRAW ", objectsAfterDraw

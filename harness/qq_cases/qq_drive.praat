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
#   <case>_points.csv     the plotted point pairs, theoretical against sample
#   <case>_status.csv     n, dropped rows, refusal flag, refusal text, fit
#                         line, the emlSubtitle$ sentinel, disclosure counts
#   <case>_disclosure.tsv the disclosure lines that reached the FIGURE
#   <case>.png            the rendered figure, as visual evidence
#
# DISCLOSURE (v1.1, 7 Aug 2026)
# ----------------------------
# @emlDrawQQPlot used to write its "n = N, Blom plotting positions" caption
# into emlSubtitle$, the user's own field, and so did this driver when it
# rebuilt the chrome reference. Both are gone. Two things are recorded here
# so validate/v23_qq_points.R can hold the replacement to its rule:
#
#   the sentinel   emlSubtitle$ is set to SENTINEL-SUBTITLE before the call
#                  and written to the status CSV after it. Anything other than
#                  the sentinel coming back means the Q-Q path wrote to the
#                  user's field. Same sentinel and same idea as
#                  harness/disclosure/case.praat.
#   the ledger     @emlDiscloseBegin leaves emlDiscloseFigN and
#                  emlDiscloseFigLabel$[] behind — what actually reached the
#                  FIGURE, as opposed to the Info window. The Info channel is
#                  visible in <case>.log; the figure channel is not, short of
#                  decoding a PNG, so it is dumped to <case>_disclosure.tsv.
#                  Tab-separated because the disclosure text contains commas.
#
# EML_QQ_ANNOTATE drives the gate. The same case is run twice by
# harness/qq_drive.sh, once with it unset and once with it 1, and the two
# runs must differ: no lines on the figure with Annotate off, lines on it with
# Annotate on, and the Info window carrying them either way.
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
#   EML_QQ_OUTDIR  directory for the outputs
#   EML_QQ_ANNOTATE  "1" to tick Annotate, anything else to leave it off
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

@emlInitializeDrawingDefaults

src$ = environment$ ("EML_QQ_INPUT")
col$ = environment$ ("EML_QQ_COL")
case$ = environment$ ("EML_QQ_CASE")
outDir$ = environment$ ("EML_QQ_OUTDIR")

pointsOut$ = outDir$ + "/" + case$ + "_points.csv"
statusOut$ = outDir$ + "/" + case$ + "_status.csv"
discOut$ = outDir$ + "/" + case$ + "_disclosure.tsv"
figOut$ = outDir$ + "/" + case$ + ".png"
chromeOut$ = outDir$ + "/" + case$ + "_chrome.png"

# The user's Annotate tick. @emlDiscloseBegin reads this global through
# variableExists, so leaving it undefined would also mean "off" — it is set
# explicitly either way so that the OFF direction is a deliberate 0 under
# test and not an accident of the harness never having defined it.
if environment$ ("EML_QQ_ANNOTATE") = "1"
    annotate = 1
else
    annotate = 0
endif

writeInfoLine: "QQ drive: case=", case$, " col=", col$, " src=", src$,
... " annotate=", annotate

tbl = Read Table from comma-separated file: src$
selectObject: tbl
nRows = Get number of rows

# Same extraction as @emlRunNormalityAnalysis: every row, undefined dropped.
raw# = zero# (nRows)
for iRow from 1 to nRows
    selectObject: tbl
    raw# [iRow] = Get value: iRow, col$
endfor

# emlSubtitle$ SENTINEL. This is the user's field: the graphs form asks for
# it ("Subtitle") and persists it to config. @emlDrawQQPlot must come back
# having left it exactly as it found it — not saved-and-restored around a
# write, which is what it used to do and which still put words the user never
# typed onto the DRAWN figure. The value is echoed into the status CSV.
emlSubtitle$ = "SENTINEL-SUBTITLE"

@emlDrawQQPlot: raw#, col$, 6, 4.5, "color", 1

subtitleAfter$ = emlSubtitle$

# The disclosure ledger. Absent on a refusal, because @emlDiscloseBegin is
# only reached once the figure is going to be drawn — hence variableExists
# rather than a bare read, which Praat aborts on.
figN = 0
infoN = 0
if variableExists ("emlDiscloseFigN")
    figN = emlDiscloseFigN
endif
if variableExists ("emlDiscloseInfoN")
    infoN = emlDiscloseInfoN
endif

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
... + "slope,intercept,sw_w,sw_p,objects_after_draw,"
... + "annotate,subtitle_after,disclose_fig_n,disclose_info_n" + newline$
appendFile: statusOut$, case$, ",", col$, ",", string$ (nRows), ",",
... string$ (nPts), ",", string$ (nDrop), ",", string$ (refused), ",",
... errClean$, ",", slope$, ",", intercept$, ",", swW$, ",", swP$, ",",
... string$ (objectsAfterDraw), ",", string$ (annotate), ",",
... subtitleAfter$, ",", string$ (figN), ",", string$ (infoN), newline$

# What reached the FIGURE, one line per disclosure, in order. Tab-separated:
# the disclosure text contains commas and Praat's CSV reader does not strip
# quotes, so quoting would put the quotes inside the value on the way back.
# The header is written even on a refusal, so the validator can tell "nothing
# was disclosed" from "the driver never ran".
writeFile: discOut$, "i" + tab$ + "text" + newline$
for i from 1 to figN
    appendFile: discOut$, string$ (i), tab$, emlDiscloseFigLabel$ [i],
    ... newline$
endfor

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

    # No subtitle is written here either. The chrome reference exists to
    # measure the ink of the figure's OWN furniture, so it has to carry the
    # same furniture the real figure carries and nothing else. Writing a
    # caption into emlSubtitle$ — which is what this driver used to do,
    # mirroring the defect in @emlDrawQQPlot — put a line of text on the
    # reference that the real figure no longer has.
    #
    # The disclosure box is deliberately NOT reproduced here. It is content,
    # not chrome. With Annotate on, the box adds ink the reference does not
    # have, which only makes the "more ink than its own chrome" test easier
    # to pass; the blank-frame protection for those cases comes from the
    # Annotate-off run of the same case, which draws the same dots and the
    # same line and has no box at all.
    @emlSanitizeLabel: col$
    disp$ = emlSanitizeLabel.result$
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

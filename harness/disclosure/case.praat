# ---------------------------------------------------------------------------
# One disclosure case: one draw procedure, one Annotate setting, one data set.
#
# Driven by harness/disclosure/run.sh, which sets:
#   EML_CHART     ts | tsci | spaghetti | bar | violin | scatter | box |
#                 hist | gviolin | gbox
#   EML_ANNOTATE  0 or 1     — the user's Annotate tick
#   EML_DIRTY     0 or 1     — 0 = clean data, 1 = six undefined values
#   EML_OUT       PNG path   — read by @stressSave in the shared prelude
#
# The fixture is ONE table, 20 rows, shaped so that every one of the ten
# procedures has the columns it needs. Six values are blanked when EML_DIRTY
# is 1, which is the case measured on 7 Aug 2026: @emlDrawViolinPlot said
# "6 row(s) skipped", @emlDrawHistogram said nothing and drew 14 rows while
# the reader believed 20.
#
# Rows: 20. subj = 1..4 cycling, t = 1..5 (four observations per time point),
# cond = C1..C5, grp = G1..G4, sub = P1..P2.
#
# After the draw the DISCLOSURE LEDGER is printed. That is what
# validate/v29_figure_disclosure.R reads: the Info channel is in the
# transcript already, but what reached the FIGURE is not observable from a
# PNG in base R, so the procedure is asked directly.
# ---------------------------------------------------------------------------
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder, which is two levels below the repository root, the same
; depth as harness/stress_cases/. So the prelude's own "../../plugin/..."
; lines resolve correctly too. Absolute paths here meant a copy of the repo
; silently tested the ORIGINAL tree. See harness/_env.sh.
include ../stress_cases/_prelude.praat

chart$ = environment$ ("EML_CHART")
annotate = number (environment$ ("EML_ANNOTATE"))
dirty = number (environment$ ("EML_DIRTY"))
if annotate = undefined
    annotate = 0
endif
if dirty = undefined
    dirty = 0
endif

# emlSubtitle$ sentinel. Every draw procedure is called with this set; the
# validator asserts it comes back byte-identical. It is the check that stops
# the subtitle hijack recurring.
emlSubtitle$ = "SENTINEL-SUBTITLE"

# The six rows that carry no value when EML_DIRTY = 1.
nRowsFixture = 20
tbl = Create Table with column names: "disc", nRowsFixture,
... "grp sub cond id t x v err"
for i to nRowsFixture
    subj = (i - 1) mod 4 + 1
    tt = (i - 1) div 4 + 1
    Set string value: i, "grp", "G" + string$ (subj)
    Set string value: i, "sub", "P" + string$ ((i - 1) mod 2 + 1)
    Set string value: i, "cond", "C" + string$ (tt)
    Set string value: i, "id", "S" + string$ (subj)
    Set numeric value: i, "t", tt
    Set numeric value: i, "x", i
    Set numeric value: i, "err", 1.5
    blank = 0
    if dirty = 1
        # Six rows: 3, 7, 11, 14, 17, 20. Spread across groups, conditions
        # and time points so no single group or time is wiped out.
        if i = 3 or i = 7 or i = 11
            blank = 1
        endif
        if i = 14 or i = 17 or i = 20
            blank = 1
        endif
    endif
    if blank = 1
        Set string value: i, "v", ""
    else
        Set numeric value: i, "v", 10 + 2 * tt + subj + (i mod 3)
    endif
endfor

Erase all

if chart$ = "ts"
    @emlDrawTimeSeries: tbl, "Time series", "Time", "Value", 6, 4,
    ... "color", 1, "t", "v", "", 0, 0, 0, 0
elsif chart$ = "tsci"
    @emlDrawTimeSeriesCI: tbl, "Time series CI", "Time", "Value", 6, 4,
    ... "color", 1, "t", "v", "", 0, 0, 0, 0
elsif chart$ = "spaghetti"
    @emlDrawSpaghettiPlot: tbl, "Spaghetti", "Condition", "Value", 6, 4,
    ... "color", 1, "cond", "v", "id", "", 1, 0, 0
elsif chart$ = "bar"
    @emlDrawBarChart: tbl, "Bar chart", "Group", "Value", 6, 4,
    ... "color", 1, "grp", "v", 1, "", 0, 0
elsif chart$ = "violin"
    @emlDrawViolinPlot: tbl, "Violin", "Group", "Value", 6, 4,
    ... "color", 1, "grp", "v", 0, 0
elsif chart$ = "scatter"
    # Regression and formula off, so the annotation block holds the
    # disclosure and nothing else and the ledger is unambiguous.
    scatterRegressionLine = 0
    scatterShowFormula = 0
    scatterAnalysisType = 0
    @emlDrawScatterPlot: tbl, "Scatter", "X", "Value", 6, 4,
    ... "color", 1, "x", "v", "", 0, 0, 0, 0, annotate
elsif chart$ = "box"
    @emlDrawBoxPlot: tbl, "Box", "Group", "Value", 6, 4,
    ... "color", 1, "grp", "v", 0, 0
elsif chart$ = "hist"
    @emlDrawHistogram: tbl, "Histogram", "Value", "Frequency", 6, 4,
    ... "color", 1, "v", "", 0, 1, 0, 0, 0
elsif chart$ = "gviolin"
    @emlDrawGroupedViolin: tbl, "Grouped violin", "Condition", "Value", 6, 4,
    ... "color", 1, "cond", "sub", "v", 0, 0
elsif chart$ = "gbox"
    @emlDrawGroupedBoxPlot: tbl, "Grouped box", "Condition", "Value", 6, 4,
    ... "color", 1, "cond", "sub", "v", 0, 0
else
    exitScript: "unknown EML_CHART: ", chart$, newline$
endif

appendInfoLine: "LEDGER chart=", emlDiscloseChart$,
... " annotate=", annotate, " dirty=", dirty,
... " info=", emlDiscloseInfoN, " fig=", emlDiscloseFigN
for li to emlDiscloseFigN
    appendInfoLine: "FIGLINE ", li, ": ", emlDiscloseFigLabel$[li]
endfor
appendInfoLine: "SUBTITLE [", emlSubtitle$, "]"

@stressSave: 6, 4

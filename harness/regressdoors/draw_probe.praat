# ============================================================================
# harness/regressdoors/draw_probe.praat -- the DRAWN per-group regression
#                                          lines, for the same leg5 fixture
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Both regression doors' Draw button sets emlGraphsPresetGroupCol$ and hands
# off to the graphs form, which reaches @emlDrawScatterPlot. This calls that
# procedure directly (the same choice harness/corrscope/probe.praat makes,
# and for the same reason: it IS the shared call), with the group column the
# doors preset, and prints the slope of every line it actually DRAWS.
#
# The drawn slope is not the reported one by construction: the report comes
# from @emlLinearRegression's least-squares, the line from
# r * (sd(y)/sd(x)) (eml-draw-procedures.praat, per-group branch). They are
# the same quantity algebraically; whether they are the same NUMBER on this
# fixture is the question, and it is asked here rather than assumed.
#
#     source harness/_env.sh
#     "$PRAAT" $PRAAT_TRUST --run harness/regressdoors/draw_probe.praat
# ============================================================================
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

x# = { 1,2,3,4,5,6,7,8,9,10, 1,2,3,4,5,6,7,8,9,10 }
y# = { 7.30,8.80,11.10,12.60,15.20,16.90,19.30,20.70,23.10,24.80,
    ... 97.80,96.30,93.90,92.20,89.70,88.10,85.80,84.20,81.90,80.30 }
g$# = { "A","A","A","A","A","A","A","A","A","A",
    ... "B","B","B","B","B","B","B","B","B","B" }
n = size (x#)
tab = Create Table with column names: "leg5", n, { "x", "y", "group" }
for i from 1 to n
    selectObject: tab
    Set numeric value: i, "x", x# [i]
    Set numeric value: i, "y", y# [i]
    Set string value: i, "group", g$# [i]
endfor

@emlInitDrawingDefaults
annotate = 1
scatterAnalysisType = 2
annotCorrType$ = "pearson"
annotStyle$ = "p-value"
scatterShowDots = 1
scatterDotSize = 2
scatterRegressionLine = 1
scatterShowFormula = 1
scatterCorrScope = 1

selectObject: tab
@emlDrawScatterPlot: tab, "Regression doors probe", "x", "y", 6, 4, "color", 4,
... "x", "y", "group", 0, 0, 0, 0, 1

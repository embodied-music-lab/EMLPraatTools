# ---------------------------------------------------------------------------
# harness/secondaxis/fixture.praat
#
# The shared fixture for the second vertical axis and the line-style change
# order. Included by every case; never run on its own.
#
# THE INCLUDE LIST IS THE FORM'S, for the reason harness/compose/fixture.praat
# gives: the request globals are set by the graphs form and read by the draw
# layer, so a probe that included only the draw library would be measuring a
# code path the user does not press.
#
# PATHS ARE RELATIVE, so a copy of this repository tests its own plugin.
# ---------------------------------------------------------------------------
include ../../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat
include ../../plugin_EML_StatsGraphs/stats/eml-output.praat
include ../../plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat

@emlInitializeDrawingDefaults
@emlLoadConfig

secondOut$ = environment$ ("EML_OUT")
if secondOut$ = ""
    secondOut$ = "unnamed.png"
endif

; TWO SCALES THAT CANNOT SHARE AN AXIS, which is the whole case for the
; feature. `f0` is a fundamental frequency in hertz, 180 to 260; `cq` is a
; contact quotient, 0.38 to 0.62 -- a proportion. Plotted on one axis the
; second series is a flat line on the floor. `g` splits the same rows into two
; singers for the grouped case, and `noise` is a text column, for the case
; that asks for a second axis on a column that is not numeric.
include data.praat
objectId = selected ("Table")

; --- the form's variable set, as @emlGraphsWorkflow leaves it -------------
title$ = "Second axis"
x_axis_label$ = "Time (s)"
y_axis_label$ = "F0 (Hz)"
figure_width = 6
figure_height = 4
colorMode$ = "color"
gridline_mode = 1
annotate = 0
timeColName$ = "t"
valueColName$ = "f0"
groupColName$ = ""
timeMin = 0
timeMax = 0
valueMin = 0
valueMax = 0
ciMode = 0
errorBarMode = 0
errorColName$ = ""
scatterXCol$ = "t"
scatterYCol$ = "f0"
scatterGroupCol$ = "g"
scatterXMin = 0
scatterXMax = 0
histValueCol$ = "f0"
histGroupCol$ = "g"
histBinCount = 0
histDisplayMode = 1
histFreqMax = 0
gvCatCol$ = "g"
gvSubCol$ = "g"
gvValueCol$ = "f0"
gbCatCol$ = "g"
gbSubCol$ = "g"
gbValueCol$ = "f0"
spCondCol$ = "t"
spValueCol$ = "f0"
spSubjectCol$ = "g"
spGroupCol$ = "g"
spShowMean = 1
f0YUnit = 1
tsShowCI = 0
ltasShowCurve = 1
ltasShowBars = 0
ltasShowPoles = 0
ltasShowSpeckles = 0
graph_type = 5

matrixPanelHeight = 0
matrixGap = 0
totalCanvasHeight = figure_height
annotMatrixN = 0
annotBlockN = 0
config_legendPlacement = 1
config_showAdvanced = 0
emlLegendPlacement = 1
@emlClearAnnotations

; ---------------------------------------------------------------------------
; @secondSave -- the union the plugin itself tracks, then the file.
; Same shape as harness/compose's: the saved image is @emlAssertFullViewport's
; rectangle, so what is written is what the plugin says the page is.
; ---------------------------------------------------------------------------
procedure secondSave
    @emlAssertFullViewport
    appendInfoLine: "UNION ", emlDrawnMinX, " ", emlDrawnMaxX, " ",
    ... emlDrawnMinY, " ", emlDrawnMaxY
    Save as 300-dpi PNG file: secondOut$
endproc

; ---------------------------------------------------------------------------
; @secondReport -- what the draw resolved, printed for the TSV. Read from the
; draw procedure's own published names, not recomputed here.
; ---------------------------------------------------------------------------
procedure secondReport
    appendInfoLine: "LEFT ", emlDrawTimeSeries.axisYMin, " ",
    ... emlDrawTimeSeries.axisYMax
    appendInfoLine: "RIGHT ", emlDrawTimeSeries.axisRightMin, " ",
    ... emlDrawTimeSeries.axisRightMax
    appendInfoLine: "SECONDON ", emlDrawTimeSeries.secondOn
    appendInfoLine: "RIGHTSLOT ", emlDrawTimeSeries.rightSlot
    if emlDrawTimeSeries.secondOn = 1
        appendInfoLine: "RIGHTINK ",
        ... emlSetColorPalette.line$[emlDrawTimeSeries.rightSlot]
        appendInfoLine: "LEFTINK ", emlSetColorPalette.line$[1]
    endif
endproc

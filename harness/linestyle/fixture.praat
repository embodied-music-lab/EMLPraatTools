# ---------------------------------------------------------------------------
# harness/linestyle/fixture.praat
#
# The shared fixture for the line-style change order. Included by every case;
# never run on its own.
#
# THE INCLUDE LIST IS THE FORM'S, for the reason harness/compose/fixture.praat
# gives: emlLineStyle is set by the graphs form and read by the draw layer, so
# a probe that included only the draw library would be measuring a code path
# the user does not press.
#
# EVERY CASE PRESSES DRAW. @emlGraphsDrawWithLegendRoom is the form's own
# dispatch, at file scope precisely so a probe can drive it without a dialog,
# and @lsPress below states the pen the way the form states it -- through
# @emlGraphsPublishSeriesPens, from the per-type variable the dialog fills in,
# and takes it back afterwards through @emlGraphsResetSeriesPens. A case that
# assigned emlLineStyle directly would be testing the draw layer while
# claiming to test the feature.
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

@emlInitDrawingDefaults
@emlLoadConfig

lsOut$ = environment$ ("EML_OUT")
if lsOut$ = ""
    lsOut$ = "unnamed.png"
endif

include data.praat

; --- the form's variable set, as @emlGraphsWorkflow leaves it -------------
title$ = "Line style"
x_axis_label$ = "Time (s)"
y_axis_label$ = "Value"
figure_width = 6
figure_height = 4
colorMode$ = "color"
gridline_mode = 1
annotate = 0
timeColName$ = "t"
valueColName$ = "v"
groupColName$ = ""
timeMin = 0
timeMax = 0
valueMin = 0
valueMax = 0
ciMode = 0
errorBarMode = 0
errorColName$ = ""
scatterXCol$ = "t"
scatterYCol$ = "v"
scatterGroupCol$ = "g"
scatterXMin = 0
scatterXMax = 0
histValueCol$ = "v"
histGroupCol$ = "g"
histBinCount = 0
histDisplayMode = 1
histFreqMax = 0
gvCatCol$ = "g"
gvSubCol$ = "g"
gvValueCol$ = "v"
gbCatCol$ = "g"
gbSubCol$ = "g"
gbValueCol$ = "v"
spCondCol$ = "t"
spValueCol$ = "v"
spSubjectCol$ = "id"
spGroupCol$ = ""
spShowMean = 1
barGroupCol$ = "g"
barValueCol$ = "v"
barErrorMode = 1
barErrorCol$ = ""
violinGroupCol$ = "g"
violinValueCol$ = "v"
f0YUnit = 1
tsShowCI = 0
ampMin = 0
ampMax = 0
freqMin = 0
freqMax = 0
powerMin = 0
powerMax = 0
ltasShowCurve = 1
ltasShowBars = 0
ltasShowPoles = 0
ltasShowSpeckles = 0
graph_type = 5
objectId = lsTableId

; --- THE DIALOG VARIABLES @emlGraphsPublishSeriesPens READS ----------------
; The form seeds these once, inside its own init block, and each dialog then
; fills in the one it owns. A probe that presses Draw without opening a dialog
; has to seed them itself or the publish aborts at "Unknown variable" -- which
; is the whole point of the publish reading them by name: every type's answer
; is stated on every press, including the types that did not run.
f0LineStyle = 1
wavLineStyle = 1
specLineStyle = 1
ltasLineStyle = 1
tsLineStyle = 1
spLineStyle = 1
tsSecondAxis = 0
tsSecondColName$ = ""
tsSecondStyle = 3
secondMin = 0
secondMax = 0
tmpSecLabel$ = ""

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
; @lsSetType: .type -- point the press at one figure type and its object.
;
; The object a type requires is the object the form would have found selected:
; requiredType$[] in eml-graphs-form.praat is the same map, read there off the
; Objects window and written here by hand because a probe has no window.
; ---------------------------------------------------------------------------
procedure lsSetType: .type
    graph_type = .type
    if .type = 1
        objectId = lsPitchId
    elsif .type = 2
        objectId = lsSoundId
    elsif .type = 3
        objectId = lsSpectrumId
    elsif .type = 4
        objectId = lsLtasId
    else
        objectId = lsTableId
    endif
endproc

; ---------------------------------------------------------------------------
; @lsPress -- ONE PRESS OF DRAW, pens and all.
;
; The three lines the form runs around every dispatch, in the order the form
; runs them: state the whole request, draw, take the request back. The reset
; is INSIDE the press because the form puts it there -- a case that wanted to
; measure a figure drawn with the request still standing would have to say so.
; ---------------------------------------------------------------------------
procedure lsPress
    @emlGraphsPublishSeriesPens
    @emlGraphsDrawWithLegendRoom
    @emlGraphsResetSeriesPens
endproc

; ---------------------------------------------------------------------------
; @lsReport -- what the press asked for, printed for the TSV.
;
; emlLineStyle is read back BEFORE @emlGraphsResetSeriesPens can clear it, so
; @lsPress is not usable here; the cases print this immediately after their
; press from the per-type variable the dialog would have set, and the name is
; taken from the plugin's own @emlLineStyleName rather than restated.
; ---------------------------------------------------------------------------
procedure lsReport: .style
    @emlLineStyleName: .style
    appendInfoLine: "STYLE ", .style
    appendInfoLine: "STYLENAME ", emlLineStyleName.word$
    appendInfoLine: "TYPE ", graph_type
endproc

; ---------------------------------------------------------------------------
; @lsSave -- the union the plugin itself tracks, then the file. Same shape as
; harness/secondaxis's: what is written is what the plugin says the page is.
; ---------------------------------------------------------------------------
procedure lsSave
    @emlAssertFullViewport
    appendInfoLine: "UNION ", emlDrawnMinX, " ", emlDrawnMaxX, " ",
    ... emlDrawnMinY, " ", emlDrawnMaxY
    Save as 300-dpi PNG file: lsOut$
endproc

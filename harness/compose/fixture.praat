# ---------------------------------------------------------------------------
# harness/compose/fixture.praat
#
# The shared fixture and the form's variable set, as @emlGraphsWorkflow leaves
# it before it dispatches a draw. Included by every compose case; never run on
# its own.
#
# THE INCLUDE LIST IS THE FORM'S, and it has to be: the page-composition
# controls live in graphs/eml-graphs-form.praat, so a probe that included only
# the draw library would be measuring a different code path from the one the
# user presses. harness/legendroom/case.praat is the precedent and its header
# says why @emlGraphsDispatchDraw is drivable at all -- every argument it
# passes is a form global, so a probe that sets those globals reaches it with
# no dialog.
#
# PATHS ARE RELATIVE, so a copy of this repository tests its own plugin. See
# harness/stress_cases/_prelude.praat for the day that mattered.
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

; EML_OUT is set by run.sh for every case. The fallback is deliberately
; relative so that running a case by hand cannot write into another tree.
composeOut$ = environment$ ("EML_OUT")
if composeOut$ = ""
    composeOut$ = "unnamed.png"
endif

; Deterministic noise. Praat's Gaussian draw gives every run a different data
; set, and a case whose data churns cannot be compared with itself -- which is
; the whole point of the byte-identity case below. Same LCG the stress cases
; use; the seed is this harness's own.
composeRng = 20260818
procedure composeRnd
    composeRng = (1103515245 * composeRng + 12345) mod 2147483648
    .g = (composeRng / 2147483648 - 0.5) * 6
endproc

Create Table with column names: "compose", 0, "t v g s"
for i from 1 to 60
    Append row
    r = Get number of rows
    Set numeric value: r, "t", (i mod 10) + 1
    @composeRnd
    Set numeric value: r, "v", 100 + (i mod 5) * 12 + composeRnd.g
    Set string value: r, "g", "grp" + string$ ((i mod 5) + 1)
    Set numeric value: r, "s", ((i - 1) mod 6) + 1
endfor
objectId = selected ("Table")

; --- the form's variable set ------------------------------------------------
title$ = "Panel"
x_axis_label$ = "x"
y_axis_label$ = "y"
figure_width = 6
figure_height = 4
colorMode$ = "color"
gridline_mode = 1
annotate = 0
timeColName$ = "t"
valueColName$ = "v"
groupColName$ = "g"
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
spSubjectCol$ = "s"
spGroupCol$ = "g"
spShowMean = 1
f0YUnit = 1
tsShowCI = 0
ltasShowCurve = 1
ltasShowBars = 0
ltasShowPoles = 0
ltasShowSpeckles = 0

; The pre-dispatch state @emlGraphsWorkflow computes from the comparison
; matrix geometry. With no matrix panel the gap and the panel are both zero
; and the canvas is the figure.
matrixPanelHeight = 0
matrixGap = 0
totalCanvasHeight = figure_height
annotMatrixN = 0
annotBlockN = 0

; Placements other than 1 are only reachable from the advanced page, and
; @emlGraphsDispatchDraw rewrites anything else to 1 when this is 0. See
; harness/legendroom/case.praat, which measured that the hard way.
config_showAdvanced = 1
config_legendPlacement = 1

# @composePanel: .type, .originX, .originY, .erase, .placement, .title$
# One press of Draw, with the page controls this work added set to the values
# a user would have typed. Every case is written in terms of this so that no
# case can drive a different sequence from the one it is named for.
procedure composePanel: .type, .originX, .originY, .erase, .placement, .title$
    ; EVERY PRESS STARTS FROM AUTO, exactly as @emlGraphsWorkflow does at the
    ; top of a press. Without it a case inherits the previous case's widened
    ; axis -- measured in harness/legendroom, where one behaviour change was
    ; made to look like four.
    valueMin = 0
    valueMax = 0
    histFreqMax = 0
    ; The workflow recomputes this from the comparison-matrix geometry before
    ; every dispatch. With no matrix it is the figure's own height, and a case
    ; that changes figure_height between panels needs it to follow.
    totalCanvasHeight = figure_height + matrixGap + matrixPanelHeight
    graph_type = .type
    title$ = .title$
    config_legendPlacement = .placement
    emlEraseFirst = .erase
    emlPanelOriginX = .originX
    emlPanelOriginY = .originY
    @emlClearAnnotations
    @emlGraphsDrawWithLegendRoom
    appendInfoLine: "PANEL ", .title$, " type=", .type,
    ... " origin=", .originX, ",", .originY,
    ... " erase=", .erase, " placement=", .placement,
    ... " passes=", legendRoomPass
endproc

# @composeSave -- the plugin's own pre-save idiom, so that what this harness
# writes is what the Save panel writes. Anything clipped here is clipped in
# the product too.
procedure composeSave
    select all
    .nSel = numberOfSelected ()
    if .nSel > 0
        Remove
    endif
    @emlAssertFullViewport
    Save as 300-dpi PNG file: composeOut$
    appendInfoLine: "UNION ", fixed$ (emlDrawnMinX, 4), " ",
    ... fixed$ (emlDrawnMaxX, 4), " ", fixed$ (emlDrawnMinY, 4), " ",
    ... fixed$ (emlDrawnMaxY, 4)
    appendInfoLine: "SAVED ", composeOut$
endproc

# @composeSavePage: .padRight, .padBottom
# THE PAGE AND THE PARKED BAND IN ONE IMAGE. @composeSave above saves what the
# plugin saves -- the extent union, which deliberately EXCLUDES a separate
# legend, because that legend is a second file. This one is a harness-only
# view that takes both, so a picture can show where the reserved band sits in
# relation to the panels. Nothing in the plugin selects this rectangle.
procedure composeSavePage: .padRight, .padBottom
    select all
    .nSel = numberOfSelected ()
    if .nSel > 0
        Remove
    endif
    .right = emlDrawnMaxX
    .bottom = emlDrawnMaxY
    if emlLegendSepActive = 1
        if emlLegendSepX1 > .right
            .right = emlLegendSepX1
        endif
        if emlLegendSepY1 > .bottom
            .bottom = emlLegendSepY1
        endif
        appendInfoLine: "PARK ", fixed$ (emlLegendSepY0, 4), " ",
        ... fixed$ (emlLegendSepY1, 4)
    endif
    appendInfoLine: "UNION ", fixed$ (emlDrawnMinX, 4), " ",
    ... fixed$ (emlDrawnMaxX, 4), " ", fixed$ (emlDrawnMinY, 4), " ",
    ... fixed$ (emlDrawnMaxY, 4)
    Select outer viewport: 0, .right + .padRight, 0, .bottom + .padBottom
    Save as 300-dpi PNG file: composeOut$
    appendInfoLine: "SAVED ", composeOut$
endproc

# ---------------------------------------------------------------------------
# harness/boxgeom/fixture.praat
#
# The shared fixture for the render-level box-geometry probe. Included by
# every case; never run on its own.
#
# WHAT THIS HARNESS IS FOR. Praat stores a viewport as an OUTER rectangle.
# `Select inner viewport` converts what it is given using the MARGINS IN
# EFFECT AT THAT MOMENT, and every later drawing command converts back using
# the margins in effect at ITS moment. Margin width is a function of font
# size. So a figure whose ambient font size changes between two
# coordinate-dependent commands draws those two commands on two different
# rectangles -- measured on Praat 6.6.30, a one-point difference puts the
# later rectangle about 2.9% narrower and 2.6% shorter. Nothing errors. The
# figure simply comes out with its frame inside its own gridlines, or its tick
# marks floating clear of the axis they belong to.
#
# The only place that mismatch is visible is the RENDERED PAGE, so this
# harness renders one and keeps the vector form of it. EPS is used rather than
# PNG because EPS states the path coordinates as numbers: the inner box, every
# tick mark and every stroke of data are all readable as device coordinates,
# and three witnesses to one rectangle can be compared without counting a
# single pixel.
#
# THE INCLUDE LIST IS THE FORM'S, for the reason harness/linestyle/fixture
# gives: the theme that decides the viewport is set up by the form's own
# dispatch, so a probe that included only the draw library would be measuring
# a code path the user does not press.
#
# THE AXIS IS PINNED TO THE DATA WHEREVER THE TYPE OFFERS THE CONTROL. That is
# what makes "the plotted extremes land on the box" an assertion rather than a
# hope: with the axis running exactly 1..12 and 10..120, the first and last
# points of the series ARE the corners of the inner box, and a box drawn on a
# different rectangle from the data has the data hanging outside it. A case
# whose type offers no such control says so, and declares which edges its data
# may be expected to reach.
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

bgOut$ = environment$ ("EML_OUT")
if bgOut$ = ""
    bgOut$ = "unnamed.eps"
endif

include data.praat

; --- the form's variable set, as @emlGraphsWorkflow leaves it -------------
title$ = "Box geometry"
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
; PINNED, and this is the whole point of the fixture. data.praat builds t over
; 1..12 and v over 10..120; stating the same numbers here makes the axis equal
; the data range, so the extreme data point sits ON the frame.
timeMin = 1
timeMax = 12
valueMin = 10
valueMax = 120
ciMode = 0
errorBarMode = 0
errorColName$ = ""
scatterXCol$ = "t"
scatterYCol$ = "v"
scatterGroupCol$ = ""
scatterXMin = 1
scatterXMax = 12
histValueCol$ = "v"
histGroupCol$ = ""
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
objectId = bgTableId

; --- THE DIALOG VARIABLES @emlGraphsPublishSeriesPens READS ----------------
; Seeded here for the reason harness/linestyle/fixture.praat states: a probe
; that presses Draw without opening a dialog has to state every type's answer,
; including the types that did not run, or the publish aborts on the first
; name it cannot read.
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
; @bgSetType: .type -- point the press at one figure type and its object.
;
; The object a type requires is the object the form would have found selected:
; requiredType$[] in eml-graphs-form.praat is the same map, read there off the
; Objects window and written here by hand because a probe has no window.
; ---------------------------------------------------------------------------
procedure bgSetType: .type
    graph_type = .type
    if .type = 1
        objectId = bgPitchId
    elsif .type = 2
        objectId = bgSoundId
    elsif .type = 3
        objectId = bgSpectrumId
    elsif .type = 4
        objectId = bgLtasId
    else
        objectId = bgTableId
    endif
endproc

; ---------------------------------------------------------------------------
; @bgPress -- ONE PRESS OF DRAW, stated the way the form states it.
;
; The three lines the form runs around every dispatch, in the order the form
; runs them. A case that reached into the draw library directly would be
; testing the library while claiming to test the figure the user gets, and the
; theme that decides the viewport is set up on this path and not on that one.
; ---------------------------------------------------------------------------
procedure bgPress
    @emlGraphsPublishSeriesPens
    @emlGraphsDrawWithLegendRoom
    @emlGraphsResetSeriesPens
endproc

; ---------------------------------------------------------------------------
; @bgSave: .reach$ -- the vector figure, and what the case claims about it.
;
; .reach$ names the edges of the inner box the case's DATA is expected to
; touch, out of "left", "right", "bottom", "top", space separated, or "none".
; It is a claim about the fixture, not about the renderer: a line chart whose
; axis was pinned to the data range touches all four, a bar chart whose x
; axis is a row of categories with half-slot padding touches neither side.
; The validator asserts containment on every case and reach only where a case
; claims it, so a case that claims nothing still catches a box drawn on the
; wrong rectangle -- the data spills OUT of it -- but claims no more than the
; fixture earns.
;
; The declared inner viewport is printed alongside. It is not what the check
; is built on -- the rectangle is read off the page, not off the intention --
; but when a case does go red it is the first number worth seeing.
; ---------------------------------------------------------------------------
procedure bgSave: .reach$
    appendInfoLine: "TYPE ", graph_type
    appendInfoLine: "REACH ", .reach$
    appendInfoLine: "DECLINNER ", emlSetAdaptiveTheme.innerLeft, " ",
    ... emlSetAdaptiveTheme.innerRight, " ",
    ... emlSetAdaptiveTheme.innerTop, " ",
    ... emlSetAdaptiveTheme.innerBottom
    appendInfoLine: "BODYSIZE ", emlSetAdaptiveTheme.bodySize
    @emlAssertFullViewport
    Save as EPS file: bgOut$
endproc

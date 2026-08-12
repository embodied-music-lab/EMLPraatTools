# ---------------------------------------------------------------------------
# PLACEMENT SWEEP over the FOUR NON-CATEGORICAL legend types.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Six graph types offer the Legend placement menu. Two of them --
# 11 Grouped Violin and 12 Grouped Box -- put a CATEGORY on the x axis and
# carry a comparison matrix below the plot; harness/legend/case.praat is the
# rig for those, and sections 1 to 9 of validate/v32_legend_geometry.R are
# measured on it. This file is the other four:
#
#     5   Line Chart (+/-CI)   @emlDrawTimeSeriesCI
#     8   Scatter Plot         @emlDrawScatterPlot
#    10   Histogram            @emlDrawHistogram   (overlay, grouped)
#    13   Spaghetti Plot       @emlDrawSpaghettiPlot
#
# None of them has a matrix panel, so the question here is narrower and
# sharper: does the PLOT RECTANGLE stay put across all five placements, does
# the SAVED IMAGE grow on the axis it is supposed to grow on, are the resolved
# axes the same in all five, and does placement 4 park a legend the save path
# can actually find.
#
# WHY IT IS DRIVEN BY THE DRIVER NOW. These four types were swept by hand on
# 9 August 2026 and the numbers went into audit/GRAPHING_PUSH_REMAINING.md
# section 1. A number in a markdown file is not a check -- section 7's
# standard is that nothing counts as validated until an authored R script
# tests the output -- so this file was rewritten to the harness's own calling
# convention (environment variables, the record lines emit_row reads, and
# @stressSave) and wired into harness/legend/run.sh as block 7. Section 11 of
# validate/v32_legend_geometry.R is the check.
#
# THE AXIS CONTRACT, AND WHY THIS FIXTURE IS WHERE IT IS PINNED. This file's
# first version carried a FINDING: the six types did not expose their resolved
# axes under one name -- 8, 10, 11 and 12 published .axisXMin.., while 5 and
# 13 published only .xMin.., so every caller outside the form had to know
# which convention its type followed and picking wrong was "Unknown variable:"
# at run time rather than at parse time. That is closed: all ten
# Table-consuming draw procedures now publish .axis* and it always means the
# range the axes were ACTUALLY drawn at.
#
# The contract's own note says .axis* is NOT an alias for .xMin, and the case
# that proves it is here: in @emlDrawScatterPlot the parameters .xMin/.xMax
# carry what the CALLER REQUESTED, with (0, 0) meaning auto. So this fixture
# reads BOTH spellings on every type and prints both, and section 11 asserts
# the thing that actually matters -- they agree on 5, 10 and 13, and on 8 they
# do NOT, because a caller reading .xMin uniformly there would silently get 0
# for an auto range instead of a wrong-variable error.
#
# Environment:
#     EML_GTYPE      5 | 8 | 10 | 13
#     EML_PLACEMENT  1..5
#     EML_VPW EML_VPH   figure size in inches
#     EML_MODE       "color" | "bw"
#     EML_OUT        where to save the figure
#     EML_CASE       the case name, echoed into the transcript
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
include _prelude.praat

caseName$ = environment$ ("EML_CASE")
if caseName$ = ""
    caseName$ = "sweep"
endif
gtype = number (environment$ ("EML_GTYPE"))
if gtype = undefined
    gtype = 8
endif
placement = number (environment$ ("EML_PLACEMENT"))
if placement = undefined
    placement = 1
endif
vpW = number (environment$ ("EML_VPW"))
if vpW = undefined
    vpW = 6
endif
vpH = number (environment$ ("EML_VPH"))
if vpH = undefined
    vpH = 4.5
endif
mode$ = environment$ ("EML_MODE")
if mode$ = ""
    mode$ = "color"
endif

Erase all
@emlInitDrawingDefaults

; Deterministic noise. randomGauss would give every placement a different data
; set, and the whole point of this sweep is that only the FURNITURE moves. An
; LCG, folded to roughly +/-1, scaled at the use site.
rngState = 20260809
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

kSeries = 4
seriesName$[1] = "Pre-training"
seriesName$[2] = "Mid-training"
seriesName$[3] = "Post-training"
seriesName$[4] = "Follow-up"

; ---- data ------------------------------------------------------------------
if gtype = 5 or gtype = 13
    ; long format: time/condition x group, several ids per cell
    Create Table with column names: "d", 0, "t val grp id"
    row = 0
    for g from 1 to kSeries
        for tt from 1 to 6
            for k from 1 to 8
                row = row + 1
                Append row
                Set numeric value: row, "t", tt
                @rnd
                Set numeric value: row, "val",
                ... 200 + g * 9 + tt * 3 + rnd.g * 7
                Set string value: row, "grp", seriesName$[g]
                Set numeric value: row, "id", (g - 1) * 8 + k
            endfor
        endfor
    endfor
elsif gtype = 8
    Create Table with column names: "d", 0, "x y grp"
    row = 0
    for g from 1 to kSeries
        for k from 1 to 60
            row = row + 1
            Append row
            @rnd
            .xv = (rngState / 2147483648) * 10
            Set numeric value: row, "x", .xv
            @rnd
            Set numeric value: row, "y",
            ... 200 + g * 10 + .xv * 2.5 + rnd.g * 8
            Set string value: row, "grp", seriesName$[g]
        endfor
    endfor
else
    Create Table with column names: "d", 0, "val grp"
    row = 0
    for g from 1 to kSeries
        for k from 1 to 90
            row = row + 1
            Append row
            @rnd
            Set numeric value: row, "val", 200 + g * 11 + rnd.g * 10
            Set string value: row, "grp", seriesName$[g]
        endfor
    endfor
endif
objectId = selected ("Table")

@emlClearAnnotations
@emlSetAdaptiveTheme: vpW, vpH
@emlSetColorPalette: mode$
@emlInitAlphaSprites
emlLegendPlacement = placement

; ---- draw ------------------------------------------------------------------
; BOTH SPELLINGS ARE READ. axis* is the contract; the legacy names are read
; beside it so section 11 can assert where they agree and where they must not.
selectObject: objectId
if gtype = 5
    @emlDrawTimeSeriesCI: objectId, "f0 over training", "Session", "f0 (Hz)",
    ... vpW, vpH, mode$, 1, "t", "val", "grp", 0, 0, 0, 0
    axXMin = emlDrawTimeSeriesCI.axisXMin
    axXMax = emlDrawTimeSeriesCI.axisXMax
    axYMin = emlDrawTimeSeriesCI.axisYMin
    axYMax = emlDrawTimeSeriesCI.axisYMax
    lgXMin = emlDrawTimeSeriesCI.xMin
    lgXMax = emlDrawTimeSeriesCI.xMax
    lgYMin = emlDrawTimeSeriesCI.yMin
    lgYMax = emlDrawTimeSeriesCI.yMax
    nGroups = emlDrawTimeSeriesCI.nGroups
elsif gtype = 8
    @emlDrawScatterPlot: objectId, "f0 by intensity", "Intensity (dB)",
    ... "f0 (Hz)", vpW, vpH, mode$, 1,
    ... "x", "y", "grp", 0, 0, 0, 0, 0
    axXMin = emlDrawScatterPlot.axisXMin
    axXMax = emlDrawScatterPlot.axisXMax
    axYMin = emlDrawScatterPlot.axisYMin
    axYMax = emlDrawScatterPlot.axisYMax
    lgXMin = emlDrawScatterPlot.xMin
    lgXMax = emlDrawScatterPlot.xMax
    lgYMin = emlDrawScatterPlot.yMin
    lgYMax = emlDrawScatterPlot.yMax
    nGroups = emlDrawScatterPlot.nGroups
elsif gtype = 10
    @emlDrawHistogram: objectId, "f0 distribution", "f0 (Hz)", "Count",
    ... vpW, vpH, mode$, 1, "val", "grp", 0, 1, 0, 0, 0
    axXMin = emlDrawHistogram.axisXMin
    axXMax = emlDrawHistogram.axisXMax
    axYMin = emlDrawHistogram.axisYMin
    axYMax = emlDrawHistogram.axisYMax
    lgXMin = emlDrawHistogram.xMin
    lgXMax = emlDrawHistogram.xMax
    lgYMin = emlDrawHistogram.yMin
    lgYMax = emlDrawHistogram.yMax
    nGroups = emlDrawHistogram.nGroups
else
    @emlDrawSpaghettiPlot: objectId, "Individual trajectories", "Session",
    ... "f0 (Hz)", vpW, vpH, mode$, 1,
    ... "t", "val", "id", "grp", 1, 0, 0
    axXMin = emlDrawSpaghettiPlot.axisXMin
    axXMax = emlDrawSpaghettiPlot.axisXMax
    axYMin = emlDrawSpaghettiPlot.axisYMin
    axYMax = emlDrawSpaghettiPlot.axisYMax
    lgXMin = emlDrawSpaghettiPlot.xMin
    lgXMax = emlDrawSpaghettiPlot.xMax
    lgYMin = emlDrawSpaghettiPlot.yMin
    lgYMax = emlDrawSpaghettiPlot.yMax
    nGroups = emlDrawSpaghettiPlot.nGroups
endif

; ---------------------------------------------------------------------------
; The records. Same shapes case.praat and series_case.praat print, so one
; emitter in run.sh reads all three fixtures.
; ---------------------------------------------------------------------------
appendInfoLine: "SWEEP name=", caseName$, " gtype=", gtype,
... " placement=", placement, " vpW=", fixed$ (vpW, 3),
... " vpH=", fixed$ (vpH, 3), " mode=", mode$

; THE AXIS CONTRACT, BOTH SPELLINGS, ON ONE LINE.
appendInfoLine: "AXCONTRACT axisXMin=", fixed$ (axXMin, 10),
... " axisXMax=", fixed$ (axXMax, 10),
... " axisYMin=", fixed$ (axYMin, 10),
... " axisYMax=", fixed$ (axYMax, 10),
... " paramXMin=", fixed$ (lgXMin, 10),
... " paramXMax=", fixed$ (lgXMax, 10),
... " paramYMin=", fixed$ (lgYMin, 10),
... " paramYMax=", fixed$ (lgYMax, 10)

appendInfoLine: "SRCASE name=", caseName$, " graph=t", gtype,
... " k=", kSeries, " vpW=", fixed$ (vpW, 3), " vpH=", fixed$ (vpH, 3),
... " mode=", mode$, " room=0 pinMin=0.0000000000 pinMax=0.0000000000"

legendShown = 0
legendHidden = 0
legendCols = 0
legendRows = 0
if variableExists ("emlDrawLegend.nCols")
    legendCols = emlDrawLegend.nCols
    legendRows = emlDrawLegend.rowsPerCol
    legendShown = emlDrawLegend.shown
    legendHidden = emlDrawLegend.hidden
endif

; ENTRIES = SERIES, on four graph types that reach the legend by four
; different routes. kSeries is what the table was built with, nGroups is what
; the draw procedure resolved out of it, legendN is what @emlDrawLegend was
; handed. All three printed, so a legend naming a different number of things
; than the figure drew cannot pass by agreeing with itself.
appendInfoLine: "SERIES k=", kSeries, " nGroups=", nGroups,
... " legendN=", legendN, " shown=", legendShown,
... " hidden=", legendHidden

cornerPlaced$ = "-"
if variableExists ("emlPlaceElements.corner1$")
    cornerPlaced$ = emlPlaceElements.corner1$
endif
cornerDrawn$ = "-"
if variableExists ("emlDrawLegend.position$")
    cornerDrawn$ = emlDrawLegend.position$
endif
appendInfoLine: "CORNER corner=", cornerDrawn$, " placed=", cornerPlaced$

appendInfoLine: "AXIS yMin=", fixed$ (axYMin, 10),
... " yMax=", fixed$ (axYMax, 10)

placementUsed = -1
if variableExists ("emlDrawLegend.placement")
    placementUsed = emlDrawLegend.placement
endif
appendInfoLine: "PLACEMENT requested=", placement, " actual=", placementUsed

appendInfoLine: "THEME body=", fixed$ (emlSetAdaptiveTheme.bodySize, 4),
... " annot=", fixed$ (emlSetAdaptiveTheme.annotSize, 4),
... " mL=", fixed$ (emlSetAdaptiveTheme.marginLeft, 4),
... " mR=", fixed$ (emlSetAdaptiveTheme.marginRight, 4),
... " mT=", fixed$ (emlSetAdaptiveTheme.marginTop, 4),
... " mB=", fixed$ (emlSetAdaptiveTheme.marginBottom, 4),
... " innerL=", fixed$ (emlSetAdaptiveTheme.innerLeft, 4),
... " innerR=", fixed$ (emlSetAdaptiveTheme.innerRight, 4),
... " innerT=", fixed$ (emlSetAdaptiveTheme.innerTop, 4),
... " innerB=", fixed$ (emlSetAdaptiveTheme.innerBottom, 4)

; @emlMeasureGraphLayout is the form's PRE-dispatch estimate and it reads
; legendN, which on this path is not populated until the draw has run. Same
; reasoning as series_case.praat: not called, field is -1.
appendInfoLine: "LAYOUT legendW=", -1, " legendH=", -1

appendInfoLine: "EXTENT minX=", fixed$ (emlDrawnMinX, 4),
... " maxX=", fixed$ (emlDrawnMaxX, 4),
... " minY=", fixed$ (emlDrawnMinY, 4),
... " maxY=", fixed$ (emlDrawnMaxY, 4)

; World -> inches -> pixels, the conversion the other two fixtures use. The
; PNG covers the drawn extent at 300 dpi, so its origin is
; emlDrawnMinX/emlDrawnMinY.
innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop

procedure toPxX: .world
    .inch = emlSetAdaptiveTheme.innerLeft
    ... + (.world - axXMin) / (axXMax - axXMin) * innerW
    .px = round ((.inch - emlDrawnMinX) * 300)
endproc
procedure toPxY: .world
    .inch = emlSetAdaptiveTheme.innerTop
    ... + (axYMax - .world) / (axYMax - axYMin) * innerH
    .px = round ((.inch - emlDrawnMinY) * 300)
endproc

boxL = -1
boxR = -1
boxT = -1
boxB = -1
if legendShown > 0
    @toPxX: emlDrawLegend.boxLeft
    boxL = toPxX.px
    @toPxX: emlDrawLegend.boxRight
    boxR = toPxX.px
    @toPxY: emlDrawLegend.boxTop
    boxT = toPxY.px
    @toPxY: emlDrawLegend.boxBottom
    boxB = toPxY.px
endif
appendInfoLine: "LEGENDBOX x=", boxL, " y=", boxT, " w=", boxR - boxL,
... " h=", boxB - boxT
appendInfoLine: "LEGENDLAYOUT cols=", legendCols, " rows=", legendRows,
... " shown=", legendShown, " hidden=", legendHidden

; No comparison matrix on any of these four types -- that is what makes them
; the non-categorical half of the sweep. Printed in case.praat's shape anyway,
; so the driver has one field to read rather than two shapes to branch on.
appendInfoLine: "MATRIX k=0 tch=0 suppressed=1 gap=0.0000 panelH=0.0000",
... " total=", fixed$ (vpH, 4), " top=", fixed$ (vpH, 4),
... " bot=", fixed$ (vpH, 4)

bandPanelBot = round ((emlSetAdaptiveTheme.outerBottom - emlDrawnMinY) * 300)
appendInfoLine: "BANDS panelBot=", bandPanelBot, " mxTop=-1 mxBot=-1"

; THE PARKED LEGEND, AND WHY IT IS WRITTEN HERE. Placement 4 leaves the
; legend on the picture some twenty-four inches below the figure and does NOT
; report it to @emlExpandDrawnExtent, so the figure saves at its own extent
; and a SECOND select-and-save writes the key. That handshake --
; emlLegendSepActive plus the four coordinates -- is what the graphs form does
; at its own save site, and no other fixture in this tree exercises it.
;
; ANCHOR, not a line number:
;     grep -n 'emlLegendSepActive = 1' plugin/graphs/eml-graphs-form.praat
sepActive = 0
sepPath$ = ""
if variableExists ("emlLegendSepActive")
    sepActive = emlLegendSepActive
endif

@stressSave: vpW, vpH

if sepActive = 1
    sepPath$ = replace$ (stressOut$, ".png", "_legend.png", 1)
    Select outer viewport: emlLegendSepX0, emlLegendSepX1,
    ... emlLegendSepY0, emlLegendSepY1
    Save as 300-dpi PNG file: sepPath$
    @emlAssertFullViewport
endif
appendInfoLine: "SEPFILE active=", sepActive, " path=", sepPath$

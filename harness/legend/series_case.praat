include _prelude.praat
; The form is included for ONE procedure, @emlLegendHeadroomAfterDraw, and
; for the dispatch preamble this case copies. Including it is safe: its
; file-scope block is assignments only ("These run at include time. They set
; up sentinel variables and preset globals. No procedure calls, no object
; operations."), and nothing in it is reached unless it is called.
;
; IT IS INCLUDED RATHER THAN REIMPLEMENTED ON PURPOSE. The headroom pass is
; the thing under test; a fixture carrying its own copy of the arithmetic
; would go green against a copy and say nothing about the product. This is
; v27's rule — drive the real procedure.
include ../../plugin/graphs/eml-graphs-form.praat
# ---------------------------------------------------------------------------
# THE LEGEND, LOAD-BEARING. A figure whose series can be told apart ONLY by
# the key, drawn through the real graph-level draw procedures.
#
# WHY THIS FILE EXISTS ALONGSIDE case.praat. case.praat is a ruler: it draws
# two violins, asks for a legend of up to twenty-four entries, and forces the
# corner to "top-left". Every rectangle it measures is correct and none of it
# is a demonstration of a legend —
#
#   · TWO SERIES, TWELVE ENTRIES. The key named ten groups that were not in
#     the figure, so "does the legend cover the data it names" could not even
#     be phrased against it, let alone tested.
#   · THE CORNER WAS FORCED. Seven draw procedures in the product set
#     `.legendCorner$ = emlPlaceElements.corner1$` and pass that. A fixture
#     that hardcodes a corner exercises no part of the choosing, so nothing
#     it renders can support a claim about which corner the product picks.
#   · A VIOLIN DOES NOT NEED A LEGEND. On a grouped violin or box the x-axis
#     already carries the category labels; the key is redundant furniture. A
#     legend earns its place on a scatter, a spaghetti plot or a line chart,
#     where series identity has nowhere else to live.
#
# So: HERE the number of legend entries IS the number of series, by
# construction and asserted on both sides; the corner is whatever
# @emlPlaceElements scores; and the figure is one where covering the key over
# the data destroys information a reader cannot get back.
#
# THE TWO GRAPH TYPES, and why each.
#   line     @emlDrawTimeSeries — graph type 5, the LINE CHART. k series over
#            the same time base, one colour and one marker shape each. The
#            reader has no other cue: the lines cross, so position does not
#            identify them, and the x-axis carries time and not identity.
#   scatter  @emlDrawScatterPlot — graph type 8, grouped. Same argument, and
#            a different legend call site: with no annotation block it takes
#            emlPlaceElements.corner1$, with one it takes corner2$. Drawn
#            here with annotate = 0 so the corner is corner1$ and the ONLY
#            difference between a figure and its control is the legend.
#
# THE DATA IS BUILT TO FILL ALL FOUR CORNERS, and that is the point of the
# whole file. @emlPlaceElements takes the emptiest quadrant. On a figure whose
# data reaches every quadrant the emptiest one still has data under it, so
# choosing a corner is not the same as making room — which is the claim
# @emlComputeAnnotationHeadroom's comment makes, and this is the figure it is
# made about. Each series is a sinusoid on its own offset and its own phase,
# so the k lines sweep the full height of the panel across the full width.
#
# ---------------------------------------------------------------------------
# THE MEASUREMENT THIS FIXTURE WAS BUILT FOR: DOES THE KEY SIT ON THE DATA.
#
# It is made on the PIXELS, between two renders, and never from what the
# script believed it drew:
#
#   TREATMENT  the figure with its legend, at the placement asked for.
#   CONTROL    the SAME figure, on the SAME AXIS, with emlLegendPlacement = 5
#              so @emlDrawLegend draws nothing. Placement 5 is a one-line
#              change inside @emlDrawLegend (`.draw = 0`); everything else —
#              the axis, the quadrant scan, .legendCorner$, the disclosure
#              corner that reads it, the drawn extent — is computed
#              identically. So the two files differ in legend ink and in
#              nothing else.
#
# THE SAME AXIS IS NOT AUTOMATIC and it is why EML_YMIN / EML_YMAX exist. If
# the legend is given y-axis room the treatment's axis is not the control's,
# every datum moves, and a pixel comparison between them would measure the
# axis change rather than the overlap. So the driver reads the axis the
# TREATMENT actually drew on out of its own transcript and pins the control
# to it. harness/legend/measure_cover.py then counts the pixels that are
# data-coloured in the control and different in the treatment.
#
# ---------------------------------------------------------------------------
# Env, all optional:
#   EML_OUT        output PNG                          default from _prelude
#   EML_CASE       case name, echoed into the records   default "unnamed"
#   EML_VPW        figure width, inches                 default 6
#   EML_VPH        figure height, inches                default 4
#   EML_K          number of SERIES, and therefore of   default 5
#                  legend entries. >= 2; @emlCountGroups
#                  refuses to group a single level.
#   EML_GRAPH      line | scatter                       default line
#   EML_MODE       color | bw                           default color
#   EML_PLACEMENT  1..5 (5 = the legend-free control)   default 1
#   EML_ROOM       1 run the form's legend-headroom      default 0
#                  pass, 0 draw once
#   EML_YMIN       pin the y-axis (both 0 = auto)       default 0
#   EML_YMAX                                            default 0
#
# Prints (the driver parses these):
#   SRCASE       name and every input echoed back
#   SERIES       k, the group labels' count, legendN, and what the legend
#                showed and hid. legendN = k is the property this whole file
#                exists to make assertable.
#   CORNER       the four quadrant scores the draw procedure computed and the
#                corner @emlPlaceElements returned — the REAL choice, not a
#                fixture's opinion of it
#   ROOM         the headroom pass: whether it applied, the band it asked
#                for, the band it was granted, and the axis before and after
#   AXIS         the y-axis the figure was finally drawn on. The driver feeds
#                this back as EML_YMIN/EML_YMAX for the control.
#   PLACEMENT, THEME, LAYOUT, EXTENT, LEGENDBOX, LEGENDLAYOUT, MATRIX, BANDS
#                the same records case.praat prints, in the same format, so
#                one driver and one RESULTS.tsv layout serve both fixtures.
# ---------------------------------------------------------------------------

caseName$ = environment$ ("EML_CASE")
if caseName$ = ""
    caseName$ = "unnamed"
endif

vpW = number (environment$ ("EML_VPW"))
if vpW = undefined
    vpW = 6
endif
vpH = number (environment$ ("EML_VPH"))
if vpH = undefined
    vpH = 4
endif
kSeries = number (environment$ ("EML_K"))
if kSeries = undefined
    kSeries = 5
endif
if kSeries < 2
    kSeries = 2
endif
graph$ = environment$ ("EML_GRAPH")
if graph$ = ""
    graph$ = "line"
endif
mode$ = environment$ ("EML_MODE")
if mode$ = ""
    mode$ = "color"
endif
placement = number (environment$ ("EML_PLACEMENT"))
if placement = undefined
    placement = 1
endif
useRoom = number (environment$ ("EML_ROOM"))
if useRoom = undefined
    useRoom = 0
endif
pinYMin = number (environment$ ("EML_YMIN"))
if pinYMin = undefined
    pinYMin = 0
endif
pinYMax = number (environment$ ("EML_YMAX"))
if pinYMax = undefined
    pinYMax = 0
endif

; ---------------------------------------------------------------------------
; THE TABLE. Deterministic, no random numbers, so a re-render is byte-
; identical and a moved pixel is a change in the plugin.
;
; k series over 13 time points. Series i is centred on its own offset and
; carries its own phase, so the lines CROSS: no series occupies a band of its
; own, and a reader who loses the key cannot recover which is which from
; position. That is what makes the legend load-bearing rather than decorative.
;
; The amplitude and the offsets are chosen so the envelope of the k series
; spans most of the panel in both directions — every quadrant gets points,
; which is the case in which "choose the emptiest corner" has nothing empty
; to choose.
;
; The scatter uses the same construction sampled at 25 x positions per group
; with a deterministic spread, so the two graph types describe the same
; shape and any difference between them is the renderer's.
; ---------------------------------------------------------------------------
nT = 13
if graph$ = "scatter"
    nT = 25
endif
nRows = kSeries * nT
tbl = Create Table with column names: "srdata", nRows, "xv yv series"
for gi to kSeries
    ; Zero-padded so the alphabetical order @emlCountGroups returns is the
    ; numeric order, at any k.
    lab$ = "Speaker " + string$ (gi)
    if gi < 10
        lab$ = "Speaker 0" + string$ (gi)
    endif
    for ti to nT
        row = (gi - 1) * nT + ti
        xv = ti
        ; The series' own offset, spread symmetrically about the middle.
        off = 9 * (gi - (kSeries + 1) / 2)
        ; Its own phase, one full turn distributed over the k series.
        ph = 2 * pi * (gi - 1) / kSeries
        yv = 60 + off + 11 * sin (2 * pi * (ti - 1) / (nT - 1) + ph)
        if graph$ = "scatter"
            ; A deterministic, series-specific perturbation, so the cloud has
            ; width without a random generator. invGaussQ over a co-prime
            ; stride visits the whole quantile range without repeating.
            xv = ti + 0.35 * invGaussQ (((gi * 7 + ti * 3) mod 25 + 0.5) / 25)
            yv = yv + 2.5 * invGaussQ (((gi * 11 + ti * 5) mod 25 + 0.5) / 25)
        endif
        selectObject: tbl
        Set numeric value: row, "xv", xv
        Set numeric value: row, "yv", yv
        Set string value: row, "series", lab$
    endfor
endfor

; The workflow's own reset, in the workflow's place — before the draw.
; ANCHOR, not a line number:
;     grep -n '@emlClearAnnotations' plugin/graphs/eml-graphs-form.praat
; Without it annotBracketN does not exist, and @emlComputeAnnotationHeadroom
; opens with `if annotBracketN > 0` unguarded. That is not a defect in the
; procedure — every caller in the product has been through the workflow — but
; a fixture that skipped it would be reporting a fixture bug as a plugin one.
@emlClearAnnotations

; ---------------------------------------------------------------------------
; THE DRAW, through the form's own dispatch preamble.
;
; ANCHOR, not a line number:
;     grep -n 'procedure emlGraphsDispatchDraw' plugin/graphs/eml-graphs-form.praat
; The five statements below are that procedure's preamble, in its order and
; for its stated reasons: erase, reset the drawn extent, hand the drawing
; layer the chosen placement, disarm the parked-legend flag, and BLANK
; @emlDrawLegend's .position$ so that "" means "no legend was drawn on THIS
; figure" and a stale corner from a previous pass cannot be mistaken for one.
; The headroom pass reads that variable, so blanking it is not cosmetic.
; ---------------------------------------------------------------------------
procedure srDispatch: .yMin, .yMax
    Erase all
    @emlResetDrawnExtent
    emlLegendPlacement = placement
    emlLegendSepActive = 0
    emlDrawLegend.position$ = ""
    Select outer viewport: 0, vpW, 0, vpH
    if graph$ = "scatter"
        @emlDrawScatterPlot: tbl, "Legend demonstration", "Time (s)",
        ... "F0 (Hz)", vpW, vpH, mode$, 1, "xv", "yv", "series",
        ... 0, 0, .yMin, .yMax, 0
        .axMin = emlDrawScatterPlot.axisYMin
        .axMax = emlDrawScatterPlot.axisYMax
        .nGroups = emlDrawScatterPlot.nGroups
        .qTL = emlDrawScatterPlot.qTL
        .qTR = emlDrawScatterPlot.qTR
        .qBL = emlDrawScatterPlot.qBL
        .qBR = emlDrawScatterPlot.qBR
    else
        @emlDrawTimeSeries: tbl, "Legend demonstration", "Time (s)",
        ... "F0 (Hz)", vpW, vpH, mode$, 1, "xv", "yv", "series",
        ... 0, 0, .yMin, .yMax
        .axMin = emlDrawTimeSeries.yMin
        .axMax = emlDrawTimeSeries.yMax
        .nGroups = emlDrawTimeSeries.nGroups
        .qTL = emlDrawTimeSeries.qTL
        .qTR = emlDrawTimeSeries.qTR
        .qBL = emlDrawTimeSeries.qBL
        .qBR = emlDrawTimeSeries.qBR
    endif
endproc

; ---------------------------------------------------------------------------
; PASS 1, then — if the caller asked for it — the form's headroom pass and a
; second draw on the widened axis.
;
; @emlLegendHeadroomAfterDraw is the PRODUCT's procedure, called with the
; product's arguments: the placement, the corner @emlDrawLegend reported, the
; axis the draw procedure resolved for itself (read back from the procedure's
; own variables, not re-derived), the annotation font size, and axisKind 1 —
; both bounds movable, which is what a line chart and a scatter have.
;
; EML_ROOM = 0 IS ALSO A REAL CALLER, not a strawman. Every companion script
; and every direct caller of the draw procedures reaches @emlDrawLegend
; without ever going through the form, so it gets no headroom pass at all.
; The two arms are rendered side by side and both numbers are recorded.
; ---------------------------------------------------------------------------
roomApplied = 0
roomNeeded = 0
roomGranted = 0
roomOverflow = 0
roomHeightIn = 0
roomBaseMin = 0
roomBaseMax = 0

@srDispatch: pinYMin, pinYMax
axMin = srDispatch.axMin
axMax = srDispatch.axMax

if useRoom = 1
    roomBaseMin = axMin
    roomBaseMax = axMax
    @emlLegendHeadroomAfterDraw: placement, emlDrawLegend.position$,
    ... roomBaseMin, roomBaseMax, emlSetAdaptiveTheme.annotSize, 1
    roomHeightIn = emlLegendHeadroomAfterDraw.heightInches
    if variableExists ("emlComputeAnnotationHeadroom.legendNeeded")
        roomNeeded = emlComputeAnnotationHeadroom.legendNeeded
        roomGranted = emlComputeAnnotationHeadroom.legendGranted
        roomOverflow = emlComputeAnnotationHeadroom.legendOverflow
    endif
    if emlLegendHeadroomAfterDraw.apply = 1
        roomApplied = 1
        @srDispatch: emlLegendHeadroomAfterDraw.yMin,
        ... emlLegendHeadroomAfterDraw.yMax
        axMin = srDispatch.axMin
        axMax = srDispatch.axMax
    endif
endif

nGroups = srDispatch.nGroups

; ---------------------------------------------------------------------------
; The records. Same shapes case.praat prints, so one driver reads both.
; ---------------------------------------------------------------------------
appendInfoLine: "SRCASE name=", caseName$, " graph=", graph$,
... " k=", kSeries, " vpW=", fixed$ (vpW, 3), " vpH=", fixed$ (vpH, 3),
... " mode=", mode$, " room=", useRoom,
... " pinMin=", fixed$ (pinYMin, 10), " pinMax=", fixed$ (pinYMax, 10)

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

; THE PROPERTY THIS FIXTURE EXISTS TO MAKE ASSERTABLE: entries = series.
; legendN is what @emlDrawLegend was handed, nGroups is what the draw
; procedure actually plotted, and kSeries is what the table was built with.
; All three are printed so the validator compares them rather than trusting
; any one of them.
appendInfoLine: "SERIES k=", kSeries, " nGroups=", nGroups,
... " legendN=", legendN, " shown=", legendShown,
... " hidden=", legendHidden

appendInfoLine: "CORNER corner=", emlDrawLegend.position$,
... " qTL=", srDispatch.qTL, " qTR=", srDispatch.qTR,
... " qBL=", srDispatch.qBL, " qBR=", srDispatch.qBR,
... " placed=", emlPlaceElements.corner1$

appendInfoLine: "ROOM used=", useRoom, " applied=", roomApplied,
... " needed=", fixed$ (roomNeeded, 4),
... " granted=", fixed$ (roomGranted, 4),
... " overflow=", roomOverflow,
... " heightIn=", fixed$ (roomHeightIn, 4),
... " baseMin=", fixed$ (roomBaseMin, 4),
... " baseMax=", fixed$ (roomBaseMax, 4)

appendInfoLine: "AXIS yMin=", fixed$ (axMin, 10),
... " yMax=", fixed$ (axMax, 10)

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
; legendN, which on this path is not populated until the draw has run. Calling
; it here would report the estimate for a legend that did not exist when the
; form would have made it, so it is NOT called and the field is -1. The
; estimate is exercised, on the path where it is meaningful, by case.praat.
appendInfoLine: "LAYOUT legendW=", -1, " legendH=", -1

appendInfoLine: "EXTENT minX=", fixed$ (emlDrawnMinX, 4),
... " maxX=", fixed$ (emlDrawnMaxX, 4),
... " minY=", fixed$ (emlDrawnMinY, 4),
... " maxY=", fixed$ (emlDrawnMaxY, 4)

; World -> inches -> pixels, the conversion case.praat uses. The PNG covers
; the drawn extent at 300 dpi, so its origin is emlDrawnMinX/MinY.
innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
xAxMin = 0
xAxMax = 1
if graph$ = "scatter"
    xAxMin = emlDrawScatterPlot.axisXMin
    xAxMax = emlDrawScatterPlot.axisXMax
else
    xAxMin = emlDrawTimeSeries.xMin
    xAxMax = emlDrawTimeSeries.xMax
endif

procedure toPxX: .world
    .inch = emlSetAdaptiveTheme.innerLeft
    ... + (.world - xAxMin) / (xAxMax - xAxMin) * innerW
    .px = round ((.inch - emlDrawnMinX) * 300)
endproc
procedure toPxY: .world
    .inch = emlSetAdaptiveTheme.innerTop
    ... + (axMax - .world) / (axMax - axMin) * innerH
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

; No comparison matrix on this path. Printed anyway, in case.praat's shape, so
; the driver has one field to read rather than two shapes to branch on.
appendInfoLine: "MATRIX k=0 tch=0 suppressed=1 gap=0.0000 panelH=0.0000",
... " total=", fixed$ (vpH, 4), " top=", fixed$ (vpH, 4),
... " bot=", fixed$ (vpH, 4)

bandPanelBot = round ((emlSetAdaptiveTheme.outerBottom - emlDrawnMinY) * 300)
appendInfoLine: "BANDS panelBot=", bandPanelBot, " mxTop=-1 mxBot=-1"

@stressSave: vpW, vpH

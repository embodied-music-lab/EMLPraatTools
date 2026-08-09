include _prelude.praat
# ---------------------------------------------------------------------------
# LEGEND GEOMETRY — the RULER. Not the demonstration.
#
# READ THIS FIRST, BECAUSE THIS FILE USED TO CLAIM MORE THAN IT MEASURES.
# What is below is a GEOMETRY RIG. It draws two violins and asks for a legend
# of 0, 1, 3, 12 or 24 entries, and those two numbers are DELIBERATELY
# unrelated: the entry count is swept as an independent variable so that the
# legend BOX can be measured against everything it can be asked to contain
# while the figure under it is held bit-identical. That is the right design
# for measuring a rectangle and it is the wrong picture of a legend — a
# twelve-entry key over a two-series figure names series that are not there,
# and on a grouped violin the x-axis already carries the category labels, so
# the legend is redundant furniture rather than the only way to read the
# figure. It also hands @emlDrawLegend a HARDCODED "top-left" instead of the
# corner @emlPlaceElements scores, so nothing here exercises corner choice.
#
# The demonstration is harness/legend/series_case.praat: a multi-series line
# chart and a grouped scatter, drawn through the real graph-level draw
# procedures, where the number of legend entries IS the number of series, the
# corner is chosen by @emlPlaceElements exactly as the product chooses it, and
# the legend is the only way to tell one series from another. The assertion
# that legend ink does not land on data ink is made there, on the pixels.
#
# This file keeps every case it had, unchanged to the pixel, because the plot
# rectangle, the matrix-band disjointness and the export-extent relationships
# are measured here and were hard-won. Nothing below is the primary
# demonstration of the legend any more.
#
# THE CONSTRAINT THIS FIXTURE EXISTS TO MEASURE. The dimensions a user types
# into the graphs form describe the PLOT, not the plot plus its furniture. If
# a legend carves space out of the 6 x 4 someone asked for, "make my figure
# square" stops being satisfiable — the plot goes oblong while the file stays
# square. So the plot rectangle has to be IDENTICAL whatever the legend is
# doing, and anything the legend needs beyond it has to come out of the SAVED
# IMAGE growing, not out of the plot shrinking.
#
# There are five placements — 1 Inside plot, 2 Right of plot, 3 Below plot,
# 4 Separate figure, 5 None — and this fixture renders all of them, plus the
# whole legend matrix through the pre-placement calling convention, in which
# no emlLegendPlacement is declared at all. It was written the day before the
# placements landed and rendered the matrix against the tree on both sides of
# that change, which is why validate/v32_legend_geometry.R can state what did
# and did not move rather than only what is true now.
#
# WHAT VARIES, AND WHY EACH ONE IS HERE
#   figure size    a square (5 x 5) and a short-and-wide (10 x 3) beside the
#                  default 6 x 4, because a legend that steals width and a
#                  legend that steals height fail differently, and the square
#                  is the case the author's objection is stated in.
#   entry count    0, 1, 3, 12, 24. One is the single-column geometry D123
#                  promised to leave bit-identical; 24 is the palette's full
#                  style space and the count that used to run off the frame;
#                  0 is the red path.
#   label width    one entry deliberately wider than the whole frame — D135,
#                  which used to overhang to the right and off the canvas,
#                  and is now ellipsized to fit.
#   colour mode    colour and greyscale, because the greyscale swatch is
#                  drawn by a different branch with a different ink rule.
#   legend at all  a no-legend render at every size, which is the control:
#                  the plot rectangle must be the same size WITH a legend as
#                  WITHOUT one. That is the author's constraint reduced to
#                  two figures, and it is the check that goes red if a
#                  placement is implemented by shrinking the panel.
#   placement      all five, at twelve entries, one render each per size. The
#                  plot rectangle must be the same in every one of them; what
#                  is allowed to change is the size of the SAVED FILE.
#
# THE FIGURE UNDER THE LEGEND IS HELD CONSTANT ON PURPOSE. Two violins of the
# same deterministic sample in every case, so that any difference in the
# measured frame is attributable to the legend and to nothing else. The
# legend is set up and called exactly as @emlDrawGroupedViolin sets it up and
# calls it — patterned swatches at emlSetAdaptiveTheme.annotSize.
#
# AND IT IS TWO VIOLINS UNDER A LEGEND OF UP TO TWENTY-FOUR ENTRIES, which is
# not a figure anybody would publish. Say it plainly: the entry count is an
# INPUT TO THE BOX, not a description of the data, and this file measures the
# box. Nothing here should be read as a statement about whether a legend
# covers the series it names — see the head of this file, and
# harness/legend/series_case.praat, where entry count and series count are
# the same number by construction.
#
# Env, all optional; the defaults are the plugin's default figure with the
# 24-entry legend that motivated D123.
#   EML_OUT      output PNG                        default from _prelude
#   EML_CASE     case name, echoed into the records default "unnamed"
#   EML_VPW      figure width, inches              default 6
#   EML_VPH      figure height, inches             default 4
#   EML_N        legend entries                    default 24
#   EML_MODE     color | bw                        default color
#   EML_LABELS   normal | wide                     default normal
#   EML_LEGEND   1 draw a legend, 0 draw none      default 1
#   EML_PLACEMENT 1..5, or empty to declare none    default none declared
#   EML_MATRIX   0 none; k >= 2 = a REAL k-group   default 0
#                post-hoc comparison matrix below
#                the plot, laid out the way the
#                graphs form lays one out
#   EML_TCH      1 declare totalCanvasHeight as    default 1
#                the form does, 0 leave it unset
#
# THE MATRIX VARIANT, and what it is for. A figure can already put a second
# panel below the plot — the pairwise comparison matrix @emlDrawMatrixPanel
# renders — and placement 3 puts the LEGEND below the plot as well. Nothing
# in the tree rendered the two together, so whether they collide was an
# argument from reading @emlDrawLegend's placement-3 branch and not a
# measurement. This is the measurement.
#
# THE MATRIX IS REAL, NOT SYNTHESISED. @emlBridgeGroupComparison is called on
# a deterministic k-group table, so annotMatrixN, annotMatrixLabel$[], the
# cell strings, the significance flags and the Cohen's d values are the ones
# a one-way ANOVA with Tukey HSD actually produces. A hand-filled matrix
# would exercise the renderer while missing anything the bridge does to the
# globals the renderer reads — the label sanitisation, the omnibus line, the
# effect-size column that decides the panel's height.
#
# EML_TCH IS THE RED PATH, AND IT IS ONE VARIABLE. The form computes
# figure_height + matrixGap + matrixPanelHeight and leaves it in
# totalCanvasHeight before it selects the outer viewport, so inside the form
# that global is always there. It is a FORM LOCAL: @emlInitDrawingDefaults —
# the documented entry point for "standalone scripts or PraatGen companion
# files" — sets emlLegendPlacement and does NOT set it. EML_TCH=0 is that
# caller. Everything else about the page is identical between the two,
# including the outer viewport, which is selected from a LOCAL copy of the
# same number; the only difference is whether the global exists.
#
# Prints (the driver parses these; the validator reads the driver's TSV):
#   LGCASE      name, and every input echoed back
#   THEME       body/annot font size, the four margins, the inner rectangle
#   PLACEMENT   what was asked for (-1 = nothing declared) and what
#               @emlDrawLegend reports it used, after its clamp
#   LAYOUT      emlLayout_legendWidthInches / HeightInches — @emlMeasureGraph-
#               Layout's estimate of the legend's size, computed before draw
#               dispatch. Nothing in the plugin consumes it; the validator
#               checks it against the box that was actually drawn.
#   EXTENT      emlDrawnMinX/MaxX/MinY/MaxY — the box @emlAssertFullViewport
#               will select, i.e. exactly what the PNG will cover.
#   LEGENDBOX   the box @emlDrawLegend says it drew, in pixels
#   LEGENDLAYOUT cols, rows per column, shown, hidden
#   MATRIX      the comparison matrix, if one was asked for: group count,
#               whether totalCanvasHeight was declared, the gap and panel
#               height the form's arithmetic produced, and the panel's
#               viewport top and its bottom AFTER @emlDrawMatrixPanel's own
#               top-down sizing adjusted it. Absent when EML_MATRIX is 0.
#   BANDS       the same three horizontal boundaries in PIXELS of the saved
#               PNG — the plot panel's bottom, the matrix band's top and its
#               bottom — which is what harness/legend/measure_bands.py is
#               handed. Printed for every case, matrix or not, so the driver
#               has one field to read rather than two shapes.
#
# THIS CASE NEVER EXITS ON AN OVERHANG. legend_cap.praat does, because
# containment is its subject and a figure that fails it is a broken figure.
# Here the overhang is one of the MEASUREMENTS — the whole point is to record
# how far outside the frame the ink went, and a case that aborted would
# record nothing. The judgement is the validator's.
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
nEntries = number (environment$ ("EML_N"))
if nEntries = undefined
    nEntries = 24
endif
mode$ = environment$ ("EML_MODE")
if mode$ = ""
    mode$ = "color"
endif
labels$ = environment$ ("EML_LABELS")
if labels$ = ""
    labels$ = "normal"
endif
drawLegend = number (environment$ ("EML_LEGEND"))
if drawLegend = undefined
    drawLegend = 1
endif

# EML_PLACEMENT -- the legend placement, 1..5. Set as the global
# emlLegendPlacement, which is where @emlDrawLegend reads it from and where
# the graphs form writes it from config_legendPlacement.
#
# UNSET IS NOT THE SAME AS 1 AND BOTH ARE DRIVEN. A script that predates the
# placements -- every stress case in this repo, every PraatGen companion file,
# every caller in eml-draw-procedures.praat -- sets NOTHING, and must get the
# corner box it has always had. So the default here is to declare no global at
# all, and placement 1 is requested explicitly only by the cases that name it.
# The two must render identically; the validator asserts that they do.
placement = number (environment$ ("EML_PLACEMENT"))
if placement <> undefined
    emlLegendPlacement = placement
endif

matrixK = number (environment$ ("EML_MATRIX"))
if matrixK = undefined
    matrixK = 0
endif
declareTotal = number (environment$ ("EML_TCH"))
if declareTotal = undefined
    declareTotal = 1
endif

xMin = 0
xMax = 2
yMin = 0
yMax = 10

Erase all
@emlSetAdaptiveTheme: vpW, vpH
@emlSetColorPalette: mode$

# The legend entries, exactly as @emlDrawGroupedViolin populates them.
#
# THE WIDE LABEL. 480 characters at the annotation font is wider than the
# frame of every figure size in this matrix — 8.3 inches of plot on the
# widest of them. It is ONE entry and not all of them, because D135 is about
# a SINGLE label being unwrappable, and because a legend where every label is
# over-wide could be explained away as abuse rather than as a case a user
# reaches.
#
# Rendered on 8 Aug 2026 at 17:10, before the placement work landed, this
# case produced an 8208-pixel legend box on an 1800-pixel canvas: `.colsMax`
# floored at 1, the box was drawn whole, and the save cut it off mid-label.
# It is now ellipsized to fit, with a NOTE naming the panel width and the
# font size. Both sets of numbers are asserted in
# validate/v32_legend_geometry.R — the new ones as the behaviour, the old
# ones as the guard.
wideLabel$ = ""
for i to 30
    wideLabel$ = wideLabel$ + "Sustained vowel "
endfor

legendN = nEntries
legendPatterned = 1
for i to nEntries
    legendColor$[i] = emlSetColorPalette.line$[i]
    legendFill$[i] = emlSetColorPalette.fill$[i]
    legendPattern[i] = emlSetColorPalette.pattern[i]
    legendLabel$[i] = "Group " + string$ (i)
endfor
if labels$ = "wide" and nEntries >= 1
    legendLabel$[1] = wideLabel$
endif

# ---------------------------------------------------------------------------
# THE COMPARISON MATRIX, and the form's PRE-DISPATCH sizing path.
#
# Nothing below runs unless EML_MATRIX asks for one, so every case in blocks
# 1 and 2 renders exactly the pixels it rendered before this section existed.
#
# THE ORDER IS THE FORM'S ORDER, and the order is the whole point. The graphs
# form measures the matrix, computes matrixGap and matrixPanelHeight, sets
# totalCanvasHeight, selects the outer viewport, dispatches the draw — which
# is where @emlDrawLegend is reached, BEFORE any matrix ink exists — and only
# then, post-dispatch, renders @emlDrawMatrixPanel. A fixture that drew the
# panel first would be measuring a figure the plugin never produces, and the
# legend would have a drawn extent to consult that in the plugin it does not.
#
#     grep -n 'totalCanvasHeight =' plugin/graphs/eml-graphs-form.praat
#     grep -n '@emlDrawMatrixPanel' plugin/graphs/eml-graphs-form.praat
#
# THE SAMPLE. k groups of twelve, each group the inverse normal CDF at twelve
# evenly spaced probabilities shifted by a per-group mean, so the ANOVA is
# significant, every Tukey pair is significant, and the Cohen's d column is
# populated — which is what makes the panel take its TALL shape, with the
# effect-size legend row under the grid. A matrix of non-significant cells
# would be a shorter panel and a weaker test of the band below it.
matrixSuppressed = 1
matrixGap = 0
matrixPanelHeight = 0
matrixTotal = vpH
matrixTop = vpH
matrixBottom = vpH
if matrixK >= 2
    annotAlpha = 0.05
    @emlClearAnnotations
    mxPerGroup = 12
    mxTable = Create Table with column names: "legendmx",
    ... matrixK * mxPerGroup, "grp val"
    for gi to matrixK
        for ki to mxPerGroup
            mxRow = (gi - 1) * mxPerGroup + ki
            Set string value: mxRow, "grp", "Cond " + string$ (gi)
            Set numeric value: mxRow, "val", 10 + 1.5 * gi
            ... + 0.9 * invGaussQ ((ki - 0.5) / mxPerGroup)
        endfor
    endfor
    @emlBridgeGroupComparison: mxTable, "val", "grp", 0.05, "p-value",
    ... 1, 1, "parametric", 3
    removeObject: mxTable
    appendInfoLine: "BRIDGE error=[", emlBridgeGroupComparison.error$,
    ... "] n=", annotMatrixN

    # The form's pre-dispatch block, term for term. See the PRE-DISPATCH
    # matrix panel measurement section of eml-graphs-form.praat.
    if annotMatrixN > 0
        mxFontInch = emlSetAdaptiveTheme.matrixSize / 72
        mxEstHeight = mxFontInch * (6 + annotMatrixN * 2.5)
        if mxEstHeight < 1.0
            mxEstHeight = 1.0
        endif
        @emlMeasureMatrixLayout: 0, vpW, vpH, vpH + mxEstHeight,
        ... emlSetAdaptiveTheme.matrixSize
        matrixSuppressed = emlMatrixLayout_suppressed
        if matrixSuppressed = 0
            matrixPanelHeight = emlMatrixLayout_yMax
            if matrixPanelHeight < 1.0
                matrixPanelHeight = 1.0
            endif
        endif
    endif
    if matrixPanelHeight > 0
        # graphOverhangInches is 0 here: this fixture draws violins on a
        # numeric axis, so no categorical labels are measured and no rotated
        # label overhangs below the frame.
        matrixGap = emlSetAdaptiveTheme.bodyInch * 1.0
    endif
    matrixTotal = vpH + matrixGap + matrixPanelHeight

    # THE ONE VARIABLE. The outer viewport is selected from matrixTotal, a
    # LOCAL, in both arms — so the page is the same page — and the GLOBAL the
    # drawing layer reads is written only when EML_TCH says the form wrote it.
    if declareTotal = 1
        totalCanvasHeight = matrixTotal
    endif
    Select outer viewport: 0, vpW, 0, matrixTotal
endif

# The form calls @emlMeasureGraphLayout once before draw dispatch, so the
# fixture calls it in the same place — its legend estimate is computed from
# legendN and legendLabel$[] and is recorded below.
#
# IT LEAVES THE VIEWPORT AND THE AXES ON ITS OWN MEASUREMENT COORDINATES
# (@emlSetPanelViewport, then `Axes: 0, innerW, 0, innerH`, so that a world
# unit is an inch), and it does not put them back. In the plugin the draw
# orchestrator that runs next sets both for itself, so nothing shows; a
# fixture that draws directly has to do the same. Written the wrong way round
# first, and the figure died on `"Position" must be between 0 and 4.125` —
# @emlDrawAxes drawing 0..10 into a world that was 0..3.11.
@emlMeasureGraphLayout: vpW, vpH, "Legend geometry", "Category", "Value"

@emlSetPanelViewport
Axes: xMin, xMax, yMin, yMax
@emlSetPatternScale: xMin, xMax, yMin, yMax

# Two marks, so the frame is not a blank page and the ink measurements have
# something to read. Deterministic sample: the inverse normal CDF at 120
# evenly spaced probabilities, the same construction legend_cap.praat uses.
nObs = 120
d# = zero# (nObs)
for i to nObs
    d#[i] = 5 + 1.3 * invGaussQ ((i - 0.5) / nObs)
endfor
@emlDrawViolin: 0.6, d#, emlSetColorPalette.fill$[1],
... emlSetColorPalette.line$[1], yMin, yMax, 0.35,
... emlSetColorPalette.pattern[1]
@emlDrawViolin: 1.4, d#, emlSetColorPalette.fill$[2],
... emlSetColorPalette.line$[2], yMin, yMax, 0.35,
... emlSetColorPalette.pattern[2]

boxL = -1
boxR = -1
boxT = -1
boxB = -1
cols = 0
rows = 0
shown = 0
hidden = 0

if drawLegend = 1
    # THE CORNER IS FORCED HERE, AND THAT IS A LIMITATION OF THIS FILE.
    # Every real caller sets `.legendCorner$ = emlPlaceElements.corner1$` and
    # passes that — grep -n 'legendCorner\$ = emlPlaceElements' in
    # plugin/graphs/eml-draw-procedures.praat for the seven of them. A fixed
    # corner is what makes the plot rectangle comparable across 103 renders
    # here, and it is exactly why no claim about WHICH corner the product
    # picks can be supported by this file. Corner selection is driven, on the
    # real path, in harness/legend/series_case.praat.
    @emlDrawLegend: xMin, xMax, yMin, yMax, "top-left",
    ... emlSetAdaptiveTheme.annotSize
endif

@emlDrawAxes: xMin, xMax, yMin, yMax, "Category", "Value",
... "Legend geometry", vpW, vpH

# POST-DISPATCH, where the form draws it: after the figure, after the legend.
# The panel does its own top-down sizing on the viewport it is handed, so the
# bottom it actually drew to is @emlDrawMatrixPanel's own .vpBottom and NOT
# the one passed in — the two differ whenever the measured content is shorter
# than the 1.0 inch floor the form applies to matrixPanelHeight.
if matrixK >= 2 and matrixPanelHeight > 0
    matrixTop = vpH + matrixGap
    @emlDrawMatrixPanel: 0, vpW, matrixTop, matrixTotal,
    ... emlSetAdaptiveTheme.matrixSize, mode$
    matrixBottom = emlDrawMatrixPanel.vpBottom
endif

# World -> inches -> pixels, the conversion legend_cap.praat and
# harness/patterns/style_case.praat both use. The PNG covers the drawn extent
# (@emlAssertFullViewport) at 300 dpi, so its origin is emlDrawnMinX/MinY.
innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop

procedure toPxX: .world
    .inch = emlSetAdaptiveTheme.innerLeft + (.world - xMin) / (xMax - xMin) * innerW
    .px = round ((.inch - emlDrawnMinX) * 300)
endproc
procedure toPxY: .world
    .inch = emlSetAdaptiveTheme.innerTop + (yMax - .world) / (yMax - yMin) * innerH
    .px = round ((.inch - emlDrawnMinY) * 300)
endproc

if drawLegend = 1
    @toPxX: emlDrawLegend.boxLeft
    boxL = toPxX.px
    @toPxX: emlDrawLegend.boxRight
    boxR = toPxX.px
    @toPxY: emlDrawLegend.boxTop
    boxT = toPxY.px
    @toPxY: emlDrawLegend.boxBottom
    boxB = toPxY.px
    # Read through variableExists so this case still runs against a build
    # that predates the D123 layout reports.
    if variableExists ("emlDrawLegend.nCols")
        cols = emlDrawLegend.nCols
        rows = emlDrawLegend.rowsPerCol
        shown = emlDrawLegend.shown
        hidden = emlDrawLegend.hidden
    endif
endif

appendInfoLine: "LGCASE name=", caseName$, " n=", nEntries,
... " vpW=", fixed$ (vpW, 3), " vpH=", fixed$ (vpH, 3),
... " mode=", mode$, " labels=", labels$, " legend=", drawLegend

# What was asked for and what was used. -1 means the case declared no
# emlLegendPlacement at all, which is the pre-placement world; `actual` is
# @emlDrawLegend's own report after its clamp, so a value that was corrected
# on the way in is visible rather than inferred.
placementAsked = -1
if placement <> undefined
    placementAsked = placement
endif
placementUsed = -1
if drawLegend = 1
    if variableExists ("emlDrawLegend.placement")
        placementUsed = emlDrawLegend.placement
    endif
endif
appendInfoLine: "PLACEMENT requested=", placementAsked, " actual=", placementUsed

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

appendInfoLine: "LAYOUT legendW=", fixed$ (emlLayout_legendWidthInches, 4),
... " legendH=", fixed$ (emlLayout_legendHeightInches, 4)

appendInfoLine: "EXTENT minX=", fixed$ (emlDrawnMinX, 4),
... " maxX=", fixed$ (emlDrawnMaxX, 4),
... " minY=", fixed$ (emlDrawnMinY, 4),
... " maxY=", fixed$ (emlDrawnMaxY, 4)

appendInfoLine: "LEGENDBOX x=", boxL, " y=", boxT, " w=", boxR - boxL,
... " h=", boxB - boxT
appendInfoLine: "LEGENDLAYOUT cols=", cols, " rows=", rows,
... " shown=", shown, " hidden=", hidden

# The matrix, in inches, and the same boundaries in pixels of the PNG that is
# about to be written. Both are printed for EVERY case: a case with no matrix
# reports k=0 and a matrix band of -1..-1, which is what
# harness/legend/measure_bands.py reads as "this band does not exist", so the
# driver has one field to pull rather than two shapes to branch on.
#
# BANDS panelBot is the plot panel's own bottom edge, which is where
# measure.py's frame search stops and where measure_bands.py starts counting.
# It is emlSetAdaptiveTheme.outerBottom and not vpH, so a panel origin other
# than zero would carry through.
appendInfoLine: "MATRIX k=", matrixK, " tch=", declareTotal,
... " suppressed=", matrixSuppressed,
... " gap=", fixed$ (matrixGap, 4),
... " panelH=", fixed$ (matrixPanelHeight, 4),
... " total=", fixed$ (matrixTotal, 4),
... " top=", fixed$ (matrixTop, 4),
... " bot=", fixed$ (matrixBottom, 4)

bandPanelBot = round ((emlSetAdaptiveTheme.outerBottom - emlDrawnMinY) * 300)
bandMxTop = -1
bandMxBot = -1
if matrixK >= 2 and matrixPanelHeight > 0
    bandMxTop = round ((matrixTop - emlDrawnMinY) * 300)
    bandMxBot = round ((matrixBottom - emlDrawnMinY) * 300)
endif
appendInfoLine: "BANDS panelBot=", bandPanelBot,
... " mxTop=", bandMxTop, " mxBot=", bandMxBot

@stressSave: vpW, vpH

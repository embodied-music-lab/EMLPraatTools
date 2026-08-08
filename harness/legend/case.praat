include ../stress_cases/_prelude.praat
# ---------------------------------------------------------------------------
# LEGEND GEOMETRY — one figure, one legend, the plot rectangle pinned.
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
    @emlDrawLegend: xMin, xMax, yMin, yMax, "top-left",
    ... emlSetAdaptiveTheme.annotSize
endif

@emlDrawAxes: xMin, xMax, yMin, yMax, "Category", "Value",
... "Legend geometry", vpW, vpH

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

@stressSave: vpW, vpH

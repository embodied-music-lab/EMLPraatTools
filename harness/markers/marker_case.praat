# ---------------------------------------------------------------------------
# ONE MARKER, ONE FIGURE. The fixture behind validate/v29_figure_disclosure.R's
# "the 24 point-marker styles are distinguishable" section.
#
# Same argument as harness/patterns/style_case.praat, moved to the other half
# of the palette. @emlSetColorPalette declared ten fill/line pairs for years
# while slots 9 and 10 were byte-for-byte copies of 1 and 2, and every check
# that read the palette TABLE agreed there were ten (D127). The four chart
# types that draw dots and lines -- scatter, line chart, spaghetti, time
# series -- had the same hole for longer and worse: they have no area to fill,
# so the fill PATTERN that fixed the violins and boxes did nothing for them,
# and they went on cycling eight hues in silence above eight groups. The fix
# is marker SHAPE, and the claim "a reader can tell series 9 from series 1" is
# a claim about the picture, so it is measured on the picture.
#
# Driven by harness/markers/run.sh, which sets:
#   EML_MODE    color | bw          the palette branch
#   EML_STYLE   1..24               the palette slot
#   EML_SHAPE   point | key | keyline | floor
#                 point    the mark itself, at @emlDrawScatterPlot's own
#                          medium dot size
#                 key      the legend swatch a SCATTER draws (marker alone)
#                 keyline  the legend swatch a LINE CHART, TIME SERIES or
#                          SPAGHETTI draws (marker on a line segment)
#                 floor    the mark at an EXPLICIT size, for the ladder that
#                          finds where the three shapes stop being separable
#   EML_HALFIN  marker radius in inches; read only when EML_SHAPE = floor
#   EML_OUT     PNG path
#
# Every render is IDENTICAL except for the style index, so any pixel
# difference between two of them is the style and nothing else.
#
# Prints, for the driver to crop and measure:
#   STYLE   mode / index / declared hue / declared marker
#   CROP    x y w h in pixels of a square region centred on the marker and
#           large enough to contain ALL THREE shapes, computed here from
#           world coordinates -- the shell does not guess where the mark is,
#           and the crop is deliberately shape-INDEPENDENT so that the
#           measurement cannot be told the answer by the crop.
# ---------------------------------------------------------------------------
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder, which is two levels below the repository root, the same
; depth as harness/stress_cases/. So the prelude's own "../../plugin/..."
; lines resolve correctly too. Absolute paths here meant a copy of the repo
; silently tested the ORIGINAL tree. See harness/_env.sh.
include ../stress_cases/_prelude.praat

mode$ = environment$ ("EML_MODE")
if mode$ = ""
    mode$ = "color"
endif
style = number (environment$ ("EML_STYLE"))
if style = undefined
    style = 1
endif
shape$ = environment$ ("EML_SHAPE")
if shape$ = ""
    shape$ = "point"
endif

vpW = 6
vpH = 4
xMin = 0
xMax = 2
yMin = 0
yMax = 10
xC = 1
yC = 5

Erase all
@emlSetAdaptiveTheme: vpW, vpH
@emlSetColorPalette: mode$
# NOT optimised, for the same reason harness/patterns/style_case.praat is not:
# @emlOptimizePaletteContrast permutes hues for a given group count, and this
# fixture is asking what the palette's slot N actually draws.
mk = emlSetColorPalette.marker[style]
hue = emlSetColorPalette.hue[style]
# The colour a scatter would use for this slot: the stroke hue in colour mode,
# the light ink in B/W. Read from the palette, not restated here.
if mode$ = "bw"
    col$ = emlSetColorPalette.lightLine$[style]
else
    col$ = emlSetColorPalette.line$[style]
endif

@emlSetPanelViewport
Axes: xMin, xMax, yMin, yMax
@emlSetPatternScale: xMin, xMax, yMin, yMax

# @emlDrawScatterPlot's MEDIUM dot size, restated as the same arithmetic:
# sizeScale 0.015 x markerSize x the x-range, converted to inches. On this
# 6 x 4 panel that is 0.065 inches, i.e. a 39-pixel circle at 300 dpi.
sizeScale = 0.015
radiusWorld = emlSetAdaptiveTheme.markerSize * sizeScale * (xMax - xMin)
halfIn = radiusWorld / emlPatWorldPerInchX

cx = xC
cy = yC
cropHalfIn = 0

if shape$ = "floor"
    # An explicit radius, so the ladder can walk the marker down until the
    # shapes stop being recoverable and the floor can be REPORTED rather than
    # asserted from the geometry. Everything else about the render is
    # unchanged, including the 3 x radius crop.
    halfIn = number (environment$ ("EML_HALFIN"))
    if halfIn = undefined
        halfIn = 0.02
    endif
    @emlDrawMarker: xC, yC, halfIn, mk, col$
    cropHalfIn = halfIn * 1.5
elsif shape$ = "point"
    @emlDrawMarker: xC, yC, halfIn, mk, col$
    # A square crop wide enough for the largest of the three shapes: the
    # triangle reaches 1.2557 x halfIn sideways and 1.45 x halfIn upward.
    cropHalfIn = halfIn * 1.5
else
    legendN = 1
    legendMarkered = 1
    legendMarkerLine = 0
    if shape$ = "keyline"
        legendMarkerLine = 1
    endif
    legendColor$[1] = col$
    legendMarker[1] = mk
    legendLabel$[1] = "S" + string$ (style)
    # The PRODUCTION legend font size -- the same value every grouped draw
    # procedure passes -- so what is measured is the key a real figure draws.
    @emlDrawLegend: xMin, xMax, yMin, yMax, "top-left",
    ... emlSetAdaptiveTheme.annotSize
    cx = (emlDrawLegend.swatchLeft + emlDrawLegend.swatchRight) / 2
    cy = emlDrawLegend.entryY
    cropHalfIn = emlDrawLegend.swatchSide * 0.42 * 1.5
endif

# World -> inches -> pixels. The PNG covers the drawn extent
# (@emlAssertFullViewport), at 300 dpi, so its origin is emlDrawnMinX/Y.
innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
cInX = emlSetAdaptiveTheme.innerLeft + (cx - xMin) / (xMax - xMin) * innerW
cInY = emlSetAdaptiveTheme.innerTop + (yMax - cy) / (yMax - yMin) * innerH
pxX = round ((cInX - cropHalfIn - emlDrawnMinX) * 300)
pxY = round ((cInY - cropHalfIn - emlDrawnMinY) * 300)
pxS = round (2 * cropHalfIn * 300)

appendInfoLine: "STYLE mode=", mode$, " index=", style, " hue=", hue,
... " marker=", mk, " shape=", shape$
appendInfoLine: "PALETTE colour=", col$, " halfInches=", fixed$ (halfIn, 4)
appendInfoLine: "CROP ", pxX, " ", pxY, " ", pxS, " ", pxS

@stressSave: vpW, vpH

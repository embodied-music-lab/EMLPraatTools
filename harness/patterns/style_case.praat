# ---------------------------------------------------------------------------
# ONE STYLE, ONE FIGURE. The fixture behind validate/v29_figure_disclosure.R's
# "the 24 sub-group styles are distinguishable" section.
#
# The claim under test is a claim about the PICTURE -- "a reader can tell
# sub-group 9 from sub-group 1" -- so it is measured on the picture. A palette
# table cannot answer it: the palette table said there were ten distinct
# fill/line pairs for years while slots 9 and 10 were literal duplicates of
# 1 and 2 (D127), and every static check agreed with it.
#
# Driven by harness/patterns/run.sh, which sets:
#   EML_MODE    color | bw          the palette branch
#   EML_STYLE   1..24               the palette slot
#   EML_SHAPE   violin | box | swatch
#   EML_OUT     PNG path
#
# Every render is IDENTICAL except for the style index, so any pixel
# difference between two of them is the style and nothing else. The layout is
# fixed and deterministic (no random data) for the same reason.
#
# Prints, for the driver to crop and measure:
#   STYLE   mode / index / declared hue / declared pattern
#   CROP    x y w h, in pixels, of a region GUARANTEED to be inside the
#           drawn mark and clear of its outline, its quartile box and its
#           median line -- computed here from world coordinates rather than
#           guessed by the shell, because only this script knows the axes.
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
    shape$ = "violin"
endif

vpW = 6
vpH = 4
xMin = 0
xMax = 2
yMin = 0
yMax = 10
xC = 1

Erase all
@emlSetAdaptiveTheme: vpW, vpH
@emlSetColorPalette: mode$
# NOT optimised. @emlOptimizePaletteContrast permutes hues for a given group
# count; this fixture is asking what the palette's slot N actually draws, so
# it must read the palette as declared.
fill$ = emlSetColorPalette.fill$[style]
line$ = emlSetColorPalette.line$[style]
pat = emlSetColorPalette.pattern[style]
hue = emlSetColorPalette.hue[style]

@emlSetPanelViewport
Axes: xMin, xMax, yMin, yMax
@emlSetPatternScale: xMin, xMax, yMin, yMax

# Deterministic pseudo-normal sample: the inverse normal CDF at 240 evenly
# spaced probabilities. Same numbers in every render, in every mode.
nObs = 240
d# = zero# (nObs)
for i to nObs
    d#[i] = 5 + 1.3 * invGaussQ ((i - 0.5) / nObs)
endfor

# Crop corners in WORLD coordinates, filled in per shape below.
cropX1 = 0
cropX2 = 0
cropY1 = 0
cropY2 = 0

if shape$ = "violin"
    @emlDrawViolin: xC, d#, fill$, line$, yMin, yMax, 0.45, pat
    # Inside the body, outside the quartile box. The body half-width at
    # y = 5 +/- 0.7 is at least 0.86 of its maximum 0.45, i.e. >= 0.38; the
    # quartile box half-width is 0.45 * 0.143 = 0.064.
    cropX1 = xC + 0.12
    cropX2 = xC + 0.34
    cropY1 = 4.3
    cropY2 = 5.7
elsif shape$ = "box"
    @emlDrawBox: xC, d#, fill$, line$, yMin, yMax, 0.45, pat
    # Between the median line and the top edge, inset off both.
    cropX1 = xC - 0.30
    cropX2 = xC + 0.30
    cropY1 = emlDrawBox.medianOut + 0.12
    cropY2 = emlDrawBox.q3Out - 0.10
else
    # The legend swatch for the same style. This is the OTHER half of the
    # claim: a solid swatch beside a hatched violin is the same defect as two
    # identical colours, moved into the key.
    legendN = 1
    legendPatterned = 1
    legendColor$[1] = line$
    legendFill$[1] = fill$
    legendPattern[1] = pat
    legendLabel$[1] = "S" + string$ (style)
    # The PRODUCTION font size — the same value @emlDrawGroupedViolin passes
    # — so what is measured is the swatch a real figure draws, not a blown-up
    # stand-in.
    @emlDrawLegend: xMin, xMax, yMin, yMax, "top-left",
    ... emlSetAdaptiveTheme.annotSize
    # @emlDrawLegend leaves its per-entry geometry in its own locals; with
    # legendN = 1 those are entry 1's.
    cropX1 = emlDrawLegend.swatchLeft
    cropX2 = emlDrawLegend.swatchRight
    cropY1 = emlDrawLegend.swatchBottom
    cropY2 = emlDrawLegend.swatchTop
    # Inset off the swatch outline by 4% of its side.
    insetX = (cropX2 - cropX1) * 0.10
    insetY = (cropY2 - cropY1) * 0.10
    cropX1 = cropX1 + insetX
    cropX2 = cropX2 - insetX
    cropY1 = cropY1 + insetY
    cropY2 = cropY2 - insetY
endif

# World -> inches -> pixels. The PNG covers the drawn extent
# (@emlAssertFullViewport), at 300 dpi, so its origin is emlDrawnMinX/Y.
innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
inX1 = emlSetAdaptiveTheme.innerLeft + (cropX1 - xMin) / (xMax - xMin) * innerW
inX2 = emlSetAdaptiveTheme.innerLeft + (cropX2 - xMin) / (xMax - xMin) * innerW
inY1 = emlSetAdaptiveTheme.innerTop + (yMax - cropY2) / (yMax - yMin) * innerH
inY2 = emlSetAdaptiveTheme.innerTop + (yMax - cropY1) / (yMax - yMin) * innerH
pxX = round ((inX1 - emlDrawnMinX) * 300)
pxY = round ((inY1 - emlDrawnMinY) * 300)
pxW = round ((inX2 - inX1) * 300)
pxH = round ((inY2 - inY1) * 300)

appendInfoLine: "STYLE mode=", mode$, " index=", style, " hue=", hue,
... " pattern=", pat, " shape=", shape$
appendInfoLine: "PALETTE fill=", fill$, " line=", line$
appendInfoLine: "CROP ", pxX, " ", pxY, " ", pxW, " ", pxH

@stressSave: vpW, vpH

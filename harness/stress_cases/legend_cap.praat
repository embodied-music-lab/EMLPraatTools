include _prelude.praat
# ---------------------------------------------------------------------------
# D123 — THE LEGEND HAS TO STAY INSIDE THE FRAME.
#
# The palette holds 24 sub-group styles (8 hues x 3 fill patterns), so a
# 24-entry legend is a case the plugin is expected to draw, not an abuse of
# it. @emlDrawLegend used to stack one row per entry with no ceiling: at 24
# entries the box was taller than the panel and ran off the top of the frame,
# taking its swatches and its labels with it.
#
# This case renders the legend through the SAME call the grouped types make —
# @emlDrawLegend with patterned swatches at emlSetAdaptiveTheme.annotSize —
# and prints, in PIXELS of the saved PNG, the frame rectangle and the legend
# box rectangle. Containment is then arithmetic on those four numbers rather
# than an opinion about the picture.
#
# Env, all optional. The driver sets none, so the DEFAULT is the case:
# 24 entries on the plugin's default 6 x 4 figure, which is the combination
# that overflowed.
#   EML_LEGEND_N   entries              default 24
#   EML_VPW        viewport width, in   default 6
#   EML_VPH        viewport height, in  default 4
#
# Prints:
#   LEGENDCASE  n / vpW / vpH / cols / rows / shown / hidden
#   FRAMEPX     x y w h   the inner (axis) rectangle
#   BOXPX       x y w h   the legend box
#   LEGENDFIT   ok=1 with the four per-edge slacks in pixels, ok=0 with the
#               edge that crossed. A crossing also exits with an Error line
#               so harness/stress_graphs.sh records DREW_THEN_FAILED rather
#               than a green row beside a broken picture.
# ---------------------------------------------------------------------------

nEntries = number (environment$ ("EML_LEGEND_N"))
if nEntries = undefined
    nEntries = 24
endif
vpW = number (environment$ ("EML_VPW"))
if vpW = undefined
    vpW = 6
endif
vpH = number (environment$ ("EML_VPH"))
if vpH = undefined
    vpH = 4
endif

xMin = 0
xMax = 2
yMin = 0
yMax = 10

Erase all
@emlSetAdaptiveTheme: vpW, vpH
@emlSetColorPalette: "color"
@emlSetPanelViewport
Axes: xMin, xMax, yMin, yMax
@emlSetPatternScale: xMin, xMax, yMin, yMax

# Two marks, so the frame is not a blank page and the harness's ink rule has
# something to read. Deterministic sample: the inverse normal CDF at 120
# evenly spaced probabilities.
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

# The legend, exactly as @emlDrawGroupedViolin sets it up.
legendN = nEntries
legendPatterned = 1
for i to nEntries
    legendColor$[i] = emlSetColorPalette.line$[i]
    legendFill$[i] = emlSetColorPalette.fill$[i]
    legendPattern[i] = emlSetColorPalette.pattern[i]
    legendLabel$[i] = "P" + string$ (i)
endfor
@emlDrawLegend: xMin, xMax, yMin, yMax, "top-left",
... emlSetAdaptiveTheme.annotSize

@emlDrawAxes: xMin, xMax, yMin, yMax, "Category", "Value",
... "Legend cap", vpW, vpH

# World -> inches -> pixels, the same conversion harness/patterns/style_case
# uses. The PNG covers the drawn extent (@emlAssertFullViewport) at 300 dpi,
# so its origin is emlDrawnMinX/emlDrawnMinY.
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

@toPxX: xMin
frameL = toPxX.px
@toPxX: xMax
frameR = toPxX.px
@toPxY: yMax
frameT = toPxY.px
@toPxY: yMin
frameB = toPxY.px

@toPxX: emlDrawLegend.boxLeft
boxL = toPxX.px
@toPxX: emlDrawLegend.boxRight
boxR = toPxX.px
@toPxY: emlDrawLegend.boxTop
boxT = toPxY.px
@toPxY: emlDrawLegend.boxBottom
boxB = toPxY.px

# .nCols / .rowsPerCol / .shown / .hidden are @emlDrawLegend's own report of
# the layout it chose. Read through variableExists so this case still runs
# against a build that predates them.
cols = 0
rows = 0
shown = legendN
hidden = 0
if variableExists ("emlDrawLegend.nCols")
    cols = emlDrawLegend.nCols
    rows = emlDrawLegend.rowsPerCol
    shown = emlDrawLegend.shown
    hidden = emlDrawLegend.hidden
endif

appendInfoLine: "LEGENDCASE n=", nEntries, " vpW=", fixed$ (vpW, 2),
... " vpH=", fixed$ (vpH, 2), " cols=", cols, " rows=", rows,
... " shown=", shown, " hidden=", hidden
appendInfoLine: "FRAMEPX x=", frameL, " y=", frameT, " w=", frameR - frameL,
... " h=", frameB - frameT
appendInfoLine: "BOXPX x=", boxL, " y=", boxT, " w=", boxR - boxL,
... " h=", boxB - boxT

slackL = boxL - frameL
slackR = frameR - boxR
slackT = boxT - frameT
slackB = frameB - boxB
fit = 1
if slackL < 0 or slackR < 0
    fit = 0
endif
if slackT < 0 or slackB < 0
    fit = 0
endif
appendInfoLine: "LEGENDFIT ok=", fit, " left=", slackL, " right=", slackR,
... " top=", slackT, " bottom=", slackB

@stressSave: vpW, vpH

if fit = 0
    exitScript: "Error: LEGEND OVERFLOW — the legend box crosses the frame ",
    ... "(left=", slackL, " right=", slackR, " top=", slackT,
    ... " bottom=", slackB, " px of slack; negative is outside)."
endif

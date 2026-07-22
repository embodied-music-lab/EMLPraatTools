# ============================================================================
# EML Stats Demo — Inferential Statistics Showcase
# ============================================================================
# Purpose: Demonstrates three core inferential statistics workflows
#          using the EML Stats library with EML Graphs publication-quality
#          drawing procedures. Generates synthetic voice-science data,
#          runs the statistical tests, produces a three-panel figure,
#          and reports all results to the Info window.
#
#          Panel 1: Independent groups — Welch t-test + Cohen's d
#                   (violin plots comparing two speaker populations)
#          Panel 2: Correlation — Pearson r
#                   (scatter plot of speaking F0 vs. singing F0)
#          Panel 3: Paired pre/post — Wilcoxon signed-rank
#                   (connected dot plot of jitter before/after therapy)
#
# Date: 3 March 2026
# Version: 1.3
#
# ATTRIBUTION
# Framework: EML Praat Assistant by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Acoustic analysis scripts were developed using the EML Praat
#    Assistant (Howell, Embodied Music Lab) with code generation
#    by Claude 4.6 Extended Thinking (Anthropic). All scripts were
#    reviewed, tested, and validated by [your name]."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

# === INCLUDE CHAIN ===
include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat
include ../graphs/eml-graph-procedures.praat

# ============================================================================
# SECTION 1: GENERATE SYNTHETIC DATA
# ============================================================================

# --- Panel 1: Two speaker groups, mean F0 ---
nGroupA = 20
nGroupB = 18
groupA# = randomGauss# (nGroupA, 195, 18)
groupB# = randomGauss# (nGroupB, 165, 24)

# --- Panel 2: Speaking F0 vs. Singing F0 (correlated) ---
nCorr = 30
speakingF0# = randomGauss# (nCorr, 180, 30)
singingF0# = zero# (nCorr)
for i from 1 to nCorr
    singingF0#[i] = speakingF0#[i] * 1.6 + randomGauss (40, 20)
endfor

# --- Panel 3: Paired pre/post jitter (12 subjects) ---
nPaired = 12
preJitter# = zero# (nPaired)
postJitter# = zero# (nPaired)
for i from 1 to nPaired
    preJitter#[i] = randomGauss (2.8, 0.9)
    if preJitter#[i] < 0.3
        preJitter#[i] = randomUniform (0.3, 1.0)
    endif
    postJitter#[i] = preJitter#[i] * 0.6 + randomGauss (0, 0.3)
    if postJitter#[i] < 0.1
        postJitter#[i] = randomUniform (0.1, 0.5)
    endif
endfor


# ============================================================================
# SECTION 2: RUN STATISTICAL TESTS
# ============================================================================

# --- Panel 1: Welch t-test + Cohen's d ---
@emlTTest: groupA#, groupB#, 2, 0
tValue = emlTTest.t
dfValue = emlTTest.df
pValueT = emlTTest.p

@emlCohenD: groupA#, groupB#
dValue = emlCohenD.d
gValue = emlCohenD.g

@emlFormatP: pValueT
pStringT$ = emlFormatP.formatted$

@emlFormatEffectLabel: dValue, "d"
effectLabelD$ = emlFormatEffectLabel.label$

# Descriptive: Median and IQR (matches violin box plot display)
@emlQuartiles: groupA#
medA = emlQuartiles.q2
iqrA = emlQuartiles.q3 - emlQuartiles.q1
@emlQuartiles: groupB#
medB = emlQuartiles.q2
iqrB = emlQuartiles.q3 - emlQuartiles.q1

# --- Panel 2: Pearson correlation (r only, no p) ---
@emlPearsonCorrelation: speakingF0#, singingF0#, 2
rValue = emlPearsonCorrelation.r

# --- Panel 3: Wilcoxon signed-rank ---
@emlWilcoxonSignedRank: preJitter#, postJitter#, 2
tPlus = emlWilcoxonSignedRank.tPlus
tMinus = emlWilcoxonSignedRank.tMinus
pValueW = emlWilcoxonSignedRank.p
wilcoxMethod$ = emlWilcoxonSignedRank.method$
nNonzero = emlWilcoxonSignedRank.nNonzero

@emlFormatP: pValueW
pStringW$ = emlFormatP.formatted$

@emlMedian: preJitter#
medianPre = emlMedian.result
@emlMedian: postJitter#
medianPost = emlMedian.result


# ============================================================================
# SECTION 3: INFO WINDOW REPORT
# ============================================================================

writeInfoLine: "============================================================"
appendInfoLine: "EML STATS DEMO — INFERENTIAL STATISTICS SHOWCASE"
appendInfoLine: "============================================================"
appendInfoLine: ""

# Panel 1 report (Median/IQR to match violin box plot)
appendInfoLine: "PANEL 1: Independent Groups Comparison"
appendInfoLine: "------------------------------------------------------------"
line1a$ = "  Trained (n = "
appendInfoLine: line1a$, nGroupA, "): Mdn = ", fixed$ (medA, 1),
... " Hz, IQR = ", fixed$ (iqrA, 1)
line1b$ = "  Untrained (n = "
appendInfoLine: line1b$, nGroupB, "): Mdn = ", fixed$ (medB, 1),
... " Hz, IQR = ", fixed$ (iqrB, 1)
appendInfoLine: ""
line1c$ = "  Welch t("
appendInfoLine: line1c$, fixed$ (dfValue, 1), ") = ", fixed$ (tValue, 2),
... ", ", pStringT$
line1d$ = "  Cohen's d = "
appendInfoLine: line1d$, fixed$ (dValue, 2), " (", effectLabelD$, ")",
... ", Hedges' g = ", fixed$ (gValue, 2)
appendInfoLine: ""

# Panel 2 report (r only)
appendInfoLine: "PANEL 2: Correlation Analysis"
appendInfoLine: "------------------------------------------------------------"
line2a$ = "  n = "
appendInfoLine: line2a$, nCorr, " speakers"
line2b$ = "  Pearson r = "
appendInfoLine: line2b$, fixed$ (rValue, 3)
appendInfoLine: ""

# Panel 3 report
appendInfoLine: "PANEL 3: Paired Pre/Post Comparison"
appendInfoLine: "------------------------------------------------------------"
line3a$ = "  Pre-therapy:  Mdn = "
appendInfoLine: line3a$, fixed$ (medianPre, 2), "% jitter"
line3b$ = "  Post-therapy: Mdn = "
appendInfoLine: line3b$, fixed$ (medianPost, 2), "% jitter"
appendInfoLine: ""
line3c$ = "  Wilcoxon signed-rank ("
appendInfoLine: line3c$, wilcoxMethod$, ")"
line3d$ = "  T+ = "
appendInfoLine: line3d$, fixed$ (tPlus, 1), ", T- = ", fixed$ (tMinus, 1),
... ", n = ", string$ (nNonzero), ", ", pStringW$
appendInfoLine: ""
appendInfoLine: "============================================================"
appendInfoLine: "All data are synthetic. Statistical tests are real."
appendInfoLine: "============================================================"


# ============================================================================
# SECTION 4: THREE-PANEL FIGURE
# ============================================================================

figWidth = 6
panelHeight = 4
panelGap = 0.5
figHeight = panelHeight * 3 + panelGap * 2

# Circle radius for data points (world coords — tuned per panel)
circleRadius = 0.015

Erase all
@emlResetDrawnExtent
@emlSetColorPalette: "color"


# ============================================================================
# PANEL 1: VIOLIN PLOT — Independent groups t-test
# ============================================================================
# Plugin @emlDrawViolinPlot pattern: manual axes, no @emlDrawAxes

panelTop1 = 0
panelBottom1 = panelHeight

@emlSetAdaptiveTheme: figWidth, panelHeight

Select outer viewport: 0, figWidth, panelTop1, panelBottom1
Select inner viewport: emlSetAdaptiveTheme.innerLeft,
... emlSetAdaptiveTheme.innerRight,
... panelTop1 + emlSetAdaptiveTheme.innerTop,
... panelTop1 + emlSetAdaptiveTheme.innerBottom

# Axis range — extra headroom for KDE tails and annotation text
allGroupData# = zero# (nGroupA + nGroupB)
for i from 1 to nGroupA
    allGroupData#[i] = groupA#[i]
endfor
for i from 1 to nGroupB
    allGroupData#[nGroupA + i] = groupB#[i]
endfor
dataRange = max (allGroupData#) - min (allGroupData#)
yMin1 = min (allGroupData#) - dataRange * 0.15
yMax1 = max (allGroupData#) + dataRange * 0.25
xMin1 = 0.5
xMax1 = 2.5

Axes: xMin1, xMax1, yMin1, yMax1

# Horizontal gridlines only (categorical x)
@emlDrawHorizontalGridlines: xMin1, xMax1, yMin1, yMax1,
... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

# Violins
@emlDrawViolin: 1, groupA#, emlSetColorPalette.fill$[1],
... emlSetColorPalette.line$[1], yMin1, yMax1
@emlDrawViolin: 2, groupB#, emlSetColorPalette.fill$[2],
... emlSetColorPalette.line$[2], yMin1, yMax1

# Jittered points overlaid on violins
jitterData# = groupA#
@emlDrawJitteredPoints: 1, emlSetColorPalette.line$[1],
... emlSetAdaptiveTheme.markerSize, 0.12
jitterData# = groupB#
@emlDrawJitteredPoints: 2, emlSetColorPalette.line$[2],
... emlSetAdaptiveTheme.markerSize, 0.12

# --- Manual axes (plugin @emlDrawViolinPlot pattern) ---
Colour: emlSetAdaptiveTheme.axisColor$
Line width: emlSetAdaptiveTheme.axisLineWidth
Draw inner box
@emlDrawAlignedMarksLeft: yMin1, yMax1,
... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

# Group labels only — no numeric x-axis ticks
Font size: emlSetAdaptiveTheme.bodySize
Colour: emlSetAdaptiveTheme.textColor$
One mark bottom: 1, "no", "yes", "no", "Trained"
One mark bottom: 2, "no", "yes", "no", "Untrained"
Text left: "yes", "F0 (Hz)"

# Annotation — top right, in the headroom space
annotY = yMax1 - (yMax1 - yMin1) * 0.04
annotLine1$ = "%t(" + fixed$ (dfValue, 1) + ") = "
... + fixed$ (tValue, 2) + ", " + pStringT$
annotLine2$ = "%d = " + fixed$ (dValue, 2) + " (" + effectLabelD$ + ")"
Text: xMax1 - 0.05, "right", annotY, "top", annotLine1$
annotY2 = annotY - (yMax1 - yMin1) * 0.06
Text: xMax1 - 0.05, "right", annotY2, "top", annotLine2$

# Title
Font size: emlSetAdaptiveTheme.titleSize
Text top: "yes", "Independent Groups: Welch %t-test"
Colour: "Black"
Line width: 1.0
Font size: emlSetAdaptiveTheme.bodySize


# ============================================================================
# PANEL 2: SCATTER PLOT — Pearson correlation
# ============================================================================
# Continuous axes — @emlDrawAxes. Annotation: r only.
# Regression line constrained to data range.
# Data points: small filled circles via Paint circle:

panelTop2 = panelHeight + panelGap
panelBottom2 = panelTop2 + panelHeight

@emlSetAdaptiveTheme: figWidth, panelHeight

Select outer viewport: 0, figWidth, panelTop2, panelBottom2
Select inner viewport: emlSetAdaptiveTheme.innerLeft,
... emlSetAdaptiveTheme.innerRight,
... panelTop2 + emlSetAdaptiveTheme.innerTop,
... panelTop2 + emlSetAdaptiveTheme.innerBottom

# Axis ranges
@emlComputeAxisRange: min (speakingF0#), max (speakingF0#), 10, 0
xMin2 = emlComputeAxisRange.axisMin
xMax2 = emlComputeAxisRange.axisMax
@emlComputeAxisRange: min (singingF0#), max (singingF0#), 20, 0
yMin2 = emlComputeAxisRange.axisMin
yMax2 = emlComputeAxisRange.axisMax

Axes: xMin2, xMax2, yMin2, yMax2

# Gridlines (both axes continuous)
@emlDrawGridlines: xMin2, xMax2, yMin2, yMax2,
... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY,
... emlSetAdaptiveTheme.useMinorTicks

# Regression line: y = slope * x + intercept
meanSpeaking = mean (speakingF0#)
meanSinging = mean (singingF0#)
sumXY = 0
sumX2r = 0
for i from 1 to nCorr
    dx = speakingF0#[i] - meanSpeaking
    dy = singingF0#[i] - meanSinging
    sumXY = sumXY + dx * dy
    sumX2r = sumX2r + dx * dx
endfor
slope = sumXY / sumX2r
intercept = meanSinging - slope * meanSpeaking

# Constrained to DATA range
dataXMin = min (speakingF0#)
dataXMax = max (speakingF0#)
regY1 = slope * dataXMin + intercept
regY2 = slope * dataXMax + intercept

Colour: "{0.6, 0.6, 0.6}"
Line width: emlSetAdaptiveTheme.dataLineWidth
Draw line: dataXMin, regY1, dataXMax, regY2

# Data points — small filled circles
circRad2 = (xMax2 - xMin2) * circleRadius
for i from 1 to nCorr
    px = speakingF0#[i]
    py = singingF0#[i]
    if px >= xMin2 and px <= xMax2 and py >= yMin2 and py <= yMax2
        Paint circle: emlSetColorPalette.line$[1], px, py, circRad2
    endif
endfor

# Annotation — top left corner, r only
Font size: emlSetAdaptiveTheme.bodySize
Colour: emlSetAdaptiveTheme.textColor$
annot2$ = "%r = " + fixed$ (rValue, 3)
Text: xMin2 + (xMax2 - xMin2) * 0.03, "left",
... yMax2 - (yMax2 - yMin2) * 0.06, "top", annot2$

# Axes (continuous both — @emlDrawAxes like plugin Time Series)
@emlDrawAxes: xMin2, xMax2, yMin2, yMax2,
... "Speaking F0 (Hz)", "Singing F0 (Hz)", "Correlation: Pearson %r",
... figWidth, panelHeight


# ============================================================================
# PANEL 3: CONNECTED DOT PLOT — Wilcoxon signed-rank
# ============================================================================
# Categorical x — manual axes (plugin violin/bar pattern).
# Legend in right margin via marginRightWithLegend.
# Data points: small filled circles.
# Annotation: top left (away from data cluster at x=2).

panelTop3 = (panelHeight + panelGap) * 2
panelBottom3 = panelTop3 + panelHeight

@emlSetAdaptiveTheme: figWidth, panelHeight

Select outer viewport: 0, figWidth, panelTop3, panelBottom3

# Reserve right margin for legend
innerRight3 = figWidth - emlSetAdaptiveTheme.marginRightWithLegend
Select inner viewport: emlSetAdaptiveTheme.innerLeft,
... innerRight3,
... panelTop3 + emlSetAdaptiveTheme.innerTop,
... panelTop3 + emlSetAdaptiveTheme.innerBottom

# Axis range
allJitter# = zero# (nPaired * 2)
for i from 1 to nPaired
    allJitter#[i] = preJitter#[i]
    allJitter#[nPaired + i] = postJitter#[i]
endfor
@emlComputeAxisRange: min (allJitter#), max (allJitter#), 0.5, 0
yMin3 = emlComputeAxisRange.axisMin
yMax3 = emlComputeAxisRange.axisMax
xMin3 = 0.4
xMax3 = 2.6

Axes: xMin3, xMax3, yMin3, yMax3

# Horizontal gridlines only
@emlDrawHorizontalGridlines: xMin3, xMax3, yMin3, yMax3,
... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

# Connecting lines (gray, behind dots)
Colour: "{0.78, 0.78, 0.78}"
Line width: 0.7
for i from 1 to nPaired
    Draw line: 1, preJitter#[i], 2, postJitter#[i]
endfor

# Pre-therapy dots — small filled circles
circRad3 = (xMax3 - xMin3) * circleRadius * 1.5
for i from 1 to nPaired
    Paint circle: emlSetColorPalette.line$[1], 1, preJitter#[i], circRad3
endfor

# Post-therapy dots
for i from 1 to nPaired
    Paint circle: emlSetColorPalette.line$[2], 2, postJitter#[i], circRad3
endfor

# --- Manual axes (categorical pattern) ---
Colour: emlSetAdaptiveTheme.axisColor$
Line width: emlSetAdaptiveTheme.axisLineWidth
Draw inner box
@emlDrawAlignedMarksLeft: yMin3, yMax3,
... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

Font size: emlSetAdaptiveTheme.bodySize
Colour: emlSetAdaptiveTheme.textColor$
One mark bottom: 1, "no", "yes", "no", "Pre-therapy"
One mark bottom: 2, "no", "yes", "no", "Post-therapy"
yLabel3$ = "Jitter (\% )"
Text left: "yes", yLabel3$

# Annotation — top left (away from data at x=2)
annot3a$ = "T^^+^ = " + fixed$ (tPlus, 0) + ", " + pStringW$
annot3b$ = "(" + wilcoxMethod$ + ", %n = " + string$ (nNonzero) + ")"
Text: xMin3 + 0.05, "left", yMax3 - (yMax3 - yMin3) * 0.04, "top", annot3a$
Text: xMin3 + 0.05, "left", yMax3 - (yMax3 - yMin3) * 0.10, "top", annot3b$

# Title
Font size: emlSetAdaptiveTheme.titleSize
Text top: "yes", "Paired Comparison: Wilcoxon Signed-Rank"

# --- Legend in right margin ---
# Switch to outer viewport with normalized coordinates
Select outer viewport: 0, figWidth, panelTop3, panelBottom3
Axes: 0, figWidth, panelHeight, 0

legX = innerRight3 + 0.2
legY1 = emlSetAdaptiveTheme.innerTop + 0.3
legY2 = legY1 + 0.35

Font size: emlSetAdaptiveTheme.bodySize - 1

# Pre swatch
Paint circle: emlSetColorPalette.line$[1], legX + 0.08, legY1, 0.06
Colour: emlSetAdaptiveTheme.textColor$
Text: legX + 0.22, "left", legY1, "half", "Pre"

# Post swatch
Paint circle: emlSetColorPalette.line$[2], legX + 0.08, legY2, 0.06
Colour: emlSetAdaptiveTheme.textColor$
Text: legX + 0.22, "left", legY2, "half", "Post"

# Reset
Colour: "Black"
Line width: 1.0
Font size: emlSetAdaptiveTheme.bodySize


# ============================================================================
# FINALIZE
# ============================================================================

@emlAssertFullViewport
Colour: "Black"
Line width: 1.0
Solid line

appendInfoLine: ""
appendInfoLine: "Figure drawn to Picture window."
appendInfoLine: "Use File > Save as 300-dpi PNG file to export."

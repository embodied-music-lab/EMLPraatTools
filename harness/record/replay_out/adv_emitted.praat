#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 14 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table vt -- 40 rows, 2 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    ~/.praat-dir/plugin_EML_StatsGraphs
#   Praat 7.x  Linux    ~/.config/praat/plugin_EML_StatsGraphs
#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EML_StatsGraphs
#   Windows    ~/Praat/plugin_EML_StatsGraphs
#   Not sure?  Run  writeInfoLine: preferencesDirectory$
#
# A version guard cannot help here: `include` is refused inside an
# if-block, so the file cannot choose its own path at run time.
# The barrel eml-lib-stats.praat will NOT work in place of this
# list: its own relative includes resolve against THIS file's
# folder, not its own.
# ------------------------------------------------------------

include ~/repo/plugin/stats/eml-core-utilities.praat
include ~/repo/plugin/stats/eml-core-descriptive.praat
include ~/repo/plugin/stats/eml-extract.praat
include ~/repo/plugin/stats/eml-output.praat
include ~/repo/plugin/stats/eml-inferential.praat
include ~/repo/plugin/stats/eml-psychometrics.praat
include ~/repo/plugin/stats/eml-categorical.praat
include ~/repo/plugin/stats/eml-result-writer.praat
include ~/repo/plugin/stats/eml-record.praat
include ~/repo/plugin/graphs/eml-graph-procedures.praat
include ~/repo/plugin/graphs/eml-annotation-procedures.praat
include ~/repo/plugin/graphs/eml-draw-procedures.praat
include ~/repo/plugin/stats/eml-analysis.praat
include ~/repo/plugin/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table vt -- 40 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Table vt was already open when this recording started.
# Nothing in the session made it, so nothing below can remake it.
#
# YOU MUST SUPPLY THE DATA YOURSELF, open and named as above, before you
# run this file. The steps below select by name: with nothing of that name
# open the script stops at its first step, and with DIFFERENT data of that
# name it runs to the end and answers a different question without saying so.
# ============================================================

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table vt"   ; run 1, steps 1 (analysis), 2 (draw)
valueCol$    = "val"   ; the measured column -- run 1, steps 1 (analysis), 2 (draw)
groupCol$    = "grp"   ; the grouping column -- run 1, steps 1 (analysis), 2 (draw)
axisYMin     = 1.5549643754959108   ; the y-axis range -- as typed in the dialog -- run 1, step 2 (draw)
axisYMax     = 4.416269793367434   ; the figure was drawn on 1.5550 .. 4.4163
eraseFirst   = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 2 (draw)
panelOriginX = 0   ; inches from the left of the page to this panel's corner -- run 1, step 2 (draw)
panelOriginY = 0   ; inches from the top of the page to this panel's corner -- run 1, step 2 (draw)
lineStyle    = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 2 (draw)
secondAxisOn = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 2 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# Group comparison on a figure: val by grp, parametric, 2 groups
# Reached through the figure's annotation rather than the stats menu; the test and the correction are the same.

prev_violinShowJitter = 1
annotate = 1
@emlReportContext: "recorded script (recorded 14 August 2026, originally analysis dialog)", ""
annotCorrectionMethod$ = "holm"
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 1
@emlBridgeGroupComparison: data, valueCol$, groupCol$, 0.05, "p-value", 0, 1, "parametric", 1

# Welch t: t(33.0) = -8.57, p < .001, d = -2.71
#   2 groups, alpha = 0.050
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs..., with statistical annotation switched on.

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of val, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

prev_violinShowJitter = 1
annotate = 1
emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
annotCorrectionMethod$ = "holm"
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 1
@emlDrawViolinPlot: data, "advanced violin", "Cohort", "val", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax
# The figure's statistical annotation. In the GUI the graphs form
# draws this after the figure returns; a recorded script has no
# form, so the step carries its own render.
annotXMin = emlDrawViolinPlot.axisXMin
annotXMax = emlDrawViolinPlot.axisXMax
annotYMin = emlDrawViolinPlot.axisYMin
annotYMax = emlDrawViolinPlot.axisYMax
annotYRange = annotYMax - annotYMin
if annotTextN > 0
    annotBlockN = annotBlockN + 1
    annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
    annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
    annotTextN = 0
endif
if annotBracketN > 0
    @emlDrawAnnotations: annotXMin, annotXMax, 4.009083, annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize, annotYMin, annotYMax
endif
if annotBlockN > 0
    if annotBracketN > 0
        omnibusCorner$ = "bottom-right"
    else
        omnibusCorner$ = "top-right"
    endif
    @emlDrawAnnotationBlock: omnibusCorner$, annotXMin, annotXMax, annotYMin, annotYMax, emlSetAdaptiveTheme.annotSize
endif
@emlClearAnnotations

# Axis resolved to 1.5550 .. 4.4163 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "val".



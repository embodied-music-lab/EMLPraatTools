#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 21 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table rt_input -- 24 rows, 3 columns
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

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table rt_input -- 24 rows, 3 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table rt_input"   ; run 1, steps 1 (analysis), 2 (draw), 3 (save)
valueCol$     = "f0_Hz"   ; the measured column -- run 1, steps 1 (analysis), 2 (draw)
groupCol$     = "cohort"   ; the grouping column -- run 1, steps 1 (analysis), 2 (draw)
axisYMin      = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 2 (draw)
axisYMax      = 0.0   ; on the recorded data it resolved to -2000.0000 .. 6000.0000
figureFormat$ = "PNG"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 1, step 3 (save)
eraseFirst    = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 2 (draw)
panelOriginX  = 0   ; inches from the left of the page to this panel's corner -- run 1, step 2 (draw)
panelOriginY  = 0   ; inches from the top of the page to this panel's corner -- run 1, step 2 (draw)
lineStyle     = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 2 (draw)
secondAxisOn  = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 2 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of f0_Hz by cohort, 3 groups.
# Tukey HSD requested. Alpha 0.05 (default, not specified by the user).
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, valueCol$, groupCol$, 1

# F(2, 21) = 1.0103, p = 0.3811, eta-squared = 0.0878
#   alpha: n = 8, mean = 621.2500
#   bravo: n = 8, mean = 303.5000
#   charlie: n = 8, mean = 903.5000
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "f0_Hz" and Group column "cohort".

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of f0_Hz, grouped by cohort, 3 groups.
# Violin width is a kernel density estimate, not a count.

annotate = 0
emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
@emlDrawViolinPlot: data, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# Axis resolved to -2000.0000 .. 6000.0000 over 3 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "cohort", Value column "f0_Hz".

# --- Step 3 (save) ---
selectObject: data1$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

annotate = 0
outputFolder$ = "/home/claude/repo/harness/roundtrip/out/saved"
@emlRecordReplaySave: 1, "rt_roundtrip", outputFolder$, figureFormat$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.



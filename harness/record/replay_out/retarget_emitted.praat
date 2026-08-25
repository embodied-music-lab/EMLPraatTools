#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 14 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table wt -- 40 rows, 3 columns
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
# Recorded against: Table wt -- 40 rows, 3 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Table wt was already open when this recording started.
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
data1$ = "Table wt"   ; run 1, steps 1 (analysis), 2 (draw)
valueCol$    = "val"   ; the measured column -- run 1, steps 1 (analysis), 2 (draw)
factorACol$  = "grp"   ; the first factor -- run 1, step 1 (analysis)
factorBCol$  = "site"   ; the second factor -- run 1, step 1 (analysis)
groupCol$    = "grp"   ; the grouping column -- run 1, step 2 (draw)
axisYMin     = 2.0769446372985843   ; the y-axis range -- as typed in the dialog -- run 1, step 2 (draw)
axisYMax     = 4.75420343875885   ; the figure was drawn on 2.0769 .. 4.7542
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
# Two-way ANOVA: val by grp and site
# Type of sums of squares and the balance of the design both matter here; see the report.

@emlReportContext: "recorded script (recorded 14 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 1
@emlRunTwoWayAnalysis: data, valueCol$, factorACol$, factorBCol$

# grp: F(1, 36) = 71.0945, p = 0.0000000005
#   site: F(1, 36) = 15.6125, p = 0.0003
#   interaction: F(1, 36) = 0.0001, p = 0.9914
#   n = 40, cells = 4
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare two-way (ANOVA)...

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of val, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 1
@emlDrawViolinPlot: data, "retarget violin", "Cohort", "val", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# Axis resolved to 2.0769 .. 4.7542 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "val".



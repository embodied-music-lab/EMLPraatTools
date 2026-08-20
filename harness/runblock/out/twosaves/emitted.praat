#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 17 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table vt -- 24 rows, 2 columns
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
# Recorded against: Table vt -- 24 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table vt"   ; run 1, steps 1 (draw), 2 (save), 3 (save)
groupCol$       = "grp"   ; the grouping column -- run 1, step 1 (draw)
valueCol$       = "val"   ; the measured column -- run 1, step 1 (draw)
axisYMin        = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax        = 0.0   ; on the recorded data it resolved to 5.5000 .. 9.0000
figureFormat$   = "PNG"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 1, step 2 (save)
figureFormat1b$ = "PNG, PDF"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 1, step 3 (save)
eraseFirst      = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX    = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY    = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
lineStyle       = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn    = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Box plot: Voice
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
@emlDrawBoxPlot: data, "Voice", "Group", "val", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 2 (save) ---
selectObject: data1$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

outputFolder$ = "/home/claude/repo/harness/runblock/out/twosaves/saved1"
@emlRecordReplaySave: 1, "figA_20260817_120000", outputFolder$, figureFormat$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.

# --- Step 3 (save) ---
selectObject: data1$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

outputFolder$ = "/home/claude/repo/harness/runblock/out/twosaves/saved2"
@emlRecordReplaySave: 1, "figB_20260817_120000", outputFolder$, figureFormat1b$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.



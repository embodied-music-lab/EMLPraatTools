#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# Tue Aug 18 20:13:27 2026  --  recorded on Praat 6.6.30
# Input: Table secondaxis -- 24 rows, 5 columns
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

include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table secondaxis -- 24 rows, 5 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table secondaxis"   ; run 1, step 1 (draw)
timeCol$         = "t"   ; the time column -- run 1, step 1 (draw)
valueCol$        = "f0"   ; the measured column -- run 1, step 1 (draw)
axisYMin         = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax         = 0.0   ; on the recorded data it resolved to 190.0000 .. 260.0000
eraseFirst       = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX     = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY     = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
lineStyle        = 2   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn     = 1   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
secondAxisCol$   = "cq"   ; the column the right-hand series is read from -- run 1, step 1 (draw)
secondAxisMin    = 0   ; the right-hand axis floor; 0 with the ceiling also 0 means auto -- run 1, step 1 (draw)
secondAxisMax    = 0   ; the right-hand axis ceiling; 0 with the floor also 0 means auto -- run 1, step 1 (draw)
secondAxisLabel$ = "Contact quotient"   ; the right-hand axis name; empty falls back to the column name -- run 1, step 1 (draw)
secondAxisStyle  = 3   ; the right-hand series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# [MISSING PHRASE: drawstep.intent]

annotate = 0
emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
emlSecondAxisCol$ = secondAxisCol$
emlSecondAxisMin = secondAxisMin
emlSecondAxisMax = secondAxisMax
emlSecondAxisLabel$ = secondAxisLabel$
emlSecondAxisStyle = secondAxisStyle
@emlDrawTimeSeries: data, "Second axis", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, timeCol$, valueCol$, "", 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...



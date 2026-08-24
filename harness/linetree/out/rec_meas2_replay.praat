#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# Mon Aug 24 13:00:59 2026  --  recorded on Praat 6.6.30
# Input: Table lt_meas2 -- 24 rows, 3 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    /home/claude/repo/plugin_EML_StatsGraphs
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

include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-extract.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-output.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-record.praat
include /home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-analysis.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations
# ---------------------------------------------------------------------------
# harness/linetree/data_meas2.praat
#
# TWO UNLIKE MEASUREMENTS, ONE ROW PER TIME. Fundamental frequency in hertz
# and contact quotient as a fraction: two numeric columns whose ranges differ
# by three orders of magnitude, which is the whole reason the right-hand axis
# exists. Plotted on one scale the quotient is a flat line on the floor.
#
# NO TIME VALUE REPEATS: this leg is the one that reaches the right-hand axis
# page with nothing to average.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_meas2", 0, "time f0 cq"
for i from 1 to 24
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 24
    Set numeric value: r, "f0", 220 + 30 * sin (i / 4)
    Set numeric value: r, "cq", 0.45 + 0.09 * cos (i / 3)
endfor
ltMeas2Id = selected ("Table")

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table lt_meas2 -- 24 rows, 3 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Table lt_meas2 was already open when this recording started.
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
data1$ = "Table lt_meas2"   ; run 1, step 1 (draw)
timeCol$         = "time"   ; the time column -- run 1, step 1 (draw)
valueCol$        = "f0"   ; the measured column -- run 1, step 1 (draw)
axisYMin         = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax         = 0.0   ; on the recorded data this resolved to 180.0000 .. 283.4961; auto adapts to other data
eraseFirst       = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX     = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY     = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
seriesRole$      = "measurements"   ; a page setting -- run 1, step 1 (draw)
lineStyle        = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn     = 1   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
secondAxisCol$   = "cq"   ; the column the right-hand series is read from -- run 1, step 1 (draw)
secondAxisMin    = 0   ; the right-hand axis floor; 0 with the ceiling also 0 means auto -- run 1, step 1 (draw)
secondAxisMax    = 0   ; the right-hand axis ceiling; 0 with the floor also 0 means auto -- run 1, step 1 (draw)
secondAxisLabel$ = ""   ; the right-hand axis name; empty falls back to the column name -- run 1, step 1 (draw)
secondAxisStyle  = 3   ; the right-hand series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Line chart: F0 over time (lt meas2)

prev_violinShowJitter = 0
prev_boxShowJitter = 0
prev_gvShowJitter = 0
prev_gbShowJitter = 0
annotate = 0
emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlSeriesRole$ = seriesRole$
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
emlSecondAxisCol$ = secondAxisCol$
emlSecondAxisMin = secondAxisMin
emlSecondAxisMax = secondAxisMax
emlSecondAxisLabel$ = secondAxisLabel$
emlSecondAxisStyle = secondAxisStyle
@emlDrawTimeSeries: data, "F0 over time (lt meas2)", "Time", "F0", 6, 4, "color", 1, timeCol$, valueCol$, "", 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


Select outer viewport: 0, 6, 0, 4
Save as 300-dpi PNG file: "/home/claude/repo/harness/linetree/out/rec_meas2_replay.png"
